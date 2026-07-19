-- Richer repeat patterns for standalone reminders.
--
-- The coarse frequency stays in `repeat` (none/daily/weekly/monthly/yearly) for
-- backward compatibility. The detailed pattern (every-N interval, specific
-- weekdays, monthly-by-weekday) is stored as JSON in `repeat_config`. It is
-- null for one-time reminders and for the plain interval-1 frequencies that
-- need no extra detail.
--
-- Example configs:
--   {"frequency":"weekly","interval":1,"days_of_week":[1,2,3,4,5]}   -- weekdays
--   {"frequency":"weekly","interval":2,"days_of_week":[2,4]}          -- every 2 weeks Tue/Thu
--   {"frequency":"monthly","interval":1,"monthly_mode":"nth_weekday"} -- e.g. 3rd Tuesday
--   {"frequency":"daily","interval":3}                               -- every 3 days

alter table public.reminders
  add column if not exists repeat_config jsonb;
