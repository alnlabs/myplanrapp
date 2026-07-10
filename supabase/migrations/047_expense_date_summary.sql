-- Period-based expense/money summaries and list query index

create index if not exists expenses_household_date_idx
  on public.expenses (household_id, expense_date desc);

create or replace function public.household_expense_summary_range(
  p_household_id uuid,
  p_start date,
  p_end date
)
returns table (category_id uuid, category_name text, total_amount numeric) as $$
  select ec.id, ec.name, coalesce(sum(e.amount), 0)
  from public.expense_categories ec
  left join public.expenses e
    on e.category_id = ec.id
    and e.household_id = p_household_id
    and e.entry_type = 'expense'
    and e.expense_date >= p_start
    and e.expense_date <= p_end
  where ec.household_id is null
     or ec.household_id = p_household_id
  group by ec.id, ec.name, ec.sort_order
  having coalesce(sum(e.amount), 0) > 0
  order by ec.sort_order;
$$ language sql security definer stable;

create or replace function public.household_money_summary_range(
  p_household_id uuid,
  p_start date,
  p_end date
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
    and expense_date >= p_start
    and expense_date <= p_end;
$$ language sql security definer stable;

create or replace function public.household_income_by_member_range(
  p_household_id uuid,
  p_start date,
  p_end date
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
    and e.expense_date >= p_start
    and e.expense_date <= p_end
  group by fm.id, fm.display_name
  having coalesce(sum(e.amount), 0) > 0
  order by coalesce(sum(e.amount), 0) desc;
$$ language sql security definer stable;
