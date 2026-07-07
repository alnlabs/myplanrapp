-- Recurring bills and subscriptions (optional household module)

create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  created_by uuid references public.profiles(id) on delete set null,
  name text not null,
  amount numeric check (amount is null or amount >= 0),
  currency text not null default 'INR',
  billing_cycle text not null default 'monthly' check (
    billing_cycle in ('monthly', 'yearly')
  ),
  due_day int not null default 1 check (due_day between 1 and 31),
  due_month int check (due_month is null or due_month between 1 and 12),
  auto_renew boolean not null default true,
  reminder_enabled boolean not null default false,
  reminder_days_before int not null default 3 check (reminder_days_before between 0 and 30),
  last_paid_expense_id uuid references public.expenses(id) on delete set null,
  is_active boolean not null default true,
  notes text,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null,
  constraint subscriptions_yearly_month check (
    billing_cycle <> 'yearly' or due_month is not null
  )
);

create index subscriptions_household_idx on public.subscriptions (household_id);
create index subscriptions_active_idx on public.subscriptions (household_id, is_active);

alter table public.subscriptions enable row level security;

create trigger subscriptions_updated_at
  before update on public.subscriptions
  for each row execute function public.handle_updated_at();

create policy "Members can view subscriptions"
  on public.subscriptions for select
  using (
    public.is_household_member(household_id)
    and public.can_access_module(household_id, 'subscriptions')
  );

create policy "Members can add subscriptions"
  on public.subscriptions for insert
  with check (
    public.can_access_module(household_id, 'subscriptions')
    and created_by = auth.uid()
  );

create policy "Creators and owners can update subscriptions"
  on public.subscriptions for update
  using (
    public.can_access_module(household_id, 'subscriptions')
    and (created_by = auth.uid() or public.is_household_owner(household_id))
  );

create policy "Creators and owners can delete subscriptions"
  on public.subscriptions for delete
  using (
    public.can_access_module(household_id, 'subscriptions')
    and (created_by = auth.uid() or public.is_household_owner(household_id))
  );
