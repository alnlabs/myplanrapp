-- Family-specific plan categories.

alter table public.plans
  drop constraint if exists plans_plan_type_check;

alter table public.plans
  add constraint plans_plan_type_check
  check (plan_type in (
    'purchase', 'task', 'meal', 'medicine',
    'bill', 'appointment', 'event', 'travel', 'chore', 'maintenance',
    'birthday', 'school', 'pet', 'childcare', 'outing',
    'other'
  ));
