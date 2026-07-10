-- Extend recurring money rules for recurring expenses + subscription link

alter table public.recurring_money_rules
  add column if not exists auto_log boolean not null default false,
  add column if not exists snooze_until date,
  add column if not exists group_id uuid references public.expense_groups(id) on delete set null,
  add column if not exists paid_by_member_id uuid
    references public.expense_group_members(id) on delete set null,
  add column if not exists subscription_id uuid
    references public.subscriptions(id) on delete set null;

alter table public.expenses
  add column if not exists source_subscription_id uuid
    references public.subscriptions(id) on delete set null,
  add column if not exists is_recurring_instance boolean not null default false;

create index if not exists recurring_money_rules_expense_due_idx
  on public.recurring_money_rules (household_id, entry_type, is_active, next_due_date)
  where entry_type = 'expense';

create or replace function public.snooze_recurring_money_rule(
  p_rule_id uuid,
  p_snooze_until date
)
returns public.recurring_money_rules as $$
declare
  v_rule public.recurring_money_rules;
begin
  update public.recurring_money_rules
  set snooze_until = p_snooze_until, updated_at = now()
  where id = p_rule_id
  returning * into v_rule;
  if not found then
    raise exception 'Rule not found';
  end if;
  return v_rule;
end;
$$ language plpgsql security definer;

create or replace function public.log_recurring_expense(
  p_rule_id uuid,
  p_expense_date date default current_date
)
returns public.expenses as $$
declare
  v_rule public.recurring_money_rules;
  v_expense public.expenses;
begin
  select * into v_rule
  from public.recurring_money_rules
  where id = p_rule_id and entry_type = 'expense' and is_active = true;
  if not found then
    raise exception 'Recurring expense rule not found';
  end if;

  insert into public.expenses (
    household_id, category_id, amount, title, note, expense_date,
    entry_type, group_id, paid_by_member_id, recurring_rule_id,
    source_subscription_id, is_recurring_instance, paid_by, created_by
  ) values (
    v_rule.household_id, v_rule.category_id, v_rule.amount, v_rule.title,
    v_rule.note, p_expense_date, 'expense', v_rule.group_id,
    v_rule.paid_by_member_id, v_rule.id, v_rule.subscription_id, true,
    auth.uid(), auth.uid()
  )
  returning * into v_expense;

  if v_rule.subscription_id is not null then
    update public.subscriptions
    set last_paid_expense_id = v_expense.id, updated_at = now()
    where id = v_rule.subscription_id;
  end if;

  perform public.advance_recurring_money_rule(p_rule_id);

  return v_expense;
end;
$$ language plpgsql security definer;
