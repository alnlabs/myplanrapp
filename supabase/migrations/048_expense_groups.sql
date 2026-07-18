-- Expense groups, splits, and settlements

create table public.expense_groups (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  name text not null,
  group_type text not null default 'organizational'
    check (group_type in ('organizational', 'shared')),
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

create index expense_groups_household_idx on public.expense_groups (household_id);

create trigger expense_groups_updated_at
  before update on public.expense_groups
  for each row execute function public.handle_updated_at();

create table public.expense_group_members (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.expense_groups(id) on delete cascade,
  display_name text not null,
  user_id uuid references public.profiles(id) on delete set null,
  family_member_id uuid references public.household_family_members(id) on delete set null,
  guest_email text,
  invite_status text not null default 'active'
    check (invite_status in ('active', 'pending')),
  created_at timestamptz default now() not null,
  constraint expense_group_members_user_unique unique (group_id, user_id),
  constraint expense_group_members_email_unique unique (group_id, guest_email)
);

create index expense_group_members_group_idx on public.expense_group_members (group_id);

alter table public.expenses
  add column if not exists group_id uuid references public.expense_groups(id) on delete set null,
  add column if not exists paid_by_member_id uuid
    references public.expense_group_members(id) on delete set null;

create table public.expense_splits (
  id uuid primary key default gen_random_uuid(),
  expense_id uuid not null references public.expenses(id) on delete cascade,
  group_member_id uuid not null references public.expense_group_members(id) on delete cascade,
  share_type text not null check (share_type in ('equal', 'exact', 'percent')),
  share_value numeric,
  owed_amount numeric not null check (owed_amount >= 0),
  unique (expense_id, group_member_id)
);

create index expense_splits_expense_idx on public.expense_splits (expense_id);

create table public.expense_settlements (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.expense_groups(id) on delete cascade,
  from_member_id uuid not null references public.expense_group_members(id) on delete restrict,
  to_member_id uuid not null references public.expense_group_members(id) on delete restrict,
  amount numeric not null check (amount > 0),
  note text,
  settled_at timestamptz default now() not null,
  created_by uuid references public.profiles(id) on delete set null,
  check (from_member_id <> to_member_id)
);

create index expense_settlements_group_idx on public.expense_settlements (group_id);

alter table public.expense_groups enable row level security;
alter table public.expense_group_members enable row level security;
alter table public.expense_splits enable row level security;
alter table public.expense_settlements enable row level security;

create policy "View expense groups"
  on public.expense_groups for select
  using (public.can_access_module(household_id, 'expenses'));

create policy "Manage expense groups"
  on public.expense_groups for all
  using (public.can_access_module(household_id, 'expenses'));

create policy "View expense group members"
  on public.expense_group_members for select
  using (
    exists (
      select 1 from public.expense_groups g
      where g.id = group_id
        and public.can_access_module(g.household_id, 'expenses')
    )
  );

create policy "Manage expense group members"
  on public.expense_group_members for all
  using (
    exists (
      select 1 from public.expense_groups g
      where g.id = group_id
        and public.can_access_module(g.household_id, 'expenses')
    )
  );

create policy "View expense splits"
  on public.expense_splits for select
  using (
    exists (
      select 1 from public.expenses e
      where e.id = expense_id
        and public.can_access_module(e.household_id, 'expenses')
    )
  );

create policy "Manage expense splits"
  on public.expense_splits for all
  using (
    exists (
      select 1 from public.expenses e
      where e.id = expense_id
        and (e.created_by = auth.uid() or public.is_household_owner(e.household_id))
    )
  );

create policy "View expense settlements"
  on public.expense_settlements for select
  using (
    exists (
      select 1 from public.expense_groups g
      where g.id = group_id
        and public.can_access_module(g.household_id, 'expenses')
    )
  );

create policy "Insert expense settlements"
  on public.expense_settlements for insert
  with check (
    exists (
      select 1 from public.expense_groups g
      where g.id = group_id
        and public.can_access_module(g.household_id, 'expenses')
    )
    and created_by = auth.uid()
  );

create or replace function public._validate_expense_splits(
  p_group_id uuid,
  p_amount numeric,
  p_paid_by_member_id uuid,
  p_splits jsonb
)
returns void as $$
declare
  v_group public.expense_groups;
  v_split jsonb;
  v_total_owed numeric := 0;
  v_count int;
begin
  if p_group_id is null then
    if jsonb_array_length(coalesce(p_splits, '[]'::jsonb)) > 0 then
      raise exception 'Splits require a shared group';
    end if;
    return;
  end if;

  select * into v_group from public.expense_groups where id = p_group_id;
  if not found then
    raise exception 'Group not found';
  end if;

  if p_paid_by_member_id is not null and not exists (
    select 1 from public.expense_group_members
    where id = p_paid_by_member_id and group_id = p_group_id
  ) then
    raise exception 'Payer must be a group member';
  end if;

  if v_group.group_type = 'organizational' then
    if jsonb_array_length(coalesce(p_splits, '[]'::jsonb)) > 0 then
      raise exception 'Organizational groups do not use splits';
    end if;
    return;
  end if;

  v_count := jsonb_array_length(coalesce(p_splits, '[]'::jsonb));
  if v_count < 2 then
    raise exception 'Shared expenses need at least 2 participants';
  end if;

  for v_split in select * from jsonb_array_elements(p_splits)
  loop
    if not exists (
      select 1 from public.expense_group_members
      where id = (v_split->>'group_member_id')::uuid
        and group_id = p_group_id
        and invite_status = 'active'
    ) then
      raise exception 'Invalid split participant';
    end if;
    v_total_owed := v_total_owed + (v_split->>'owed_amount')::numeric;
  end loop;

  if abs(v_total_owed - p_amount) > 0.01 then
    raise exception 'Split amounts must equal expense total';
  end if;
end;
$$ language plpgsql security definer;

create or replace function public._insert_expense_splits(
  p_expense_id uuid,
  p_splits jsonb
)
returns void as $$
declare
  v_split jsonb;
begin
  for v_split in select * from jsonb_array_elements(coalesce(p_splits, '[]'::jsonb))
  loop
    insert into public.expense_splits (
      expense_id, group_member_id, share_type, share_value, owed_amount
    ) values (
      p_expense_id,
      (v_split->>'group_member_id')::uuid,
      v_split->>'share_type',
      nullif(v_split->>'share_value', '')::numeric,
      (v_split->>'owed_amount')::numeric
    );
  end loop;
end;
$$ language plpgsql security definer;

create or replace function public.create_expense_with_splits(
  p_household_id uuid,
  p_category_id uuid,
  p_amount numeric,
  p_title text,
  p_expense_date date,
  p_note text default null,
  p_group_id uuid default null,
  p_paid_by_member_id uuid default null,
  p_splits jsonb default '[]'::jsonb
)
returns public.expenses as $$
declare
  v_expense public.expenses;
begin
  if p_amount <= 0 then
    raise exception 'Amount must be positive';
  end if;

  perform public._validate_expense_splits(
    p_group_id, p_amount, p_paid_by_member_id, p_splits
  );

  insert into public.expenses (
    household_id, category_id, amount, title, note, expense_date,
    entry_type, group_id, paid_by_member_id, paid_by, created_by
  ) values (
    p_household_id, p_category_id, p_amount, p_title, p_note, p_expense_date,
    'expense', p_group_id, p_paid_by_member_id, auth.uid(), auth.uid()
  )
  returning * into v_expense;

  if p_group_id is not null then
    perform public._insert_expense_splits(v_expense.id, p_splits);
  end if;

  return v_expense;
end;
$$ language plpgsql security definer;

create or replace function public.update_expense_with_splits(
  p_expense_id uuid,
  p_category_id uuid,
  p_amount numeric,
  p_title text,
  p_expense_date date,
  p_note text default null,
  p_group_id uuid default null,
  p_paid_by_member_id uuid default null,
  p_splits jsonb default '[]'::jsonb
)
returns public.expenses as $$
declare
  v_expense public.expenses;
begin
  select * into v_expense from public.expenses where id = p_expense_id;
  if not found then
    raise exception 'Expense not found';
  end if;

  if v_expense.created_by <> auth.uid()
     and not public.is_household_owner(v_expense.household_id) then
    raise exception 'Not allowed';
  end if;

  if p_amount <= 0 then
    raise exception 'Amount must be positive';
  end if;

  perform public._validate_expense_splits(
    p_group_id, p_amount, p_paid_by_member_id, p_splits
  );

  delete from public.expense_splits where expense_id = p_expense_id;

  update public.expenses
  set
    category_id = p_category_id,
    amount = p_amount,
    title = p_title,
    note = p_note,
    expense_date = p_expense_date,
    group_id = p_group_id,
    paid_by_member_id = p_paid_by_member_id
  where id = p_expense_id
  returning * into v_expense;

  if p_group_id is not null then
    perform public._insert_expense_splits(v_expense.id, p_splits);
  end if;

  return v_expense;
end;
$$ language plpgsql security definer;

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
    -- Qualify + alias so display_name does not clash with RETURNS TABLE out-params.
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

create or replace function public.record_expense_settlement(
  p_group_id uuid,
  p_from_member_id uuid,
  p_to_member_id uuid,
  p_amount numeric,
  p_note text default null
)
returns public.expense_settlements as $$
declare
  v_row public.expense_settlements;
  v_from_balance numeric;
  v_to_balance numeric;
begin
  if p_from_member_id = p_to_member_id then
    raise exception 'Cannot settle with yourself';
  end if;
  if p_amount <= 0 then
    raise exception 'Amount must be positive';
  end if;

  if not exists (
    select 1 from public.expense_group_members
    where id = p_from_member_id and group_id = p_group_id
  ) or not exists (
    select 1 from public.expense_group_members
    where id = p_to_member_id and group_id = p_group_id
  ) then
    raise exception 'Invalid group members';
  end if;

  select net_balance into v_from_balance
  from public.expense_group_balances(p_group_id)
  where group_member_id = p_from_member_id;

  if v_from_balance is null or v_from_balance > -0.01 then
    raise exception 'Payer does not owe enough to settle';
  end if;

  if p_amount > abs(v_from_balance) + 0.01 then
    raise exception 'Settlement exceeds outstanding balance';
  end if;

  insert into public.expense_settlements (
    group_id, from_member_id, to_member_id, amount, note, created_by
  ) values (
    p_group_id, p_from_member_id, p_to_member_id, p_amount, p_note, auth.uid()
  )
  returning * into v_row;

  return v_row;
end;
$$ language plpgsql security definer;
