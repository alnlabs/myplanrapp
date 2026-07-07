-- Household feature settings and per-member module visibility

create table public.household_settings (
  household_id uuid primary key references public.households(id) on delete cascade,
  enabled_modules text[] not null default array[
    'pantry', 'shopping', 'expenses', 'plans', 'recipes', 'assets', 'member_details'
  ],
  updated_at timestamptz default now() not null
);

create table public.household_member_permissions (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  module text not null,
  is_visible boolean not null default true,
  unique (household_id, user_id, module)
);

alter table public.household_settings enable row level security;
alter table public.household_member_permissions enable row level security;

create trigger household_settings_updated_at
  before update on public.household_settings
  for each row execute function public.handle_updated_at();

create policy "Members can view household settings"
  on public.household_settings for select
  using (public.is_household_member(household_id));

create policy "Owners can manage household settings"
  on public.household_settings for all
  using (public.is_household_owner(household_id));

create policy "Members can view own permissions"
  on public.household_member_permissions for select
  using (
    public.is_household_member(household_id)
    and (user_id = auth.uid() or public.is_household_owner(household_id))
  );

create policy "Owners can manage member permissions"
  on public.household_member_permissions for all
  using (public.is_household_owner(household_id));

create or replace function public.is_module_enabled(
  p_household_id uuid,
  p_module text
)
returns boolean as $$
  select coalesce(
    (
      select p_module = any(enabled_modules)
      from public.household_settings
      where household_id = p_household_id
    ),
    true
  );
$$ language sql stable security definer;

create or replace function public.can_access_module(
  p_household_id uuid,
  p_module text
)
returns boolean as $$
  select
    public.is_household_member(p_household_id)
    and public.is_module_enabled(p_household_id, p_module)
    and (
      public.is_household_owner(p_household_id)
      or coalesce(
        (
          select is_visible
          from public.household_member_permissions
          where household_id = p_household_id
            and user_id = auth.uid()
            and module = p_module
        ),
        true
      )
    );
$$ language sql stable security definer;

create or replace function public.upsert_household_settings(
  p_household_id uuid,
  p_enabled_modules text[]
)
returns void as $$
begin
  if not public.is_household_owner(p_household_id) then
    raise exception 'Only the family owner can change feature settings';
  end if;

  insert into public.household_settings (household_id, enabled_modules)
  values (p_household_id, p_enabled_modules)
  on conflict (household_id) do update set
    enabled_modules = excluded.enabled_modules,
    updated_at = now();

  insert into public.household_member_permissions (household_id, user_id, module, is_visible)
  select p_household_id, hm.user_id, m.module, true
  from public.household_memberships hm
  cross join unnest(p_enabled_modules) as m(module)
  on conflict (household_id, user_id, module) do nothing;
end;
$$ language plpgsql security definer;

create or replace function public.seed_member_permissions(p_household_id uuid, p_user_id uuid)
returns void as $$
declare
  v_modules text[];
begin
  select enabled_modules into v_modules
  from public.household_settings
  where household_id = p_household_id;

  if v_modules is null then
    v_modules := array['pantry','shopping','expenses','plans','recipes','assets','member_details'];
  end if;

  insert into public.household_member_permissions (household_id, user_id, module, is_visible)
  select p_household_id, p_user_id, m, true
  from unnest(v_modules) as m
  on conflict (household_id, user_id, module) do nothing;
end;
$$ language plpgsql security definer;

-- Seed settings for existing households
insert into public.household_settings (household_id)
select id from public.households
on conflict (household_id) do nothing;

-- Update create_household to init settings
create or replace function public.create_household(p_name text)
returns uuid as $$
declare
  v_household_id uuid;
  v_display_name text;
  v_default_modules text[] := array[
    'pantry', 'shopping', 'expenses', 'plans', 'recipes', 'assets', 'member_details'
  ];
begin
  select coalesce(display_name, 'Me')
  into v_display_name
  from public.profiles
  where id = auth.uid();

  insert into public.households (name, owner_id)
  values (p_name, auth.uid())
  returning id into v_household_id;

  insert into public.household_memberships (household_id, user_id, role)
  values (v_household_id, auth.uid(), 'owner');

  insert into public.household_settings (household_id, enabled_modules)
  values (v_household_id, v_default_modules);

  perform public.seed_member_permissions(v_household_id, auth.uid());

  insert into public.household_family_members (
    household_id, user_id, display_name, relationship, member_type, invite_status, created_by
  ) values (
    v_household_id, auth.uid(), v_display_name, 'self', 'app', 'active', auth.uid()
  );

  insert into public.household_member_details (family_member_id, household_id, user_id)
  select id, household_id, user_id
  from public.household_family_members
  where household_id = v_household_id and user_id = auth.uid();

  update public.profiles
  set active_household_id = v_household_id
  where id = auth.uid();

  return v_household_id;
end;
$$ language plpgsql security definer;

create or replace function public.accept_household_invite(p_household_id uuid)
returns void as $$
declare
  v_email text;
  v_display_name text;
  v_family_member_id uuid;
begin
  select email into v_email from auth.users where id = auth.uid();
  select coalesce(display_name, split_part(v_email, '@', 1))
  into v_display_name
  from public.profiles where id = auth.uid();

  insert into public.household_memberships (household_id, user_id, role)
  values (p_household_id, auth.uid(), 'member')
  on conflict (household_id, user_id) do nothing;

  perform public.seed_member_permissions(p_household_id, auth.uid());

  update public.household_invites
  set status = 'accepted'
  where household_id = p_household_id
    and lower(invited_email) = lower(v_email)
    and status = 'pending';

  update public.household_family_members
  set user_id = auth.uid(),
      display_name = v_display_name,
      invite_status = 'active',
      updated_at = now()
  where household_id = p_household_id
    and lower(invited_email) = lower(v_email)
    and invite_status = 'pending'
  returning id into v_family_member_id;

  if v_family_member_id is null then
    insert into public.household_family_members (
      household_id, user_id, display_name, relationship, member_type, invite_status, created_by
    ) values (
      p_household_id, auth.uid(), v_display_name, 'other', 'app', 'active', auth.uid()
    )
    returning id into v_family_member_id;
  end if;

  insert into public.household_member_details (family_member_id, household_id, user_id)
  values (v_family_member_id, p_household_id, auth.uid())
  on conflict (family_member_id) do update set user_id = auth.uid();

  update public.profiles
  set active_household_id = p_household_id
  where id = auth.uid();
end;
$$ language plpgsql security definer;
