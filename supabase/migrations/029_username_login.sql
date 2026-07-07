-- Username support: allow signing in with a username instead of email.

alter table public.profiles
  add column if not exists username text;

create unique index if not exists profiles_username_lower_key
  on public.profiles (lower(username))
  where username is not null;

-- Populate display_name and username from sign-up metadata.
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, display_name, username)
  values (
    new.id,
    coalesce(
      nullif(new.raw_user_meta_data->>'display_name', ''),
      split_part(new.email, '@', 1)
    ),
    nullif(new.raw_user_meta_data->>'username', '')
  );
  return new;
end;
$$ language plpgsql security definer;

-- Resolve a username to its account email for password sign-in.
create or replace function public.email_for_username(p_username text)
returns text as $$
  select u.email
  from public.profiles p
  join auth.users u on u.id = p.id
  where lower(p.username) = lower(trim(p_username))
  limit 1;
$$ language sql security definer;

grant execute on function public.email_for_username(text) to anon, authenticated;
