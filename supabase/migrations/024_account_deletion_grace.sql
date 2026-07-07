-- Soft account deletion with a 30-day grace period.
-- Users can sign in again within 30 days to restore their account.

alter table public.profiles
  add column if not exists deleted_at timestamptz;

create or replace function public.request_account_deletion()
returns timestamptz
language plpgsql
security definer
set search_path = public
as $$
declare
  v_deleted_at timestamptz := now();
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  update public.profiles
  set deleted_at = v_deleted_at,
      active_household_id = null
  where id = auth.uid();

  return v_deleted_at;
end;
$$;

create or replace function public.restore_own_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  update public.profiles
  set deleted_at = null
  where id = auth.uid()
    and deleted_at is not null
    and deleted_at > now() - interval '30 days';

  if not found then
    raise exception 'This account can no longer be restored';
  end if;
end;
$$;

create or replace function public.finalize_expired_account_deletion()
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_deleted_at timestamptz;
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    return false;
  end if;

  select deleted_at into v_deleted_at
  from public.profiles
  where id = v_uid;

  if v_deleted_at is null then
    return false;
  end if;

  if v_deleted_at + interval '30 days' > now() then
    return false;
  end if;

  delete from auth.users where id = v_uid;
  return true;
end;
$$;

-- Immediate hard delete (used after grace period or admin tooling).
create or replace function public.delete_own_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  delete from auth.users where id = auth.uid();
end;
$$;

grant execute on function public.request_account_deletion() to authenticated;
grant execute on function public.restore_own_account() to authenticated;
grant execute on function public.finalize_expired_account_deletion() to authenticated;
grant execute on function public.delete_own_account() to authenticated;
