-- Enforce member profile visibility server-side for household viewers.

create or replace function public.get_member_details_for_viewer(p_family_member_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_fm public.household_family_members%rowtype;
  v_row public.household_member_details%rowtype;
  v_full_access boolean;
  v_vis jsonb;
  v_result jsonb;
begin
  select * into v_fm
  from public.household_family_members
  where id = p_family_member_id;

  if not found then
    raise exception 'Family member not found';
  end if;

  if not public.is_household_member(v_fm.household_id) then
    raise exception 'Not allowed';
  end if;

  select * into v_row
  from public.household_member_details
  where family_member_id = p_family_member_id;

  v_full_access :=
    public.is_household_manager(v_fm.household_id)
    or v_fm.user_id = auth.uid()
    or (v_fm.created_by = auth.uid() and v_fm.user_id is null);

  if not found then
    return jsonb_build_object(
      'family_member_id', p_family_member_id,
      'household_id', v_fm.household_id,
      'user_id', v_fm.user_id,
      'visibility', '{}'::jsonb,
      'clothing_sizes', '{}'::jsonb
    );
  end if;

  v_result := jsonb_build_object(
    'family_member_id', v_row.family_member_id,
    'household_id', v_row.household_id,
    'user_id', v_row.user_id,
    'phone', v_row.phone,
    'alt_phone', v_row.alt_phone,
    'date_of_birth', v_row.date_of_birth,
    'blood_group', v_row.blood_group,
    'allergies', v_row.allergies,
    'medicines', v_row.medicines,
    'doctor_name', v_row.doctor_name,
    'doctor_phone', v_row.doctor_phone,
    'dietary_preference', v_row.dietary_preference,
    'food_allergies', v_row.food_allergies,
    'work_place', v_row.work_place,
    'school_name', v_row.school_name,
    'emergency_contact_name', v_row.emergency_contact_name,
    'emergency_contact_phone', v_row.emergency_contact_phone,
    'emergency_contact_relation', v_row.emergency_contact_relation,
    'notes', v_row.notes,
    'avatar_url', v_row.avatar_url,
    'clothing_sizes', coalesce(v_row.clothing_sizes, '{}'::jsonb),
    'visibility', coalesce(v_row.visibility, '{}'::jsonb)
  );

  if v_full_access then
    return v_result;
  end if;

  v_vis := coalesce(v_row.visibility, '{}'::jsonb);

  if not coalesce((v_vis->>'phone')::boolean, true) then
    v_result := v_result || jsonb_build_object('phone', null, 'alt_phone', null);
  end if;

  if not coalesce((v_vis->>'health')::boolean, true) then
    v_result := v_result || jsonb_build_object(
      'blood_group', null,
      'allergies', null,
      'medicines', null,
      'doctor_name', null,
      'doctor_phone', null,
      'dietary_preference', null,
      'food_allergies', null
    );
  end if;

  if not coalesce((v_vis->>'emergency')::boolean, true) then
    v_result := v_result || jsonb_build_object(
      'emergency_contact_name', null,
      'emergency_contact_phone', null,
      'emergency_contact_relation', null,
      'notes', null
    );
  end if;

  return v_result;
end;
$$;

grant execute on function public.get_member_details_for_viewer(uuid) to authenticated;

create or replace function public.get_medicine_schedules_for_viewer(p_family_member_id uuid)
returns setof public.member_medicine_schedules
language plpgsql
security definer
set search_path = public
as $$
declare
  v_fm public.household_family_members%rowtype;
  v_row public.household_member_details%rowtype;
  v_full_access boolean;
  v_vis jsonb;
begin
  select * into v_fm
  from public.household_family_members
  where id = p_family_member_id;

  if not found then
    raise exception 'Family member not found';
  end if;

  if not public.is_household_member(v_fm.household_id) then
    raise exception 'Not allowed';
  end if;

  select * into v_row
  from public.household_member_details
  where family_member_id = p_family_member_id;

  v_full_access :=
    public.is_household_manager(v_fm.household_id)
    or v_fm.user_id = auth.uid()
    or (v_fm.created_by = auth.uid() and v_fm.user_id is null);

  v_vis := coalesce(v_row.visibility, '{}'::jsonb);

  if v_full_access or coalesce((v_vis->>'health')::boolean, true) then
    return query
    select *
    from public.member_medicine_schedules
    where family_member_id = p_family_member_id
    order by created_at;
  end if;

  return;
end;
$$;

grant execute on function public.get_medicine_schedules_for_viewer(uuid) to authenticated;
