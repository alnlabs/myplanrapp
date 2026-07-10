-- Manual pantry availability status (warning / required / emergency).

alter table public.pantry_items
  add column if not exists availability_status text
  check (
    availability_status is null
    or availability_status in ('warning', 'required', 'emergency')
  );

create or replace function public.check_low_stock(p_household_id uuid)
returns setof public.pantry_items as $$
  select *
  from public.pantry_items pi
  where pi.household_id = p_household_id
    and (
      pi.availability_status is not null
      or (
        pi.low_stock_threshold is not null
        and (pi.quantity * public.pantry_base_factor(pi.unit))
            <= (pi.low_stock_threshold
                * public.pantry_base_factor(coalesce(pi.low_stock_unit, pi.unit)))
      )
      or pi.quantity <= 0
    )
  order by
    case pi.availability_status
      when 'emergency' then 1
      when 'required' then 2
      when 'warning' then 3
      else 4
    end,
    pi.name;
$$ language sql security definer stable;

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
    if r.availability_status is not null then
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
          and lower(s.name) = lower(r.name)
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
    end if;

    if found then v_count := v_count + 1; end if;
  end loop;
  return v_count;
end;
$$ language plpgsql security definer;
