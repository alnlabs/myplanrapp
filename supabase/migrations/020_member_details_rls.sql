-- Restrict direct reads of member details; field filtering stays in RPC.

drop policy if exists "Members can view member details" on public.household_member_details;

create policy "Managers can view member details"
  on public.household_member_details for select
  using (public.is_household_manager(household_id));

create policy "Linked users can view own member details"
  on public.household_member_details for select
  using (user_id = auth.uid());

create policy "Roster creators can view managed member details"
  on public.household_member_details for select
  using (
    exists (
      select 1 from public.household_family_members fm
      where fm.id = household_member_details.family_member_id
        and fm.created_by = auth.uid()
        and fm.user_id is null
    )
  );

-- Household members still see avatar_url via roster join on household_family_members.
