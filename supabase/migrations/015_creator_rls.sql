-- Refactor RLS: module gating on SELECT, creator-owned edit/delete on core tables.
-- Communal exceptions: pantry stock (apply_stock_event is SECURITY DEFINER),
-- shopping check/uncheck (any member may UPDATE).

-- ============ pantry_items ============
drop policy if exists "Members can view pantry items" on public.pantry_items;
drop policy if exists "Members can manage pantry items" on public.pantry_items;

create policy "View pantry items"
  on public.pantry_items for select
  using (public.can_access_module(household_id, 'pantry'));

create policy "Insert pantry items"
  on public.pantry_items for insert
  with check (
    public.can_access_module(household_id, 'pantry')
    and created_by = auth.uid()
  );

create policy "Update pantry items"
  on public.pantry_items for update
  using (
    public.can_access_module(household_id, 'pantry')
    and (created_by = auth.uid() or public.is_household_owner(household_id))
  );

create policy "Delete pantry items"
  on public.pantry_items for delete
  using (
    created_by = auth.uid() or public.is_household_owner(household_id)
  );

-- ============ recipes ============
drop policy if exists "Members can view recipes" on public.recipes;
drop policy if exists "Members can manage recipes" on public.recipes;

create policy "View recipes"
  on public.recipes for select
  using (public.can_access_module(household_id, 'recipes'));

create policy "Insert recipes"
  on public.recipes for insert
  with check (
    public.can_access_module(household_id, 'recipes')
    and created_by = auth.uid()
  );

create policy "Update recipes"
  on public.recipes for update
  using (
    created_by = auth.uid() or public.is_household_owner(household_id)
  );

create policy "Delete recipes"
  on public.recipes for delete
  using (
    created_by = auth.uid() or public.is_household_owner(household_id)
  );

-- ============ expenses ============
drop policy if exists "Members can view expenses" on public.expenses;
drop policy if exists "Members can manage expenses" on public.expenses;

create policy "View expenses"
  on public.expenses for select
  using (public.can_access_module(household_id, 'expenses'));

create policy "Insert expenses"
  on public.expenses for insert
  with check (
    public.can_access_module(household_id, 'expenses')
    and created_by = auth.uid()
  );

create policy "Update expenses"
  on public.expenses for update
  using (
    created_by = auth.uid() or public.is_household_owner(household_id)
  );

create policy "Delete expenses"
  on public.expenses for delete
  using (
    created_by = auth.uid() or public.is_household_owner(household_id)
  );

-- ============ shopping_list_items ============
-- Communal: any member with access can check/uncheck (UPDATE). Delete = creator/owner.
drop policy if exists "Members can view shopping list" on public.shopping_list_items;
drop policy if exists "Members can manage shopping list" on public.shopping_list_items;

create policy "View shopping list"
  on public.shopping_list_items for select
  using (public.can_access_module(household_id, 'shopping'));

create policy "Insert shopping list"
  on public.shopping_list_items for insert
  with check (
    public.can_access_module(household_id, 'shopping')
    and created_by = auth.uid()
  );

create policy "Update shopping list"
  on public.shopping_list_items for update
  using (public.can_access_module(household_id, 'shopping'));

create policy "Delete shopping list"
  on public.shopping_list_items for delete
  using (
    created_by = auth.uid() or public.is_household_owner(household_id)
  );

-- ============ home_assets ============
drop policy if exists "Members can view home assets" on public.home_assets;
drop policy if exists "Members can manage home assets" on public.home_assets;

create policy "View home assets"
  on public.home_assets for select
  using (public.can_access_module(household_id, 'assets'));

create policy "Insert home assets"
  on public.home_assets for insert
  with check (
    public.can_access_module(household_id, 'assets')
    and created_by = auth.uid()
  );

create policy "Update home assets"
  on public.home_assets for update
  using (
    created_by = auth.uid() or public.is_household_owner(household_id)
  );

create policy "Delete home assets"
  on public.home_assets for delete
  using (
    created_by = auth.uid() or public.is_household_owner(household_id)
  );

-- ============ asset_service_records ============
drop policy if exists "Members can view service records" on public.asset_service_records;
drop policy if exists "Members can manage service records" on public.asset_service_records;

create policy "View service records"
  on public.asset_service_records for select
  using (public.can_access_module(household_id, 'assets'));

create policy "Insert service records"
  on public.asset_service_records for insert
  with check (
    public.can_access_module(household_id, 'assets')
    and created_by = auth.uid()
  );

create policy "Update service records"
  on public.asset_service_records for update
  using (
    created_by = auth.uid() or public.is_household_owner(household_id)
  );

create policy "Delete service records"
  on public.asset_service_records for delete
  using (
    created_by = auth.uid() or public.is_household_owner(household_id)
  );
