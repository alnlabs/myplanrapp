-- Buying from shop: remove item, restock pantry, mark as fine so auto-sync does not re-add.

create or replace function public.complete_shopping_item(
  p_item_id uuid,
  p_restock boolean default true
)
returns void as $$
declare
  v_item public.shopping_list_items;
  v_pantry public.pantry_items;
  v_pantry_id uuid;
  v_restock_qty numeric;
begin
  select * into v_item
  from public.shopping_list_items
  where id = p_item_id;

  if v_item is null then
    raise exception 'Shopping item not found';
  end if;

  v_pantry_id := v_item.pantry_item_id;

  if v_pantry_id is null then
    select id into v_pantry_id
    from public.pantry_items
    where household_id = v_item.household_id
      and lower(name) = lower(v_item.name)
    limit 1;
  end if;

  if v_pantry_id is not null then
    select * into v_pantry from public.pantry_items where id = v_pantry_id;

    if p_restock then
      v_restock_qty := v_item.quantity;

      if coalesce(v_restock_qty, 0) <= 0 and v_pantry.low_stock_threshold is not null then
        v_restock_qty := greatest(
          (
            v_pantry.low_stock_threshold
            * public.pantry_base_factor(coalesce(v_pantry.low_stock_unit, v_pantry.unit))
            - v_pantry.quantity * public.pantry_base_factor(v_pantry.unit)
          ) / public.pantry_base_factor(v_pantry.unit),
          1
        );
      elsif coalesce(v_restock_qty, 0) <= 0 then
        v_restock_qty := 1;
      end if;

      if v_restock_qty > 0 then
        perform public.apply_stock_event(
          v_pantry_id,
          v_restock_qty,
          'restocked',
          'Bought from shop list'
        );
      end if;
    end if;

    update public.pantry_items
    set availability_status = 'fine'
    where id = v_pantry_id;
  end if;

  delete from public.shopping_list_items
  where id = p_item_id;
end;
$$ language plpgsql security definer;
