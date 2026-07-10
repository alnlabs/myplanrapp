-- =============================================================================
-- Remove the "The Sharma Family" demo data.
-- Deleting the auth users cascades the household and every related row.
-- =============================================================================

delete from auth.users
where id in (
  'aaaaaaaa-0000-4000-8000-000000000001', -- priya (owner)
  'aaaaaaaa-0000-4000-8000-000000000002', -- arjun
  'aaaaaaaa-0000-4000-8000-000000000003'  -- kavya
);
