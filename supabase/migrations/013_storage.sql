-- Asset photo attachments + Supabase Storage bucket

create table public.asset_attachments (
  id uuid primary key default gen_random_uuid(),
  asset_id uuid not null references public.home_assets(id) on delete cascade,
  household_id uuid not null references public.households(id) on delete cascade,
  created_by uuid references public.profiles(id) on delete set null,
  attachment_type text not null default 'other' check (
    attachment_type in ('warranty', 'receipt', 'other')
  ),
  storage_path text not null,
  file_name text not null,
  mime_type text,
  file_size_bytes bigint,
  created_at timestamptz default now() not null
);

create index asset_attachments_asset_idx on public.asset_attachments (asset_id);
create index asset_attachments_household_idx on public.asset_attachments (household_id);

alter table public.asset_attachments enable row level security;

create policy "Members can view asset attachments"
  on public.asset_attachments for select
  using (
    public.is_household_member(household_id)
    and public.can_access_module(household_id, 'assets')
  );

create policy "Members can add asset attachments"
  on public.asset_attachments for insert
  with check (
    public.can_access_module(household_id, 'assets')
    and created_by = auth.uid()
  );

create policy "Creators and owners can delete attachments"
  on public.asset_attachments for delete
  using (
    public.can_access_module(household_id, 'assets')
    and (created_by = auth.uid() or public.is_household_owner(household_id))
  );

-- Storage bucket (private; signed URLs in app)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'household-attachments',
  'household-attachments',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'application/pdf']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy "Household members can read attachment files"
  on storage.objects for select
  using (
    bucket_id = 'household-attachments'
    and public.is_household_member((storage.foldername(name))[1]::uuid)
    and public.can_access_module((storage.foldername(name))[1]::uuid, 'assets')
  );

create policy "Household members can upload attachment files"
  on storage.objects for insert
  with check (
    bucket_id = 'household-attachments'
    and auth.uid() is not null
    and public.is_household_member((storage.foldername(name))[1]::uuid)
    and public.can_access_module((storage.foldername(name))[1]::uuid, 'assets')
  );

create policy "Creators and owners can delete attachment files"
  on storage.objects for delete
  using (
    bucket_id = 'household-attachments'
    and public.is_household_member((storage.foldername(name))[1]::uuid)
    and (
      public.is_household_owner((storage.foldername(name))[1]::uuid)
      or owner = auth.uid()
    )
  );
