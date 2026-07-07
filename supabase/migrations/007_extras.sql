-- Expiry dates, cook & deduct, shopping complete with restock

alter table public.pantry_items
  add column if not exists expiry_date date;

create or replace function public.check_expiring_soon(p_household_id uuid, p_days int default 3)
returns setof public.pantry_items as $$
  select *
  from public.pantry_items
  where household_id = p_household_id
    and expiry_date is not null
    and expiry_date <= current_date + p_days
  order by expiry_date;
$$ language sql security definer stable;

create or replace function public.cook_and_deduct_recipe(p_recipe_id uuid)
returns table (
  ingredient_name text,
  deducted numeric,
  status text
) as $$
declare
  v_household_id uuid;
  r record;
  v_item_id uuid;
begin
  select household_id into v_household_id
  from public.recipes where id = p_recipe_id;

  for r in
    select * from public.check_recipe_availability(p_recipe_id, v_household_id)
    where status = 'sufficient' and pantry_item_id is not null
  loop
    perform public.apply_stock_event(
      r.pantry_item_id,
      -r.required_quantity,
      'used',
      'Cooked recipe'
    );
    ingredient_name := r.ingredient_name;
    deducted := r.required_quantity;
    status := 'deducted';
    return next;
  end loop;
end;
$$ language plpgsql security definer;

create or replace function public.complete_shopping_item(
  p_item_id uuid,
  p_restock boolean default true
)
returns void as $$
declare
  v_item public.shopping_list_items;
  v_pantry_id uuid;
begin
  select * into v_item
  from public.shopping_list_items
  where id = p_item_id;

  if v_item is null then
    raise exception 'Shopping item not found';
  end if;

  update public.shopping_list_items
  set is_checked = true
  where id = p_item_id;

  if not p_restock then
    return;
  end if;

  v_pantry_id := v_item.pantry_item_id;

  if v_pantry_id is null then
    select id into v_pantry_id
    from public.pantry_items
    where household_id = v_item.household_id
      and lower(name) = lower(v_item.name)
    limit 1;
  end if;

  if v_pantry_id is not null and coalesce(v_item.quantity, 0) > 0 then
    perform public.apply_stock_event(
      v_pantry_id,
      v_item.quantity,
      'restocked',
      'Bought from shop list'
    );
  end if;
end;
$$ language plpgsql security definer;
