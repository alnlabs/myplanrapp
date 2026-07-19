-- Receipt scanning: persisted receipts + their detected line items.
--
-- Two-layer deduplication:
--   1) Receipt-level idempotency: a unique (household_id, fingerprint) index
--      stops the same physical receipt from being processed twice.
--   2) Line-level apply tracking: receipt_line_items records what was applied
--      (and to which record) so re-applying is a no-op.
-- Actual expense/pantry/shopping writes reuse existing tables/RPCs; these tables
-- only track the receipt and its mapping decisions.

create table if not exists public.receipts (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  created_by uuid references public.profiles(id) on delete set null,
  fingerprint text not null,
  merchant text,
  purchased_at date,
  total numeric,
  currency text,
  image_path text,
  status text not null default 'pending'
    check (status in ('pending', 'processed')),
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null,
  unique (household_id, fingerprint)
);

create table if not exists public.receipt_line_items (
  id uuid primary key default gen_random_uuid(),
  receipt_id uuid not null references public.receipts(id) on delete cascade,
  line_index int not null,
  raw_text text,
  name text,
  qty numeric,
  unit text,
  destination text,
  action text,
  matched_item_id uuid references public.pantry_items(id) on delete set null,
  applied_at timestamptz,
  applied_ref uuid,
  created_at timestamptz default now() not null,
  unique (receipt_id, line_index)
);

create index if not exists receipts_household_idx
  on public.receipts(household_id);
create index if not exists receipt_line_items_receipt_idx
  on public.receipt_line_items(receipt_id);

alter table public.receipts enable row level security;
alter table public.receipt_line_items enable row level security;

-- Receipts are scoped to household membership.
drop policy if exists "Members can view receipts" on public.receipts;
create policy "Members can view receipts"
  on public.receipts for select
  using (public.is_household_member(household_id));

drop policy if exists "Members can manage receipts" on public.receipts;
create policy "Members can manage receipts"
  on public.receipts for all
  using (public.is_household_member(household_id))
  with check (public.is_household_member(household_id));

-- Line items inherit access from their parent receipt's household (child-table
-- pattern mirroring stock_events in 003_pantry.sql).
drop policy if exists "Members can view receipt lines" on public.receipt_line_items;
create policy "Members can view receipt lines"
  on public.receipt_line_items for select
  using (
    exists (
      select 1 from public.receipts r
      where r.id = receipt_line_items.receipt_id
        and public.is_household_member(r.household_id)
    )
  );

drop policy if exists "Members can manage receipt lines" on public.receipt_line_items;
create policy "Members can manage receipt lines"
  on public.receipt_line_items for all
  using (
    exists (
      select 1 from public.receipts r
      where r.id = receipt_line_items.receipt_id
        and public.is_household_member(r.household_id)
    )
  )
  with check (
    exists (
      select 1 from public.receipts r
      where r.id = receipt_line_items.receipt_id
        and public.is_household_member(r.household_id)
    )
  );

create trigger receipts_updated_at
  before update on public.receipts
  for each row execute function public.handle_updated_at();
