-- Optional brand for pantry items (e.g. Sugar + Madhur).

alter table public.pantry_items
  add column if not exists brand text;
