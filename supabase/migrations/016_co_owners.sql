-- Co-owners: the household creator is the owner and can promote app members to
-- co-owner. Owners and co-owners ("managers") can add/manage family members.

-- 1. Allow the co_owner role.
alter table public.household_memberships
  drop constraint if exists household_memberships_role_check;
alter table public.household_memberships
  add constraint household_memberships_role_check
  check (role in ('owner', 'co_owner', 'member'));

-- 2. Manager = owner or co_owner.
create or replace function public.is_household_manager(p_household_id uuid)
returns boolean as $$
  select exists (
    select 1 from public.household_memberships
    where household_id = p_household_id
      and user_id = auth.uid()
      and role in ('owner', 'co_owner')
  );
$$ language sql security definer stable;

-- 3. Owner-only: change an app member's role between co_owner and member.
create or replace function public.set_member_role(
  p_household_id uuid,
  p_user_id uuid,
  p_role text
)
returns void as $$
begin
  if not public.is_household_owner(p_household_id) then
    raise exception 'Only the owner can change member roles';
  end if;

  if p_role not in ('co_owner', 'member') then
    raise exception 'Invalid role';
  end if;

  if exists (
    select 1 from public.household_memberships
    where household_id = p_household_id
      and user_id = p_user_id
      and role = 'owner'
  ) then
    raise exception 'The owner role cannot be changed';
  end if;

  update public.household_memberships
  set role = p_role
  where household_id = p_household_id and user_id = p_user_id;

  if not found then
    raise exception 'Member not found';
  end if;
end;
$$ language plpgsql security definer;

-- 4. Let managers (owner + co_owner) manage the family roster and details.
drop policy if exists "Owners can manage family roster" on public.household_family_members;
create policy "Managers can manage family roster"
  on public.household_family_members for all
  using (public.is_household_manager(household_id));

drop policy if exists "Owners can manage member details" on public.household_member_details;
create policy "Managers can manage member details"
  on public.household_member_details for all
  using (public.is_household_manager(household_id));

-- 5. Relax add/invite roster functions from owner-only to manager.
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
  if not public.is_household_manager(p_household_id) then
    raise exception 'Only owners or co-owners can add members';
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
  if not public.is_household_manager(p_household_id) then
    raise exception 'Only owners or co-owners can invite members';
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

-- 6. Let managers remove roster members (still never the creator/self).
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

  if not public.is_household_manager(v_row.household_id) then
    raise exception 'Only owners or co-owners can remove roster members';
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
