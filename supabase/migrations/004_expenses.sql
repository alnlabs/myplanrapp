-- Expenses

create table public.expense_categories (
  id uuid primary key default gen_random_uuid(),
  household_id uuid references public.households(id) on delete cascade,
  name text not null,
  icon text,
  sort_order int default 0,
  created_at timestamptz default now() not null
);

create table public.expenses (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  category_id uuid not null references public.expense_categories(id) on delete restrict,
  amount numeric not null check (amount > 0),
  currency text not null default 'INR',
  title text not null,
  note text,
  expense_date date not null default current_date,
  paid_by uuid references public.profiles(id) on delete set null,
  pantry_item_id uuid references public.pantry_items(id) on delete set null,
  stock_event_id uuid references public.stock_events(id) on delete set null,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz default now() not null
);

alter table public.expense_categories enable row level security;
alter table public.expenses enable row level security;

insert into public.expense_categories (household_id, name, sort_order) values
  (null, 'Groceries', 1),
  (null, 'Utilities', 2),
  (null, 'Rent', 3),
  (null, 'Transport', 4),
  (null, 'Medical', 5),
  (null, 'Entertainment', 6),
  (null, 'Other', 7);

create policy "Anyone can view default categories"
  on public.expense_categories for select
  using (household_id is null or public.is_household_member(household_id));

create policy "Members can manage household categories"
  on public.expense_categories for all
  using (household_id is not null and public.is_household_member(household_id));

create policy "Members can view expenses"
  on public.expenses for select
  using (public.is_household_member(household_id));

create policy "Members can manage expenses"
  on public.expenses for all
  using (public.is_household_member(household_id));

create or replace function public.household_expense_summary(
  p_household_id uuid,
  p_month int,
  p_year int
)
returns table (category_id uuid, category_name text, total_amount numeric) as $$
  select ec.id, ec.name, coalesce(sum(e.amount), 0)
  from public.expense_categories ec
  left join public.expenses e
    on e.category_id = ec.id
    and e.household_id = p_household_id
    and extract(month from e.expense_date) = p_month
    and extract(year from e.expense_date) = p_year
  where ec.household_id is null
     or ec.household_id = p_household_id
  group by ec.id, ec.name, ec.sort_order
  having coalesce(sum(e.amount), 0) > 0
  order by ec.sort_order;
$$ language sql security definer stable;

create or replace function public.log_grocery_expense(
  p_household_id uuid,
  p_category_id uuid,
  p_amount numeric,
  p_title text,
  p_expense_date date,
  p_note text default null,
  p_pantry_item_id uuid default null,
  p_restock_delta numeric default null,
  p_restock_note text default null
)
returns public.expenses as $$
declare
  v_expense public.expenses;
  v_stock_event_id uuid;
begin
  if p_pantry_item_id is not null and p_restock_delta is not null then
    select id into v_stock_event_id
    from public.apply_stock_event(p_pantry_item_id, p_restock_delta, 'restocked', p_restock_note);
  end if;

  insert into public.expenses (
    household_id, category_id, amount, title, note, expense_date,
    paid_by, pantry_item_id, stock_event_id, created_by
  )
  values (
    p_household_id, p_category_id, p_amount, p_title, p_note, p_expense_date,
    auth.uid(), p_pantry_item_id, v_stock_event_id, auth.uid()
  )
  returning * into v_expense;

  return v_expense;
end;
$$ language plpgsql security definer;
