-- Allow the family owner to change a member's type:
--   Profile only (roster)  ->  App (invited by email)
--   App                     ->  Profile only (revokes app access)
-- The member's detail card (health, sizes, etc.) is preserved either way.

create or replace function public.convert_roster_to_app(
  p_family_member_id uuid,
  p_email text
)
returns void as $$
declare
  v_row public.household_family_members%rowtype;
  v_email text := lower(trim(p_email));
begin
  select * into v_row
  from public.household_family_members
  where id = p_family_member_id;

  if not found then
    raise exception 'Family member not found';
  end if;

  if not public.is_household_owner(v_row.household_id) then
    raise exception 'Only the family owner can change member type';
  end if;

  if v_row.member_type <> 'roster' then
    raise exception 'Member is already an app member';
  end if;

  if v_email = '' then
    raise exception 'An email is required to invite this member to the app';
  end if;

  insert into public.household_invites (household_id, invited_email, invited_by)
  values (v_row.household_id, v_email, auth.uid())
  on conflict (household_id, invited_email) do update
    set status = 'pending', invited_by = auth.uid(), created_at = now();

  update public.household_family_members
  set member_type = 'app',
      invited_email = v_email,
      invite_status = 'pending',
      updated_at = now()
  where id = p_family_member_id;
end;
$$ language plpgsql security definer;

create or replace function public.convert_app_to_roster(
  p_family_member_id uuid
)
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

  if not public.is_household_owner(v_row.household_id) then
    raise exception 'Only the family owner can change member type';
  end if;

  if v_row.member_type <> 'app' then
    raise exception 'Member is already a profile-only member';
  end if;

  if v_row.relationship = 'self' then
    raise exception 'Cannot change the household creator';
  end if;

  -- If they already joined the app, revoke access (never the owner or self).
  if v_row.user_id is not null then
    if v_row.user_id = auth.uid() then
      raise exception 'You cannot change your own membership here';
    end if;

    if exists (
      select 1 from public.household_memberships
      where household_id = v_row.household_id
        and user_id = v_row.user_id
        and role = 'owner'
    ) then
      raise exception 'Cannot change the family owner';
    end if;

    delete from public.household_memberships
    where household_id = v_row.household_id
      and user_id = v_row.user_id;

    update public.profiles
    set active_household_id = null
    where id = v_row.user_id
      and active_household_id = v_row.household_id;
  end if;

  -- Cancel any still-pending invite for this member.
  if v_row.invited_email is not null then
    update public.household_invites
    set status = 'cancelled'
    where household_id = v_row.household_id
      and lower(invited_email) = lower(v_row.invited_email)
      and status = 'pending';
  end if;

  update public.household_family_members
  set member_type = 'roster',
      user_id = null,
      invited_email = null,
      invite_status = null,
      updated_at = now()
  where id = p_family_member_id;
end;
$$ language plpgsql security definer;
