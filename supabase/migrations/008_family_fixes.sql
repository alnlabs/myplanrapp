-- Family sharing fixes: invite visibility, co-member profiles, leave/remove

create policy "Invitees can view their pending invites"
  on public.household_invites for select
  using (
    status = 'pending'
    and lower(invited_email) = lower(
      (select email from auth.users where id = auth.uid())
    )
  );

create policy "Household members can view co-member profiles"
  on public.profiles for select
  using (
    exists (
      select 1
      from public.household_memberships hm_self
      join public.household_memberships hm_other
        on hm_self.household_id = hm_other.household_id
      where hm_self.user_id = auth.uid()
        and hm_other.user_id = profiles.id
    )
  );

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

  update public.profiles
  set active_household_id = null
  where id = p_user_id and active_household_id = p_household_id;
end;
$$ language plpgsql security definer;
