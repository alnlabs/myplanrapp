-- Let app users update their own roster row (e.g. display name from Profile).

create policy "Linked users can update own roster entry"
  on public.household_family_members for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
