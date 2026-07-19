-- Guests added to an expense group by email were stored as invite_status
-- 'pending', which hid them from the paid-by / split participant lists and made
-- the split validation reject them. Expense-group guests are just tracked
-- participants (not app users who accept an invite), so activate existing ones.
-- Household-invitee rows (which carry a user_id or family_member_id) are left
-- untouched.

update public.expense_group_members
set invite_status = 'active'
where invite_status = 'pending'
  and user_id is null
  and family_member_id is null;
