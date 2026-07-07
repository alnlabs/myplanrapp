-- User feedback: feature requests and bug reports.

create table public.feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  household_id uuid references public.households(id) on delete set null,
  type text not null check (type in ('feature', 'bug', 'other')),
  message text not null,
  contact_email text,
  app_version text,
  created_at timestamptz default now() not null
);

alter table public.feedback enable row level security;

create policy "Users can submit own feedback"
  on public.feedback for insert
  with check (user_id = auth.uid());

create policy "Users can view own feedback"
  on public.feedback for select
  using (user_id = auth.uid());
