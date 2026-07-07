-- Store custom reminder date/time for subscriptions.

alter table public.subscriptions
  add column if not exists reminder_at timestamptz;
