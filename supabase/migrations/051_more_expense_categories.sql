-- Add more default (household-agnostic) expense categories.
-- Idempotent: only inserts categories that don't already exist as defaults.

insert into public.expense_categories (household_id, name, sort_order, category_kind)
select null, v.name, v.sort_order, 'expense'
from (values
  ('Dining out', 8),
  ('Fuel', 9),
  ('Education', 10),
  ('Childcare', 11),
  ('Health & Fitness', 12),
  ('Personal care', 13),
  ('Clothing', 14),
  ('Household supplies', 15),
  ('Home maintenance', 16),
  ('Electronics', 17),
  ('Gifts & Donations', 18),
  ('Travel', 19),
  ('Insurance', 20),
  ('Loan & EMI', 21),
  ('Taxes', 22),
  ('Pets', 23),
  ('Phone & Internet', 24),
  ('Subscriptions', 25)
) as v(name, sort_order)
where not exists (
  select 1 from public.expense_categories ec
  where ec.household_id is null
    and ec.name = v.name
    and ec.category_kind = 'expense'
);

-- Keep the generic "Other" bucket at the end of the expense list.
update public.expense_categories
set sort_order = 999
where household_id is null
  and name = 'Other'
  and category_kind = 'expense';
