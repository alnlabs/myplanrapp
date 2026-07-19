-- Personal vs household scope for expenses, income, and recurring money rules.
-- Mirrors the pattern already used by public.plans.scope (010_plans.sql).

alter table public.expenses
  add column if not exists scope text not null default 'household'
    check (scope in ('personal', 'household'));

alter table public.recurring_money_rules
  add column if not exists scope text not null default 'household'
    check (scope in ('personal', 'household'));

create index if not exists expenses_scope_creator_idx
  on public.expenses (household_id, scope, created_by);

-- Personal rows are private to their creator; household rows are shared.
-- The live SELECT policy comes from 015_creator_rls.sql ("View expenses");
-- keep its module gate and add the scope restriction (mirrors plans.scope).
drop policy if exists "View expenses" on public.expenses;
create policy "View expenses"
  on public.expenses for select
  using (
    public.can_access_module(household_id, 'expenses')
    and (scope = 'household' or created_by = auth.uid())
  );

drop policy if exists "Members can view recurring money rules"
  on public.recurring_money_rules;
drop policy if exists "Members can manage recurring money rules"
  on public.recurring_money_rules;

create policy "Members can view recurring money rules"
  on public.recurring_money_rules for select
  using (
    public.is_household_member(household_id)
    and (scope = 'household' or created_by = auth.uid())
  );

create policy "Members can manage recurring money rules"
  on public.recurring_money_rules for all
  using (
    public.is_household_member(household_id)
    and (scope = 'household' or created_by = auth.uid())
  )
  with check (
    public.is_household_member(household_id)
    and (scope = 'household' or created_by = auth.uid())
  );

-- Scope-aware summary RPCs. p_scope: 'personal' | 'household' | null (= all
-- rows visible to p_viewer, i.e. household rows plus the viewer's personal rows).

drop function if exists public.household_money_summary_range(uuid, date, date);
create or replace function public.household_money_summary_range(
  p_household_id uuid,
  p_start date,
  p_end date,
  p_scope text default null,
  p_viewer uuid default null,
  p_group_id uuid default null
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
    and expense_date <= p_end
    and (p_group_id is null or group_id = p_group_id)
    and (
      (p_scope = 'personal' and scope = 'personal' and created_by = p_viewer)
      or (p_scope = 'household' and scope = 'household')
      or (p_scope is null and (scope = 'household' or created_by = p_viewer))
    );
$$ language sql security definer stable;

drop function if exists public.household_expense_summary_range(uuid, date, date);
create or replace function public.household_expense_summary_range(
  p_household_id uuid,
  p_start date,
  p_end date,
  p_scope text default null,
  p_viewer uuid default null,
  p_group_id uuid default null
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
    and (p_group_id is null or e.group_id = p_group_id)
    and (
      (p_scope = 'personal' and e.scope = 'personal' and e.created_by = p_viewer)
      or (p_scope = 'household' and e.scope = 'household')
      or (p_scope is null and (e.scope = 'household' or e.created_by = p_viewer))
    )
  where ec.household_id is null
     or ec.household_id = p_household_id
  group by ec.id, ec.name, ec.sort_order
  having coalesce(sum(e.amount), 0) > 0
  order by ec.sort_order;
$$ language sql security definer stable;

drop function if exists public.household_income_by_member_range(uuid, date, date);
create or replace function public.household_income_by_member_range(
  p_household_id uuid,
  p_start date,
  p_end date,
  p_scope text default null,
  p_viewer uuid default null,
  p_group_id uuid default null
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
    and (p_group_id is null or e.group_id = p_group_id)
    and (
      (p_scope = 'personal' and e.scope = 'personal' and e.created_by = p_viewer)
      or (p_scope = 'household' and e.scope = 'household')
      or (p_scope is null and (e.scope = 'household' or e.created_by = p_viewer))
    )
  group by fm.id, fm.display_name
  having coalesce(sum(e.amount), 0) > 0
  order by coalesce(sum(e.amount), 0) desc;
$$ language sql security definer stable;
