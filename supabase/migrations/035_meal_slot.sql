-- Optional meal slot for meal plans (breakfast, lunch, dinner, snack)

alter table public.plans
  add column meal_slot text check (
    meal_slot is null or meal_slot in ('breakfast', 'lunch', 'dinner', 'snack')
  );

create index plans_meal_slot_idx on public.plans (household_id, meal_slot, due_at)
  where plan_type = 'meal' and status = 'open';
