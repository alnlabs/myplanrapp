-- Home assets: durable items, warranty, repair history

create table public.home_assets (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  created_by uuid references public.profiles(id) on delete set null,
  name text not null,
  description text,
  category text not null default 'other' check (
    category in ('electronics', 'appliance', 'furniture', 'cable', 'other')
  ),
  item_kind text not null default 'permanent' check (
    item_kind in ('permanent', 'temporary', 'borrowed')
  ),
  status text not null default 'active' check (
    status in ('active', 'under_repair', 'borrowed_out', 'disposed')
  ),
  location text,
  acquisition_type text check (
    acquisition_type is null
    or acquisition_type in ('shop', 'online', 'borrowed', 'gift')
  ),
  purchase_date date,
  purchase_amount numeric,
  vendor_name text,
  vendor_url text,
  order_reference text,
  warranty_start date,
  warranty_end date,
  warranty_provider text,
  warranty_notes text,
  expiry_date date,
  used_by_member_id uuid references public.household_family_members(id) on delete set null,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

create table public.asset_service_records (
  id uuid primary key default gen_random_uuid(),
  asset_id uuid not null references public.home_assets(id) on delete cascade,
  household_id uuid not null references public.households(id) on delete cascade,
  created_by uuid references public.profiles(id) on delete set null,
  service_type text not null check (
    service_type in ('shop_repair', 'third_party', 'diy')
  ),
  service_date date not null default current_date,
  shop_name text,
  shop_address text,
  shop_phone text,
  platform_name text,
  agent_name text,
  booking_ref text,
  cost numeric,
  notes text,
  created_at timestamptz default now() not null
);

create index home_assets_household_idx on public.home_assets (household_id);
create index home_assets_warranty_end_idx on public.home_assets (warranty_end)
  where warranty_end is not null;

alter table public.home_assets enable row level security;
alter table public.asset_service_records enable row level security;

create trigger home_assets_updated_at
  before update on public.home_assets
  for each row execute function public.handle_updated_at();

create policy "Members can view home assets"
  on public.home_assets for select
  using (public.is_household_member(household_id));

create policy "Members can manage home assets"
  on public.home_assets for all
  using (public.is_household_member(household_id));

create policy "Members can view service records"
  on public.asset_service_records for select
  using (public.is_household_member(household_id));

create policy "Members can manage service records"
  on public.asset_service_records for all
  using (public.is_household_member(household_id));
