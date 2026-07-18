-- Fix: column reference "display_name" is ambiguous in expense_group_balances.
-- RETURNS TABLE out-params shadow unqualified column names inside the function body.

create or replace function public.expense_group_balances(p_group_id uuid)
returns table (
  group_member_id uuid,
  display_name text,
  paid_total numeric,
  owed_total numeric,
  settled_in numeric,
  settled_out numeric,
  net_balance numeric
) as $$
begin
  return query
  with members as (
    select egm.id, egm.display_name as member_name
    from public.expense_group_members egm
    where egm.group_id = p_group_id
  ),
  paid as (
    select paid_by_member_id as member_id, coalesce(sum(amount), 0) as total
    from public.expenses
    where group_id = p_group_id
      and entry_type = 'expense'
      and paid_by_member_id is not null
    group by paid_by_member_id
  ),
  owed as (
    select s.group_member_id as member_id, coalesce(sum(s.owed_amount), 0) as total
    from public.expense_splits s
    join public.expenses e on e.id = s.expense_id
    where e.group_id = p_group_id
    group by s.group_member_id
  ),
  settled_in_totals as (
    select to_member_id as member_id, coalesce(sum(amount), 0) as total
    from public.expense_settlements
    where group_id = p_group_id
    group by to_member_id
  ),
  settled_out_totals as (
    select from_member_id as member_id, coalesce(sum(amount), 0) as total
    from public.expense_settlements
    where group_id = p_group_id
    group by from_member_id
  )
  select
    m.id,
    m.member_name,
    coalesce(p.total, 0),
    coalesce(o.total, 0),
    coalesce(si.total, 0),
    coalesce(so.total, 0),
    coalesce(p.total, 0) - coalesce(o.total, 0)
      + coalesce(si.total, 0) - coalesce(so.total, 0)
  from members m
  left join paid p on p.member_id = m.id
  left join owed o on o.member_id = m.id
  left join settled_in_totals si on si.member_id = m.id
  left join settled_out_totals so on so.member_id = m.id
  order by m.member_name;
end;
$$ language plpgsql security definer stable;
