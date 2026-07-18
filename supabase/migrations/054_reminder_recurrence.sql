-- Add repeat/recurrence support to standalone reminders.
-- Recurrence is handled client-side via OS repeating notifications, so we only
-- need to persist the chosen frequency alongside the anchor time (reminder_at).

alter table public.reminders
  add column if not exists repeat text not null default 'none';

alter table public.reminders
  drop constraint if exists reminders_repeat_check;

alter table public.reminders
  add constraint reminders_repeat_check
  check (repeat in ('none', 'daily', 'weekly', 'monthly', 'yearly'));
