-- Medicine schedules: purpose (what it's for) required; brand/formula name optional.

alter table public.member_medicine_schedules
  add column if not exists medicine_for text;

-- Backfill purpose from the legacy name column before relaxing medicine_name.
update public.member_medicine_schedules
set medicine_for = medicine_name
where medicine_for is null or trim(medicine_for) = '';

alter table public.member_medicine_schedules
  alter column medicine_name drop not null;

-- Legacy rows only had a single name field; drop the duplicate brand copy.
update public.member_medicine_schedules
set medicine_name = null
where medicine_name is not null
  and trim(medicine_name) = trim(medicine_for);

alter table public.member_medicine_schedules
  alter column medicine_for set not null;
