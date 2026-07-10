-- Recurring money rules (income and future expense automation)

create table public.recurring_money_rules (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  created_by uuid references public.profiles(id) on delete set null,
  entry_type text not null default 'income' check (entry_type in ('expense', 'income')),
  title text not null,
  amount numeric not null check (amount > 0),
  category_id uuid not null references public.expense_categories(id) on delete restrict,
  note text,
  income_source text,
  family_member_id uuid references public.household_family_members(id) on delete set null,
  frequency text not null default 'monthly' check (
    frequency in ('weekly', 'monthly', 'yearly')
  ),
  interval_count int not null default 1 check (interval_count > 0),
  day_of_month int check (day_of_month is null or day_of_month between 1 and 31),
  day_of_week int check (day_of_week is null or day_of_week between 1 and 7),
  month_of_year int check (month_of_year is null or month_of_year between 1 and 12),
  start_date date not null default current_date,
  end_date date,
  next_due_date date not null,
  is_active boolean not null default true,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null,
  constraint recurring_income_member_check check (
    entry_type <> 'income'
    or (family_member_id is not null and income_source is not null and length(trim(income_source)) > 0)
  )
);

create index recurring_money_rules_household_idx
  on public.recurring_money_rules (household_id, is_active, next_due_date);

create index recurring_money_rules_member_idx
  on public.recurring_money_rules (family_member_id)
  where entry_type = 'income';

alter table public.recurring_money_rules enable row level security;

create trigger recurring_money_rules_updated_at
  before update on public.recurring_money_rules
  for each row execute function public.handle_updated_at();

create policy "Members can view recurring money rules"
  on public.recurring_money_rules for select
  using (public.is_household_member(household_id));

create policy "Members can manage recurring money rules"
  on public.recurring_money_rules for all
  using (public.is_household_member(household_id));

alter table public.expenses
  add column if not exists recurring_rule_id uuid
    references public.recurring_money_rules(id) on delete set null;

create or replace function public.advance_recurring_money_rule(p_rule_id uuid)
returns public.recurring_money_rules as $$
declare
  v_rule public.recurring_money_rules;
  v_next date;
begin
  select * into v_rule from public.recurring_money_rules where id = p_rule_id;
  if not found then
    raise exception 'Rule not found';
  end if;

  v_next := v_rule.next_due_date;

  while v_next <= current_date loop
    if v_rule.frequency = 'weekly' then
      v_next := v_next + (v_rule.interval_count * 7);
    elsif v_rule.frequency = 'monthly' then
      v_next := (v_next + (v_rule.interval_count || ' months')::interval)::date;
    else
      v_next := (v_next + (v_rule.interval_count || ' years')::interval)::date;
    end if;
  end loop;

  if v_rule.end_date is not null and v_next > v_rule.end_date then
    update public.recurring_money_rules
    set is_active = false, next_due_date = v_next, updated_at = now()
    where id = p_rule_id
    returning * into v_rule;
  else
    update public.recurring_money_rules
    set next_due_date = v_next, updated_at = now()
    where id = p_rule_id
    returning * into v_rule;
  end if;

  return v_rule;
end;
$$ language plpgsql security definer;
