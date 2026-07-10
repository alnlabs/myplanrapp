-- Auto shop list: align generate with check_low_stock (attention + threshold + out of stock).

create or replace function public.generate_shopping_list_from_low_stock(p_household_id uuid)
returns int as $$
declare
  v_count int := 0;
  r record;
  v_deficit numeric;
begin
  for r in
    select * from public.check_low_stock(p_household_id)
  loop
    if r.availability_status in ('warning', 'required', 'emergency') then
      insert into public.shopping_list_items (
        household_id, name, quantity, unit, source, pantry_item_id, created_by
      )
      select
        p_household_id,
        r.name,
        null,
        null,
        'low_stock',
        r.id,
        auth.uid()
      where not exists (
        select 1 from public.shopping_list_items s
        where s.household_id = p_household_id
          and s.is_checked = false
          and (
            s.pantry_item_id = r.id
            or lower(s.name) = lower(r.name)
          )
      );
    elsif r.low_stock_threshold is not null then
      v_deficit := greatest(
        (r.low_stock_threshold
          * public.pantry_base_factor(coalesce(r.low_stock_unit, r.unit))
         - r.quantity * public.pantry_base_factor(r.unit))
        / public.pantry_base_factor(r.unit),
        0
      );

      insert into public.shopping_list_items (
        household_id, name, quantity, unit, source, pantry_item_id, created_by
      )
      select
        p_household_id,
        r.name,
        nullif(v_deficit, 0),
        case when v_deficit > 0 then r.unit else null end,
        'low_stock',
        r.id,
        auth.uid()
      where not exists (
        select 1 from public.shopping_list_items s
        where s.household_id = p_household_id
          and s.is_checked = false
          and (
            s.pantry_item_id = r.id
            or lower(s.name) = lower(r.name)
          )
      );
    elsif r.quantity <= 0 then
      insert into public.shopping_list_items (
        household_id, name, quantity, unit, source, pantry_item_id, created_by
      )
      select
        p_household_id,
        r.name,
        null,
        null,
        'low_stock',
        r.id,
        auth.uid()
      where not exists (
        select 1 from public.shopping_list_items s
        where s.household_id = p_household_id
          and s.is_checked = false
          and (
            s.pantry_item_id = r.id
            or lower(s.name) = lower(r.name)
          )
      );
    end if;

    if found then v_count := v_count + 1; end if;
  end loop;
  return v_count;
end;
$$ language plpgsql security definer;
