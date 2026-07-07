-- Households (families)

create table public.households (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  owner_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

create table public.household_memberships (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null default 'member' check (role in ('owner', 'member')),
  joined_at timestamptz default now() not null,
  unique (household_id, user_id)
);

create table public.household_invites (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  invited_email text not null,
  invited_by uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'cancelled')),
  created_at timestamptz default now() not null,
  unique (household_id, invited_email)
);

alter table public.profiles
  add constraint profiles_active_household_fkey
  foreign key (active_household_id) references public.households(id) on delete set null;

alter table public.households enable row level security;
alter table public.household_memberships enable row level security;
alter table public.household_invites enable row level security;

create or replace function public.is_household_member(p_household_id uuid)
returns boolean as $$
  select exists (
    select 1 from public.household_memberships
    where household_id = p_household_id and user_id = auth.uid()
  );
$$ language sql security definer stable;

create or replace function public.is_household_owner(p_household_id uuid)
returns boolean as $$
  select exists (
    select 1 from public.household_memberships
    where household_id = p_household_id and user_id = auth.uid() and role = 'owner'
  );
$$ language sql security definer stable;

create policy "Members can view households"
  on public.households for select
  using (public.is_household_member(id));

create policy "Users can create households"
  on public.households for insert
  with check (auth.uid() = owner_id);

create policy "Owners can update households"
  on public.households for update
  using (public.is_household_owner(id));

create policy "Members can view memberships"
  on public.household_memberships for select
  using (public.is_household_member(household_id));

create policy "Owners can manage memberships"
  on public.household_memberships for all
  using (public.is_household_owner(household_id));

create policy "Users can join via invite"
  on public.household_memberships for insert
  with check (
    auth.uid() = user_id and exists (
      select 1 from public.household_invites hi
      join auth.users u on u.id = auth.uid()
      where hi.household_id = household_memberships.household_id
        and lower(hi.invited_email) = lower(u.email)
        and hi.status = 'pending'
    )
  );

create policy "Members can view invites"
  on public.household_invites for select
  using (public.is_household_member(household_id));

create policy "Owners can manage invites"
  on public.household_invites for all
  using (public.is_household_owner(household_id));

create trigger households_updated_at
  before update on public.households
  for each row execute function public.handle_updated_at();

create or replace function public.create_household(p_name text)
returns uuid as $$
declare
  v_household_id uuid;
begin
  insert into public.households (name, owner_id)
  values (p_name, auth.uid())
  returning id into v_household_id;

  insert into public.household_memberships (household_id, user_id, role)
  values (v_household_id, auth.uid(), 'owner');

  update public.profiles
  set active_household_id = v_household_id
  where id = auth.uid();

  return v_household_id;
end;
$$ language plpgsql security definer;

create or replace function public.accept_household_invite(p_household_id uuid)
returns void as $$
begin
  insert into public.household_memberships (household_id, user_id, role)
  values (p_household_id, auth.uid(), 'member')
  on conflict (household_id, user_id) do nothing;

  update public.household_invites
  set status = 'accepted'
  where household_id = p_household_id
    and lower(invited_email) = lower((select email from auth.users where id = auth.uid()))
    and status = 'pending';

  update public.profiles
  set active_household_id = p_household_id
  where id = auth.uid();
end;
$$ language plpgsql security definer;
