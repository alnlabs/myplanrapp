-- Owner-only reset of a household's transactional data.
--
-- Clears content data (money, pantry, shopping, assets, subscriptions,
-- reminders, plans, recipes, receipts) for the given features. Never touches
-- login accounts, memberships, the family roster, or household settings.
--
-- Security: only the household OWNER may run this (enforced here, independent
-- of RLS since this is SECURITY DEFINER). Returns a jsonb map of
-- {feature: rows_deleted}.

create or replace function public.reset_household_data(
  p_household_id uuid,
  p_features text[]
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_feature text;
  v_counts jsonb := '{}'::jsonb;
  v_n bigint;
begin
  if not public.is_household_owner(p_household_id) then
    raise exception 'Only the family owner can reset data';
  end if;

  if p_features is null or array_length(p_features, 1) is null then
    return v_counts;
  end if;

  foreach v_feature in array p_features loop
    v_n := 0;

    if v_feature = 'money' then
      delete from public.expenses where household_id = p_household_id;
      get diagnostics v_n = row_count;
      delete from public.recurring_money_rules where household_id = p_household_id;
      delete from public.expense_groups where household_id = p_household_id;

    elsif v_feature = 'pantry' then
      -- stock_events cascade via pantry_items.item_id
      delete from public.pantry_items where household_id = p_household_id;
      get diagnostics v_n = row_count;

    elsif v_feature = 'shopping' then
      delete from public.shopping_list_items where household_id = p_household_id;
      get diagnostics v_n = row_count;

    elsif v_feature = 'assets' then
      -- service records + attachments cascade via home_assets
      delete from public.home_assets where household_id = p_household_id;
      get diagnostics v_n = row_count;

    elsif v_feature = 'subscriptions' then
      delete from public.subscriptions where household_id = p_household_id;
      get diagnostics v_n = row_count;

    elsif v_feature = 'reminders' then
      delete from public.reminders where household_id = p_household_id;
      get diagnostics v_n = row_count;

    elsif v_feature = 'plans' then
      delete from public.plans where household_id = p_household_id;
      get diagnostics v_n = row_count;

    elsif v_feature = 'recipes' then
      -- recipe_ingredients cascade via recipes
      delete from public.recipes where household_id = p_household_id;
      get diagnostics v_n = row_count;

    elsif v_feature = 'receipts' then
      -- receipt_line_items cascade via receipts
      delete from public.receipts where household_id = p_household_id;
      get diagnostics v_n = row_count;

    else
      raise exception 'Unknown reset feature: %', v_feature;
    end if;

    v_counts := v_counts || jsonb_build_object(v_feature, v_n);
  end loop;

  return v_counts;
end;
$$;

grant execute on function public.reset_household_data(uuid, text[]) to authenticated;
