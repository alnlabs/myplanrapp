-- Sync shop list both ways: remove stale low-stock rows, then add current needs.

create or replace function public.sync_shopping_list_from_pantry(p_household_id uuid)
returns int as $$
declare
  v_added int;
begin
  delete from public.shopping_list_items s
  where s.household_id = p_household_id
    and s.is_checked = false
    and s.source = 'low_stock'
    and (
      (
        s.pantry_item_id is not null
        and not exists (
          select 1
          from public.check_low_stock(p_household_id) ls
          where ls.id = s.pantry_item_id
        )
      )
      or exists (
        select 1
        from public.pantry_items pi
        where pi.household_id = p_household_id
          and lower(pi.name) = lower(s.name)
          and not exists (
            select 1
            from public.check_low_stock(p_household_id) ls
            where ls.id = pi.id
          )
      )
    );

  v_added := public.generate_shopping_list_from_low_stock(p_household_id);
  return v_added;
end;
$$ language plpgsql security definer;
