-- Allow low-stock threshold to use a different unit than the item quantity.
-- e.g. quantity in kg, alert at 200 g.

alter table public.pantry_items
  add column if not exists low_stock_unit text;

-- Convert a quantity to a comparable base value within its unit family
-- (mass -> grams, volume -> ml, count -> as-is).
create or replace function public.pantry_base_factor(p_unit text)
returns numeric
language sql
immutable
as $$
  select case p_unit
    when 'kg' then 1000
    when 'g' then 1
    when 'L' then 1000
    when 'ml' then 1
    else 1
  end;
$$;

create or replace function public.check_low_stock(p_household_id uuid)
returns setof public.pantry_items as $$
  select *
  from public.pantry_items pi
  where pi.household_id = p_household_id
    and pi.low_stock_threshold is not null
    and (pi.quantity * public.pantry_base_factor(pi.unit))
        <= (pi.low_stock_threshold
            * public.pantry_base_factor(coalesce(pi.low_stock_unit, pi.unit)))
  order by pi.name;
$$ language sql security definer stable;

-- Shopping list deficit is expressed in the item's own unit.
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
      v_deficit,
      r.unit,
      'low_stock',
      r.id,
      auth.uid()
    where not exists (
      select 1 from public.shopping_list_items s
      where s.household_id = p_household_id
        and s.is_checked = false
        and lower(s.name) = lower(r.name)
    );
    if found then v_count := v_count + 1; end if;
  end loop;
  return v_count;
end;
$$ language plpgsql security definer;
