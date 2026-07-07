-- Allow household managers (owner or co-owner) to revoke a pending invite.
-- Keeps household_invites and the matching roster entry in sync.

create or replace function public.cancel_household_invite(p_invite_id uuid)
returns void as $$
declare
  v_invite public.household_invites%rowtype;
begin
  select * into v_invite
  from public.household_invites
  where id = p_invite_id;

  if not found then
    raise exception 'Invite not found';
  end if;

  if not public.is_household_manager(v_invite.household_id) then
    raise exception 'Only owners or co-owners can revoke invites';
  end if;

  update public.household_invites
  set status = 'cancelled'
  where id = p_invite_id
    and status = 'pending';

  update public.household_family_members
  set invite_status = 'cancelled',
      updated_at = now()
  where household_id = v_invite.household_id
    and lower(invited_email) = lower(v_invite.invited_email)
    and invite_status = 'pending';
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function public.cancel_household_invite(uuid) to authenticated;
