-- Family roster: app members + profile-only members with detail cards

create table public.household_family_members (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete set null,
  display_name text not null,
  relationship text not null check (
    relationship in (
      'self', 'spouse', 'parent', 'child', 'sibling',
      'grandparent', 'grandchild', 'in_law', 'other'
    )
  ),
  member_type text not null check (member_type in ('app', 'roster')),
  invited_email text,
  invite_status text check (
    invite_status is null or invite_status in ('pending', 'active', 'cancelled')
  ),
  phone text,
  date_of_birth date,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

create unique index household_family_members_user_unique
  on public.household_family_members (household_id, user_id)
  where user_id is not null;

create unique index household_family_members_pending_email_unique
  on public.household_family_members (household_id, lower(invited_email))
  where invite_status = 'pending' and invited_email is not null;

create table public.household_member_details (
  family_member_id uuid primary key references public.household_family_members(id) on delete cascade,
  household_id uuid not null references public.households(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete set null,
  phone text,
  alt_phone text,
  date_of_birth date,
  blood_group text,
  allergies text,
  medicines text,
  doctor_name text,
  doctor_phone text,
  dietary_preference text check (
    dietary_preference is null
    or dietary_preference in ('veg', 'non_veg', 'vegan', 'other')
  ),
  food_allergies text,
  clothing_sizes jsonb,
  work_place text,
  school_name text,
  emergency_contact_name text,
  emergency_contact_phone text,
  emergency_contact_relation text,
  notes text,
  avatar_url text,
  visibility jsonb not null default '{}'::jsonb,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

create table public.member_medicine_schedules (
  id uuid primary key default gen_random_uuid(),
  family_member_id uuid not null references public.household_family_members(id) on delete cascade,
  household_id uuid not null references public.households(id) on delete cascade,
  medicine_name text not null,
  dosage text,
  times_per_day jsonb not null default '[]'::jsonb,
  reminder_notify_user_id uuid references public.profiles(id) on delete set null,
  is_active boolean not null default true,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz default now() not null
);

alter table public.household_family_members enable row level security;
alter table public.household_member_details enable row level security;
alter table public.member_medicine_schedules enable row level security;

create trigger household_family_members_updated_at
  before update on public.household_family_members
  for each row execute function public.handle_updated_at();

create trigger household_member_details_updated_at
  before update on public.household_member_details
  for each row execute function public.handle_updated_at();

create policy "Members can view family roster"
  on public.household_family_members for select
  using (public.is_household_member(household_id));

create policy "Owners can manage family roster"
  on public.household_family_members for all
  using (public.is_household_owner(household_id));

create policy "Members can view member details"
  on public.household_member_details for select
  using (public.is_household_member(household_id));

create policy "Owners can manage member details"
  on public.household_member_details for all
  using (public.is_household_owner(household_id));

create policy "Linked users can update own details"
  on public.household_member_details for update
  using (user_id = auth.uid());

create policy "Members can view medicine schedules"
  on public.member_medicine_schedules for select
  using (public.is_household_member(household_id));

create policy "Members can manage medicine schedules"
  on public.member_medicine_schedules for all
  using (public.is_household_member(household_id));

-- Seed roster from existing app memberships
insert into public.household_family_members (
  household_id, user_id, display_name, relationship, member_type, invite_status, created_by
)
select
  hm.household_id,
  hm.user_id,
  coalesce(p.display_name, split_part(u.email, '@', 1), 'Member'),
  case when hm.role = 'owner' then 'self' else 'other' end,
  'app',
  'active',
  hm.user_id
from public.household_memberships hm
join public.profiles p on p.id = hm.user_id
join auth.users u on u.id = hm.user_id
on conflict do nothing;

insert into public.household_member_details (family_member_id, household_id, user_id)
select fm.id, fm.household_id, fm.user_id
from public.household_family_members fm
where fm.member_type = 'app'
on conflict do nothing;

-- Pending invites → roster rows
insert into public.household_family_members (
  household_id, display_name, relationship, member_type,
  invited_email, invite_status, created_by
)
select
  hi.household_id,
  split_part(hi.invited_email, '@', 1),
  'other',
  'app',
  hi.invited_email,
  'pending',
  hi.invited_by
from public.household_invites hi
where hi.status = 'pending'
on conflict do nothing;

create or replace function public.create_household(p_name text)
returns uuid as $$
declare
  v_household_id uuid;
  v_display_name text;
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

create or replace function public.add_roster_family_member(
  p_household_id uuid,
  p_display_name text,
  p_relationship text,
  p_phone text default null,
  p_date_of_birth date default null
)
returns uuid as $$
declare
  v_id uuid;
begin
  if not public.is_household_owner(p_household_id) then
    raise exception 'Only the family owner can add profile-only members';
  end if;

  insert into public.household_family_members (
    household_id, display_name, relationship, member_type, phone, date_of_birth, created_by
  ) values (
    p_household_id, trim(p_display_name), p_relationship, 'roster',
    nullif(trim(p_phone), ''), p_date_of_birth, auth.uid()
  )
  returning id into v_id;

  insert into public.household_member_details (
    family_member_id, household_id, phone, date_of_birth
  ) values (
    v_id, p_household_id, nullif(trim(p_phone), ''), p_date_of_birth
  );

  return v_id;
end;
$$ language plpgsql security definer;

create or replace function public.invite_app_family_member(
  p_household_id uuid,
  p_email text,
  p_relationship text
)
returns uuid as $$
declare
  v_email text := lower(trim(p_email));
  v_id uuid;
  v_display_name text := split_part(v_email, '@', 1);
begin
  if not public.is_household_owner(p_household_id) then
    raise exception 'Only the family owner can invite members';
  end if;

  insert into public.household_invites (household_id, invited_email, invited_by)
  values (p_household_id, v_email, auth.uid())
  on conflict (household_id, invited_email) do update
    set status = 'pending', invited_by = auth.uid(), created_at = now();

  insert into public.household_family_members (
    household_id, display_name, relationship, member_type,
    invited_email, invite_status, created_by
  ) values (
    p_household_id, v_display_name, p_relationship, 'app', v_email, 'pending', auth.uid()
  )
  on conflict do nothing
  returning id into v_id;

  if v_id is null then
    update public.household_family_members
    set relationship = p_relationship,
        invite_status = 'pending',
        updated_at = now()
    where household_id = p_household_id
      and lower(invited_email) = v_email
    returning id into v_id;
  end if;

  return v_id;
end;
$$ language plpgsql security definer;

create or replace function public.remove_family_roster_member(p_family_member_id uuid)
returns void as $$
declare
  v_row public.household_family_members%rowtype;
begin
  select * into v_row
  from public.household_family_members
  where id = p_family_member_id;

  if not found then
    raise exception 'Family member not found';
  end if;

  if v_row.relationship = 'self' then
    raise exception 'Cannot remove the household creator';
  end if;

  if not public.is_household_owner(v_row.household_id) then
    raise exception 'Only the family owner can remove roster members';
  end if;

  if v_row.member_type = 'app' and v_row.user_id is not null then
    perform public.remove_household_member(v_row.household_id, v_row.user_id);
  end if;

  if v_row.invite_status = 'pending' and v_row.invited_email is not null then
    update public.household_invites
    set status = 'cancelled'
    where household_id = v_row.household_id
      and lower(invited_email) = lower(v_row.invited_email)
      and status = 'pending';
  end if;

  delete from public.household_family_members where id = p_family_member_id;
end;
$$ language plpgsql security definer;

create or replace function public.upsert_member_details(
  p_family_member_id uuid,
  p_details jsonb
)
returns void as $$
declare
  v_household_id uuid;
  v_user_id uuid;
  v_created_by uuid;
begin
  select household_id, user_id, created_by
  into v_household_id, v_user_id, v_created_by
  from public.household_family_members
  where id = p_family_member_id;

  if not found then
    raise exception 'Family member not found';
  end if;

  if not (
    public.is_household_owner(v_household_id)
    or v_user_id = auth.uid()
    or (v_created_by = auth.uid() and v_user_id is null)
  ) then
    raise exception 'Not allowed to edit this member card';
  end if;

  insert into public.household_member_details (
    family_member_id, household_id, user_id,
    phone, alt_phone, date_of_birth, blood_group, allergies, medicines,
    doctor_name, doctor_phone, dietary_preference, food_allergies,
    work_place, school_name,
    emergency_contact_name, emergency_contact_phone, emergency_contact_relation,
    notes
  ) values (
    p_family_member_id, v_household_id, v_user_id,
    p_details->>'phone', p_details->>'alt_phone',
    nullif(p_details->>'date_of_birth', '')::date,
    p_details->>'blood_group', p_details->>'allergies', p_details->>'medicines',
    p_details->>'doctor_name', p_details->>'doctor_phone',
    p_details->>'dietary_preference', p_details->>'food_allergies',
    p_details->>'work_place', p_details->>'school_name',
    p_details->>'emergency_contact_name', p_details->>'emergency_contact_phone',
    p_details->>'emergency_contact_relation',
    p_details->>'notes'
  )
  on conflict (family_member_id) do update set
    phone = excluded.phone,
    alt_phone = excluded.alt_phone,
    date_of_birth = excluded.date_of_birth,
    blood_group = excluded.blood_group,
    allergies = excluded.allergies,
    medicines = excluded.medicines,
    doctor_name = excluded.doctor_name,
    doctor_phone = excluded.doctor_phone,
    dietary_preference = excluded.dietary_preference,
    food_allergies = excluded.food_allergies,
    work_place = excluded.work_place,
    school_name = excluded.school_name,
    emergency_contact_name = excluded.emergency_contact_name,
    emergency_contact_phone = excluded.emergency_contact_phone,
    emergency_contact_relation = excluded.emergency_contact_relation,
    notes = excluded.notes,
    updated_at = now();
end;
$$ language plpgsql security definer;

-- Sync membership leave/remove with family roster
create or replace function public.leave_household(p_household_id uuid)
returns void as $$
declare
  v_role text;
begin
  select role into v_role
  from public.household_memberships
  where household_id = p_household_id and user_id = auth.uid();

  if v_role is null then
    raise exception 'Not a member of this household';
  end if;

  if v_role = 'owner' then
    raise exception 'Owner cannot leave. Remove other members or transfer ownership first.';
  end if;

  delete from public.household_memberships
  where household_id = p_household_id and user_id = auth.uid();

  delete from public.household_family_members
  where household_id = p_household_id and user_id = auth.uid();

  update public.profiles
  set active_household_id = null
  where id = auth.uid() and active_household_id = p_household_id;
end;
$$ language plpgsql security definer;

create or replace function public.remove_household_member(
  p_household_id uuid,
  p_user_id uuid
)
returns void as $$
begin
  if not public.is_household_owner(p_household_id) then
    raise exception 'Only the family owner can remove members';
  end if;

  if p_user_id = auth.uid() then
    raise exception 'Use leave_household to leave';
  end if;

  if exists (
    select 1 from public.household_memberships
    where household_id = p_household_id
      and user_id = p_user_id
      and role = 'owner'
  ) then
    raise exception 'Cannot remove the family owner';
  end if;

  delete from public.household_memberships
  where household_id = p_household_id and user_id = p_user_id;

  delete from public.household_family_members
  where household_id = p_household_id and user_id = p_user_id;

  update public.profiles
  set active_household_id = null
  where id = p_user_id and active_household_id = p_household_id;
end;
$$ language plpgsql security definer;
