-- Income tracking: entry_type on ledger, free-text income_source per entry, per-member attribution

alter table public.expense_categories
  add column if not exists category_kind text not null default 'expense'
    check (category_kind in ('expense', 'income', 'both'));

insert into public.expense_categories (household_id, name, sort_order, category_kind)
select null, v.name, v.sort_order, 'income'
from (values
  ('Salary', 101),
  ('Business', 102),
  ('Freelance', 103),
  ('Rental', 104),
  ('Refund', 105),
  ('Gift', 106),
  ('Investment', 107),
  ('Other income', 108)
) as v(name, sort_order)
where not exists (
  select 1 from public.expense_categories ec
  where ec.household_id is null and ec.name = v.name and ec.category_kind = 'income'
);

alter table public.expenses
  add column if not exists entry_type text not null default 'expense'
    check (entry_type in ('expense', 'income')),
  add column if not exists family_member_id uuid
    references public.household_family_members(id) on delete set null,
  add column if not exists income_source text;

alter table public.expenses
  add constraint expenses_income_member_check check (
    entry_type = 'expense'
    or family_member_id is not null
  );

alter table public.expenses
  add constraint expenses_income_source_check check (
    entry_type = 'expense'
    or (income_source is not null and length(trim(income_source)) > 0)
  );

create index if not exists expenses_entry_type_idx
  on public.expenses (household_id, entry_type, expense_date desc);

create index if not exists expenses_family_member_idx
  on public.expenses (household_id, family_member_id, expense_date desc)
  where entry_type = 'income';

-- Expense-only summary (backward compatible)
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
    and e.entry_type = 'expense'
    and extract(month from e.expense_date) = p_month
    and extract(year from e.expense_date) = p_year
  where ec.household_id is null
     or ec.household_id = p_household_id
  group by ec.id, ec.name, ec.sort_order
  having coalesce(sum(e.amount), 0) > 0
  order by ec.sort_order;
$$ language sql security definer stable;

create or replace function public.household_money_summary(
  p_household_id uuid,
  p_month int,
  p_year int
)
returns table (
  total_spent numeric,
  total_earned numeric,
  net_amount numeric
) as $$
  select
    coalesce(sum(case when entry_type = 'expense' then amount else 0 end), 0),
    coalesce(sum(case when entry_type = 'income' then amount else 0 end), 0),
    coalesce(sum(case when entry_type = 'income' then amount else -amount end), 0)
  from public.expenses
  where household_id = p_household_id
    and extract(month from expense_date) = p_month
    and extract(year from expense_date) = p_year;
$$ language sql security definer stable;

create or replace function public.household_income_by_member(
  p_household_id uuid,
  p_month int,
  p_year int
)
returns table (
  family_member_id uuid,
  member_name text,
  earned_total numeric
) as $$
  select
    fm.id,
    coalesce(nullif(trim(fm.display_name), ''), 'Member'),
    coalesce(sum(e.amount), 0)
  from public.expenses e
  join public.household_family_members fm on fm.id = e.family_member_id
  where e.household_id = p_household_id
    and e.entry_type = 'income'
    and extract(month from e.expense_date) = p_month
    and extract(year from e.expense_date) = p_year
  group by fm.id, fm.display_name
  having coalesce(sum(e.amount), 0) > 0
  order by coalesce(sum(e.amount), 0) desc;
$$ language sql security definer stable;

create or replace function public.household_income_by_member_source(
  p_household_id uuid,
  p_family_member_id uuid,
  p_month int,
  p_year int
)
returns table (
  income_source text,
  earned_total numeric
) as $$
  select
    coalesce(nullif(trim(e.income_source), ''), e.title),
    coalesce(sum(e.amount), 0)
  from public.expenses e
  where e.household_id = p_household_id
    and e.family_member_id = p_family_member_id
    and e.entry_type = 'income'
    and extract(month from e.expense_date) = p_month
    and extract(year from e.expense_date) = p_year
  group by coalesce(nullif(trim(e.income_source), ''), e.title)
  having coalesce(sum(e.amount), 0) > 0
  order by coalesce(sum(e.amount), 0) desc;
$$ language sql security definer stable;
