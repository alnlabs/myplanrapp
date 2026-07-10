-- Bought shop items are removed from the list (not moved to a bought section).
-- Clear manual pantry attention when the linked item is bought.

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

  v_pantry_id := v_item.pantry_item_id;

  if v_pantry_id is null then
    select id into v_pantry_id
    from public.pantry_items
    where household_id = v_item.household_id
      and lower(name) = lower(v_item.name)
    limit 1;
  end if;

  if v_pantry_id is not null then
    if p_restock and coalesce(v_item.quantity, 0) > 0 then
      perform public.apply_stock_event(
        v_pantry_id,
        v_item.quantity,
        'restocked',
        'Bought from shop list'
      );
    end if;

    update public.pantry_items
    set availability_status = null
    where id = v_pantry_id
      and availability_status in ('warning', 'required', 'emergency');
  end if;

  delete from public.shopping_list_items
  where id = p_item_id;
end;
$$ language plpgsql security definer;
