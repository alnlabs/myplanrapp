-- Recipes

create table public.recipes (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  name text not null,
  servings int not null default 4 check (servings > 0),
  instructions text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

create table public.recipe_ingredients (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid not null references public.recipes(id) on delete cascade,
  name text not null,
  quantity numeric not null check (quantity > 0),
  unit text not null default 'g',
  pantry_item_id uuid references public.pantry_items(id) on delete set null,
  sort_order int default 0
);

alter table public.recipes enable row level security;
alter table public.recipe_ingredients enable row level security;

create policy "Members can view recipes"
  on public.recipes for select
  using (public.is_household_member(household_id));

create policy "Members can manage recipes"
  on public.recipes for all
  using (public.is_household_member(household_id));

create policy "Members can view recipe ingredients"
  on public.recipe_ingredients for select
  using (
    exists (
      select 1 from public.recipes r
      where r.id = recipe_ingredients.recipe_id
        and public.is_household_member(r.household_id)
    )
  );

create policy "Members can manage recipe ingredients"
  on public.recipe_ingredients for all
  using (
    exists (
      select 1 from public.recipes r
      where r.id = recipe_ingredients.recipe_id
        and public.is_household_member(r.household_id)
    )
  );

create trigger recipes_updated_at
  before update on public.recipes
  for each row execute function public.handle_updated_at();

create or replace function public.check_recipe_availability(
  p_recipe_id uuid,
  p_household_id uuid
)
returns table (
  ingredient_id uuid,
  ingredient_name text,
  required_quantity numeric,
  unit text,
  available_quantity numeric,
  status text,
  gap numeric,
  pantry_item_id uuid
) as $$
begin
  return query
  select
    ri.id,
    ri.name,
    ri.quantity,
    ri.unit,
    coalesce(pi.quantity, 0),
    case
      when pi.id is null or pi.quantity <= 0 then 'missing'
      when pi.quantity < ri.quantity then 'insufficient'
      else 'sufficient'
    end,
    case
      when pi.id is null or pi.quantity <= 0 then ri.quantity
      when pi.quantity < ri.quantity then ri.quantity - pi.quantity
      else 0
    end,
    pi.id
  from public.recipe_ingredients ri
  left join public.pantry_items pi on (
    (ri.pantry_item_id is not null and pi.id = ri.pantry_item_id)
    or (ri.pantry_item_id is null and lower(pi.name) = lower(ri.name) and pi.household_id = p_household_id)
  )
  where ri.recipe_id = p_recipe_id
  order by ri.sort_order, ri.name;
end;
$$ language plpgsql security definer stable;
