-- Per-household daily usage counter for the receipt assistant, so a runaway
-- loop or abuse can't burn through the LLM budget. The edge function calls
-- bump_assistant_usage() before each model call; it returns false once the
-- daily limit is reached (no increment past the cap).

create table if not exists public.assistant_usage (
  household_id uuid not null references public.households(id) on delete cascade,
  usage_date date not null default current_date,
  count int not null default 0,
  primary key (household_id, usage_date)
);

alter table public.assistant_usage enable row level security;

drop policy if exists "Members can view assistant usage" on public.assistant_usage;
create policy "Members can view assistant usage"
  on public.assistant_usage for select
  using (public.is_household_member(household_id));

-- Atomically checks the cap and increments. Returns true if the call is allowed
-- (and was counted), false if the household already hit today's limit.
create or replace function public.bump_assistant_usage(
  p_household_id uuid,
  p_limit int
)
returns boolean as $$
declare
  v_count int;
begin
  if not public.is_household_member(p_household_id) then
    raise exception 'Not a household member';
  end if;

  select count into v_count
  from public.assistant_usage
  where household_id = p_household_id and usage_date = current_date
  for update;

  if v_count is null then
    insert into public.assistant_usage (household_id, usage_date, count)
    values (p_household_id, current_date, 1)
    on conflict (household_id, usage_date)
      do update set count = public.assistant_usage.count + 1;
    return true;
  end if;

  if v_count >= p_limit then
    return false;
  end if;

  update public.assistant_usage
  set count = v_count + 1
  where household_id = p_household_id and usage_date = current_date;
  return true;
end;
$$ language plpgsql security definer;
