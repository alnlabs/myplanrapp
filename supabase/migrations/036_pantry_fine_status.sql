-- Allow explicit "fine" availability to suppress auto low-stock alerts.

alter table public.pantry_items
  drop constraint if exists pantry_items_availability_status_check;

alter table public.pantry_items
  add constraint pantry_items_availability_status_check
  check (
    availability_status is null
    or availability_status in ('fine', 'warning', 'required', 'emergency')
  );

create or replace function public.check_low_stock(p_household_id uuid)
returns setof public.pantry_items as $$
  select *
  from public.pantry_items pi
  where pi.household_id = p_household_id
    and (
      pi.availability_status in ('warning', 'required', 'emergency')
      or (
        pi.availability_status is null
        and (
          pi.quantity <= 0
          or (
            pi.low_stock_threshold is not null
            and (pi.quantity * public.pantry_base_factor(pi.unit))
                <= (pi.low_stock_threshold
                    * public.pantry_base_factor(coalesce(pi.low_stock_unit, pi.unit)))
          )
        )
      )
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
