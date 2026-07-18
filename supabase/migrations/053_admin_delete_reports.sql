-- Allow admins to delete feedback and error reports from the in-app admin view.
-- Reads were granted in 052; this adds delete so admins can triage/clear items
-- (individually, by day, or all at once).

-- Admins may delete any error report.
drop policy if exists "Admins can delete error reports" on public.error_reports;
create policy "Admins can delete error reports"
  on public.error_reports for delete
  using (public.is_admin());

-- Admins may delete any feedback entry.
drop policy if exists "Admins can delete feedback" on public.feedback;
create policy "Admins can delete feedback"
  on public.feedback for delete
  using (public.is_admin());
