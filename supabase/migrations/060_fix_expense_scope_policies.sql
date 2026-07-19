-- Repair for 059_expense_scope.sql.
--
-- 059 assumed the expenses SELECT/ALL policies were still named
-- "Members can view/manage expenses" (from 004_expenses.sql). They were
-- actually replaced by 015_creator_rls.sql with granular View/Insert/Update/
-- Delete policies. As a result 059:
--   * left the permissive "View expenses" policy in place (no scope filter),
--     so personal rows stayed visible to the whole household, and
--   * added a permissive "Members can manage expenses" FOR ALL policy that
--     let any member update/delete household expenses.
--
-- This migration removes the bad policies and makes the real SELECT policy
-- scope-aware. Insert/Update/Delete keep their creator/owner rules from 015.
-- Written idempotently so it is safe on fresh databases too.

drop policy if exists "Members can view expenses" on public.expenses;
drop policy if exists "Members can manage expenses" on public.expenses;

drop policy if exists "View expenses" on public.expenses;
create policy "View expenses"
  on public.expenses for select
  using (
    public.can_access_module(household_id, 'expenses')
    and (scope = 'household' or created_by = auth.uid())
  );
