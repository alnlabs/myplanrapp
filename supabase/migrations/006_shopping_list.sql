-- Shopping list

create table public.shopping_list_items (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  name text not null,
  quantity numeric,
  unit text,
  source text not null default 'manual' check (source in ('manual', 'low_stock', 'recipe')),
  recipe_id uuid references public.recipes(id) on delete set null,
  pantry_item_id uuid references public.pantry_items(id) on delete set null,
  is_checked boolean not null default false,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz default now() not null
);

alter table public.shopping_list_items enable row level security;

create policy "Members can view shopping list"
  on public.shopping_list_items for select
  using (public.is_household_member(household_id));

create policy "Members can manage shopping list"
  on public.shopping_list_items for all
  using (public.is_household_member(household_id));

create or replace function public.generate_shopping_list_from_low_stock(p_household_id uuid)
returns int as $$
declare
  v_count int := 0;
  r record;
begin
  for r in
    select * from public.check_low_stock(p_household_id)
  loop
    insert into public.shopping_list_items (
      household_id, name, quantity, unit, source, pantry_item_id, created_by
    )
    select
      p_household_id,
      r.name,
      greatest(r.low_stock_threshold - r.quantity, 0),
      r.unit,
      'low_stock',
      r.id,
      auth.uid()
    where not exists (
      select 1 from public.shopping_list_items s
      where s.household_id = p_household_id
        and s.is_checked = false
        and lower(s.name) = lower(r.name)
    );
    if found then v_count := v_count + 1; end if;
  end loop;
  return v_count;
end;
$$ language plpgsql security definer;

create or replace function public.generate_shopping_list_from_recipe(p_recipe_id uuid)
returns int as $$
declare
  v_household_id uuid;
  v_count int := 0;
  r record;
begin
  select household_id into v_household_id
  from public.recipes where id = p_recipe_id;

  for r in
    select * from public.check_recipe_availability(p_recipe_id, v_household_id)
    where status in ('missing', 'insufficient')
  loop
    insert into public.shopping_list_items (
      household_id, name, quantity, unit, source, recipe_id, pantry_item_id, created_by
    )
    select
      v_household_id,
      r.ingredient_name,
      r.gap,
      r.unit,
      'recipe',
      p_recipe_id,
      r.pantry_item_id,
      auth.uid()
    where not exists (
      select 1 from public.shopping_list_items s
      where s.household_id = v_household_id
        and s.is_checked = false
        and lower(s.name) = lower(r.ingredient_name)
    );
    if found then v_count := v_count + 1; end if;
  end loop;
  return v_count;
end;
$$ language plpgsql security definer;
