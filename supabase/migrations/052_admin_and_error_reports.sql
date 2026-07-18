-- Admin visibility for feedback + client error reports.
-- Admins are designated by profiles.is_admin (set manually in Supabase).
-- In-app admin access is additionally gated behind an email OTP step-up.

-- 1. Admin flag on profiles.
alter table public.profiles
  add column if not exists is_admin boolean not null default false;

-- 2. Helper: is the current user an admin? Security definer avoids RLS recursion.
create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select coalesce(
    (select is_admin from public.profiles where id = auth.uid()),
    false
  );
$$;

-- 3. Client error reports (crashes / captured errors uploaded from the app).
create table if not exists public.error_reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade,
  message text not null,
  error text,
  stack_trace text,
  app_version text,
  platform text,
  created_at timestamptz default now() not null
);

create index if not exists error_reports_created_at_idx
  on public.error_reports (created_at desc);

alter table public.error_reports enable row level security;

-- Authenticated users may insert their own reports.
drop policy if exists "Users can submit own error reports" on public.error_reports;
create policy "Users can submit own error reports"
  on public.error_reports for insert
  with check (user_id = auth.uid());

-- Only admins may read error reports.
drop policy if exists "Admins can view error reports" on public.error_reports;
create policy "Admins can view error reports"
  on public.error_reports for select
  using (public.is_admin());

-- 4. Admin read access to feedback (in addition to the existing own-feedback policy).
drop policy if exists "Admins can view all feedback" on public.feedback;
create policy "Admins can view all feedback"
  on public.feedback for select
  using (public.is_admin());

-- 5. Admins can read all profiles (to show reporter names in the admin view).
drop policy if exists "Admins can view all profiles" on public.profiles;
create policy "Admins can view all profiles"
  on public.profiles for select
  using (public.is_admin());
