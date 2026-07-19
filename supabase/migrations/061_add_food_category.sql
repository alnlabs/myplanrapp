-- Add a default (household-agnostic) "Food" expense category.
-- Idempotent: only inserts when it does not already exist as a default.

insert into public.expense_categories (household_id, name, sort_order, category_kind)
select null, 'Food', 1, 'expense'
where not exists (
  select 1 from public.expense_categories ec
  where ec.household_id is null
    and ec.name = 'Food'
    and ec.category_kind = 'expense'
);
