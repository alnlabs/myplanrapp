-- Avatar storage, extended member details, medicine schedules support, delete account

-- 1. Extend upsert_member_details for avatar, clothing sizes, visibility.
create or replace function public.upsert_member_details(
  p_family_member_id uuid,
  p_details jsonb
)
returns void as $$
declare
  v_household_id uuid;
  v_user_id uuid;
  v_created_by uuid;
begin
  select household_id, user_id, created_by
  into v_household_id, v_user_id, v_created_by
  from public.household_family_members
  where id = p_family_member_id;

  if not found then
    raise exception 'Family member not found';
  end if;

  if not (
    public.is_household_manager(v_household_id)
    or v_user_id = auth.uid()
    or (v_created_by = auth.uid() and v_user_id is null)
  ) then
    raise exception 'Not allowed to edit this member card';
  end if;

  insert into public.household_member_details (
    family_member_id, household_id, user_id,
    phone, alt_phone, date_of_birth, blood_group, allergies, medicines,
    doctor_name, doctor_phone, dietary_preference, food_allergies,
    work_place, school_name,
    emergency_contact_name, emergency_contact_phone, emergency_contact_relation,
    notes, avatar_url, clothing_sizes, visibility
  ) values (
    p_family_member_id, v_household_id, v_user_id,
    p_details->>'phone', p_details->>'alt_phone',
    nullif(p_details->>'date_of_birth', '')::date,
    p_details->>'blood_group', p_details->>'allergies', p_details->>'medicines',
    p_details->>'doctor_name', p_details->>'doctor_phone',
    p_details->>'dietary_preference', p_details->>'food_allergies',
    p_details->>'work_place', p_details->>'school_name',
    p_details->>'emergency_contact_name', p_details->>'emergency_contact_phone',
    p_details->>'emergency_contact_relation',
    p_details->>'notes',
    nullif(p_details->>'avatar_url', ''),
    coalesce(p_details->'clothing_sizes', '{}'::jsonb),
    coalesce(p_details->'visibility', '{}'::jsonb)
  )
  on conflict (family_member_id) do update set
    phone = excluded.phone,
    alt_phone = excluded.alt_phone,
    date_of_birth = excluded.date_of_birth,
    blood_group = excluded.blood_group,
    allergies = excluded.allergies,
    medicines = excluded.medicines,
    doctor_name = excluded.doctor_name,
    doctor_phone = excluded.doctor_phone,
    dietary_preference = excluded.dietary_preference,
    food_allergies = excluded.food_allergies,
    work_place = excluded.work_place,
    school_name = excluded.school_name,
    emergency_contact_name = excluded.emergency_contact_name,
    emergency_contact_phone = excluded.emergency_contact_phone,
    emergency_contact_relation = excluded.emergency_contact_relation,
    notes = excluded.notes,
    avatar_url = excluded.avatar_url,
    clothing_sizes = excluded.clothing_sizes,
    visibility = excluded.visibility,
    updated_at = now();
end;
$$ language plpgsql security definer;

-- 2. Avatar storage bucket (private; signed URLs in app).
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'household-avatars',
  'household-avatars',
  false,
  2097152,
  array['image/jpeg', 'image/png', 'image/webp', 'image/heic']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy "Household members can read avatar files"
  on storage.objects for select
  using (
    bucket_id = 'household-avatars'
    and public.is_household_member((storage.foldername(name))[1]::uuid)
  );

create policy "Managers can upload avatar files"
  on storage.objects for insert
  with check (
    bucket_id = 'household-avatars'
    and auth.uid() is not null
    and public.is_household_manager((storage.foldername(name))[1]::uuid)
  );

create policy "Managers and linked users can update avatar files"
  on storage.objects for update
  using (
    bucket_id = 'household-avatars'
    and public.is_household_member((storage.foldername(name))[1]::uuid)
    and (
      public.is_household_manager((storage.foldername(name))[1]::uuid)
      or owner = auth.uid()
    )
  );

create policy "Managers can delete avatar files"
  on storage.objects for delete
  using (
    bucket_id = 'household-avatars'
    and public.is_household_manager((storage.foldername(name))[1]::uuid)
  );

-- 3. Medicine schedule policies: all members view; managers/caregivers edit.
drop policy if exists "Members can manage medicine schedules" on public.member_medicine_schedules;
drop policy if exists "Managers can manage medicine schedules" on public.member_medicine_schedules;
drop policy if exists "Managers and caregivers can manage medicine schedules" on public.member_medicine_schedules;

create policy "Managers and caregivers can insert medicine schedules"
  on public.member_medicine_schedules for insert
  with check (
    public.is_household_manager(household_id)
    or exists (
      select 1 from public.household_family_members fm
      where fm.id = member_medicine_schedules.family_member_id
        and (
          fm.user_id = auth.uid()
          or (fm.created_by = auth.uid() and fm.user_id is null)
        )
    )
  );

create policy "Managers and caregivers can update medicine schedules"
  on public.member_medicine_schedules for update
  using (
    public.is_household_manager(household_id)
    or exists (
      select 1 from public.household_family_members fm
      where fm.id = member_medicine_schedules.family_member_id
        and (
          fm.user_id = auth.uid()
          or (fm.created_by = auth.uid() and fm.user_id is null)
        )
    )
  );

create policy "Managers and caregivers can delete medicine schedules"
  on public.member_medicine_schedules for delete
  using (
    public.is_household_manager(household_id)
    or exists (
      select 1 from public.household_family_members fm
      where fm.id = member_medicine_schedules.family_member_id
        and (
          fm.user_id = auth.uid()
          or (fm.created_by = auth.uid() and fm.user_id is null)
        )
    )
  );

-- 4. Delete own account (cascades via FK; removes auth user).
create or replace function public.delete_own_account()
returns void as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  delete from auth.users where id = auth.uid();
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function public.delete_own_account() to authenticated;
