-- Standalone reminders: generic household reminders with local notifications.

create table public.reminders (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  notes text,
  reminder_at timestamptz not null,
  is_active boolean not null default true,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

create index reminders_household_active_idx
  on public.reminders (household_id, reminder_at)
  where is_active = true;

alter table public.reminders enable row level security;

create policy "Users can view own reminders"
  on public.reminders for select
  using (
    public.is_household_member(household_id)
    and user_id = auth.uid()
  );

create policy "Users can create own reminders"
  on public.reminders for insert
  with check (
    public.is_household_member(household_id)
    and user_id = auth.uid()
  );

create policy "Users can update own reminders"
  on public.reminders for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "Users can delete own reminders"
  on public.reminders for delete
  using (user_id = auth.uid());

create trigger reminders_updated_at
  before update on public.reminders
  for each row execute function public.handle_updated_at();
