-- Plans: tasks, purchases, meals, medicine with optional reminders

create table public.plans (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  created_by uuid not null references public.profiles(id) on delete cascade,
  scope text not null default 'household' check (scope in ('personal', 'household')),
  plan_type text not null default 'task' check (
    plan_type in ('purchase', 'task', 'meal', 'medicine', 'other')
  ),
  title text not null,
  description text,
  status text not null default 'open' check (status in ('open', 'completed', 'cancelled')),
  due_at timestamptz,
  reminder_enabled boolean not null default false,
  reminder_at timestamptz,
  about_member_id uuid references public.household_family_members(id) on delete set null,
  assigned_to uuid references public.household_family_members(id) on delete set null,
  reminder_notify_user_id uuid references public.profiles(id) on delete set null,
  recipe_id uuid references public.recipes(id) on delete set null,
  completed_at timestamptz,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

create index plans_household_status_idx on public.plans (household_id, status);
create index plans_reminder_idx on public.plans (reminder_at)
  where reminder_enabled = true and status = 'open';

alter table public.plans enable row level security;

create policy "Members can view plans"
  on public.plans for select
  using (
    public.is_household_member(household_id)
    and (scope = 'household' or created_by = auth.uid())
  );

create policy "Members can create plans"
  on public.plans for insert
  with check (
    public.is_household_member(household_id)
    and created_by = auth.uid()
  );

create policy "Creators and owners can update plans"
  on public.plans for update
  using (
    created_by = auth.uid() or public.is_household_owner(household_id)
  );

create policy "Creators and owners can delete plans"
  on public.plans for delete
  using (
    created_by = auth.uid() or public.is_household_owner(household_id)
  );

create trigger plans_updated_at
  before update on public.plans
  for each row execute function public.handle_updated_at();

create or replace function public.complete_plan(p_plan_id uuid)
returns void as $$
begin
  update public.plans
  set
    status = 'completed',
    completed_at = now(),
    reminder_enabled = false,
    updated_at = now()
  where id = p_plan_id
    and public.is_household_member(household_id)
    and status = 'open';

  if not found then
    raise exception 'Plan not found or already completed';
  end if;
end;
$$ language plpgsql security definer;
