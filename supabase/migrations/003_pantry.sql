-- Pantry items and stock events

create table public.pantry_items (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  name text not null,
  quantity numeric not null default 0 check (quantity >= 0),
  unit text not null default 'pcs',
  low_stock_threshold numeric,
  category text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

create table public.stock_events (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.pantry_items(id) on delete cascade,
  delta numeric not null,
  reason text not null check (reason in ('used', 'restocked', 'corrected')),
  note text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz default now() not null
);

alter table public.pantry_items enable row level security;
alter table public.stock_events enable row level security;

create policy "Members can view pantry items"
  on public.pantry_items for select
  using (public.is_household_member(household_id));

create policy "Members can manage pantry items"
  on public.pantry_items for all
  using (public.is_household_member(household_id));

create policy "Members can view stock events"
  on public.stock_events for select
  using (
    exists (
      select 1 from public.pantry_items pi
      where pi.id = stock_events.item_id
        and public.is_household_member(pi.household_id)
    )
  );

create policy "Members can insert stock events"
  on public.stock_events for insert
  with check (
    exists (
      select 1 from public.pantry_items pi
      where pi.id = stock_events.item_id
        and public.is_household_member(pi.household_id)
    )
  );

create trigger pantry_items_updated_at
  before update on public.pantry_items
  for each row execute function public.handle_updated_at();

create or replace function public.apply_stock_event(
  p_item_id uuid,
  p_delta numeric,
  p_reason text,
  p_note text default null
)
returns public.stock_events as $$
declare
  v_event public.stock_events;
  v_new_qty numeric;
begin
  select quantity + p_delta into v_new_qty
  from public.pantry_items
  where id = p_item_id
  for update;

  if v_new_qty is null then
    raise exception 'Item not found';
  end if;

  if v_new_qty < 0 then
    raise exception 'Insufficient stock';
  end if;

  update public.pantry_items
  set quantity = v_new_qty, updated_at = now()
  where id = p_item_id;

  insert into public.stock_events (item_id, delta, reason, note, created_by)
  values (p_item_id, p_delta, p_reason, p_note, auth.uid())
  returning * into v_event;

  return v_event;
end;
$$ language plpgsql security definer;

create or replace function public.check_low_stock(p_household_id uuid)
returns setof public.pantry_items as $$
  select *
  from public.pantry_items
  where household_id = p_household_id
    and low_stock_threshold is not null
    and quantity <= low_stock_threshold
  order by name;
$$ language sql security definer stable;
