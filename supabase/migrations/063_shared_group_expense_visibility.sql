-- Shared-group expenses should be private to the group's members, not visible
-- to the whole household/family.
--
-- Rules (in addition to the existing scope rules):
--   * An expense attached to a SHARED group is visible only to that group's
--     members (matched by expense_group_members.user_id) or its creator.
--   * Organizational (tracking-only) groups and group-less expenses keep the
--     normal household visibility.
--
-- The SELECT policy enforces this for direct queries; the SECURITY DEFINER
-- summary RPCs (which bypass RLS) apply the same filter so household totals
-- don't leak shared-group amounts to non-members.

-- Helper: is a (possibly group-attached) expense visible to p_viewer w.r.t. the
-- shared-group restriction? SECURITY DEFINER so it can read the group tables
-- without tripping their own RLS.
create or replace function public.expense_group_visible(
  p_group_id uuid,
  p_created_by uuid,
  p_viewer uuid
)
returns boolean as $$
  select
    p_group_id is null
    or p_created_by = p_viewer
    or not exists (
      select 1 from public.expense_groups g
      where g.id = p_group_id and g.group_type = 'shared'
    )
    or exists (
      select 1 from public.expense_group_members egm
      where egm.group_id = p_group_id and egm.user_id = p_viewer
    );
$$ language sql security definer stable;

drop policy if exists "View expenses" on public.expenses;
create policy "View expenses"
  on public.expenses for select
  using (
    public.can_access_module(household_id, 'expenses')
    and (scope = 'household' or created_by = auth.uid())
    and public.expense_group_visible(group_id, created_by, auth.uid())
  );

-- Re-create the scope-aware summary RPCs with the shared-group filter applied.

drop function if exists public.household_money_summary_range(uuid, date, date, text, uuid, uuid);
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
    and public.expense_group_visible(group_id, created_by, p_viewer)
    and (
      (p_scope = 'personal' and scope = 'personal' and created_by = p_viewer)
      or (p_scope = 'household' and scope = 'household')
      or (p_scope is null and (scope = 'household' or created_by = p_viewer))
    );
$$ language sql security definer stable;

drop function if exists public.household_expense_summary_range(uuid, date, date, text, uuid, uuid);
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
    and public.expense_group_visible(e.group_id, e.created_by, p_viewer)
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

drop function if exists public.household_income_by_member_range(uuid, date, date, text, uuid, uuid);
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
    and public.expense_group_visible(e.group_id, e.created_by, p_viewer)
    and (
      (p_scope = 'personal' and e.scope = 'personal' and e.created_by = p_viewer)
      or (p_scope = 'household' and e.scope = 'household')
      or (p_scope is null and (e.scope = 'household' or e.created_by = p_viewer))
    )
  group by fm.id, fm.display_name
  having coalesce(sum(e.amount), 0) > 0
  order by coalesce(sum(e.amount), 0) desc;
$$ language sql security definer stable;
