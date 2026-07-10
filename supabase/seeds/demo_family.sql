-- =============================================================================
-- MyPlanr demo seed: "The Sharma Family"
-- -----------------------------------------------------------------------------
-- Creates login-ready accounts and ~3 months of realistic usage across every
-- feature (pantry, expenses, recipes, shopping, plans, assets, subscriptions,
-- reminders, family members, medicine schedules).
--
-- Idempotent: re-running deletes the previous demo data (via auth-user cascade)
-- and recreates it from scratch. Run against the pooler/direct Postgres URL as
-- the `postgres` role (RLS is bypassed for the table owner).
--
-- Login accounts (password for all: Demo@1234)
--   priya@myplanr.test  / username: priya   (owner)
--   arjun@myplanr.test  / username: arjun   (co-owner)
--   kavya@myplanr.test  / username: kavya   (member)
--
-- Requires the pgcrypto extension (present on Supabase in the `extensions`
-- schema) for password hashing.
-- =============================================================================

do $$
declare
  -- Auth users
  v_priya uuid := 'aaaaaaaa-0000-4000-8000-000000000001';
  v_arjun uuid := 'aaaaaaaa-0000-4000-8000-000000000002';
  v_kavya uuid := 'aaaaaaaa-0000-4000-8000-000000000003';

  -- Household
  v_house uuid := 'bbbbbbbb-0000-4000-8000-000000000001';

  -- Family member rows
  fm_priya uuid := 'cccccccc-0000-4000-8000-000000000001';
  fm_arjun uuid := 'cccccccc-0000-4000-8000-000000000002';
  fm_kavya uuid := 'cccccccc-0000-4000-8000-000000000003';
  fm_laksh uuid := 'cccccccc-0000-4000-8000-000000000004';
  fm_rohan uuid := 'cccccccc-0000-4000-8000-000000000005';

  -- Pantry items
  p01 uuid := 'dddddddd-0000-4000-8000-000000000001'; -- Basmati Rice
  p02 uuid := 'dddddddd-0000-4000-8000-000000000002'; -- Wheat Flour
  p03 uuid := 'dddddddd-0000-4000-8000-000000000003'; -- Milk (out)
  p04 uuid := 'dddddddd-0000-4000-8000-000000000004'; -- Sugar (low)
  p05 uuid := 'dddddddd-0000-4000-8000-000000000005'; -- Salt
  p06 uuid := 'dddddddd-0000-4000-8000-000000000006'; -- Cooking Oil
  p07 uuid := 'dddddddd-0000-4000-8000-000000000007'; -- Tomatoes
  p08 uuid := 'dddddddd-0000-4000-8000-000000000008'; -- Onions
  p09 uuid := 'dddddddd-0000-4000-8000-000000000009'; -- Eggs (low)
  p10 uuid := 'dddddddd-0000-4000-8000-000000000010'; -- Tea Powder
  p11 uuid := 'dddddddd-0000-4000-8000-000000000011'; -- Coffee
  p12 uuid := 'dddddddd-0000-4000-8000-000000000012'; -- Pasta
  p13 uuid := 'dddddddd-0000-4000-8000-000000000013'; -- Toor Dal
  p14 uuid := 'dddddddd-0000-4000-8000-000000000014'; -- Butter (low)
  p15 uuid := 'dddddddd-0000-4000-8000-000000000015'; -- Bread

  -- Recipes
  r01 uuid := 'eeeeeeee-0000-4000-8000-000000000001'; -- Veg Pulao
  r02 uuid := 'eeeeeeee-0000-4000-8000-000000000002'; -- Tomato Pasta
  r03 uuid := 'eeeeeeee-0000-4000-8000-000000000003'; -- Masala Omelette
  r04 uuid := 'eeeeeeee-0000-4000-8000-000000000004'; -- Dal Tadka

  -- Home assets
  a01 uuid := 'ffffffff-0000-4000-8000-000000000001'; -- Fridge (warranty valid)
  a02 uuid := 'ffffffff-0000-4000-8000-000000000002'; -- Washing machine (expiring)
  a03 uuid := 'ffffffff-0000-4000-8000-000000000003'; -- TV (expired)
  a04 uuid := 'ffffffff-0000-4000-8000-000000000004'; -- Laptop (valid)
  a05 uuid := 'ffffffff-0000-4000-8000-000000000005'; -- Mixer (valid)
  a06 uuid := 'ffffffff-0000-4000-8000-000000000006'; -- Office chair (no warranty)

  -- Expense category ids (global defaults from migration 004)
  cat_groc uuid;
  cat_util uuid;
  cat_rent uuid;
  cat_tran uuid;
  cat_med  uuid;
  cat_ent  uuid;
begin
  -- ---------------------------------------------------------------------------
  -- 0. Clean previous demo (deleting the owner cascades the whole household;
  --    deleting the other users cascades their profiles/memberships).
  -- ---------------------------------------------------------------------------
  delete from auth.users where id in (v_priya, v_arjun, v_kavya);

  -- ---------------------------------------------------------------------------
  -- 1. Auth users (+ identities). The on_auth_user_created trigger creates the
  --    matching public.profiles rows from raw_user_meta_data.
  -- ---------------------------------------------------------------------------
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data,
    confirmation_token, recovery_token, email_change,
    email_change_token_new, reauthentication_token, is_super_admin
  )
  select
    '00000000-0000-0000-0000-000000000000',
    u.id, 'authenticated', 'authenticated', u.email,
    extensions.crypt(u.pw, extensions.gen_salt('bf')),
    now() - interval '100 days', now() - interval '100 days', now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('display_name', u.dn, 'username', u.un),
    '', '', '', '', '', false
  from (values
    (v_priya, 'priya@myplanr.test', 'Demo@1234', 'Priya Sharma', 'priya'),
    (v_arjun, 'arjun@myplanr.test', 'Demo@1234', 'Arjun Sharma', 'arjun'),
    (v_kavya, 'kavya@myplanr.test', 'Demo@1234', 'Kavya Sharma', 'kavya')
  ) as u(id, email, pw, dn, un);

  insert into auth.identities (
    id, user_id, identity_data, provider, provider_id,
    last_sign_in_at, created_at, updated_at
  )
  select
    gen_random_uuid(), u.id,
    jsonb_build_object(
      'sub', u.id::text, 'email', u.email,
      'email_verified', true, 'phone_verified', false
    ),
    'email', u.id::text,
    now(), now(), now()
  from (values
    (v_priya, 'priya@myplanr.test'),
    (v_arjun, 'arjun@myplanr.test'),
    (v_kavya, 'kavya@myplanr.test')
  ) as u(id, email);

  -- ---------------------------------------------------------------------------
  -- 2. Household, settings (all modules on), memberships, active household.
  -- ---------------------------------------------------------------------------
  insert into public.households (id, name, owner_id, created_at, updated_at)
  values (v_house, 'The Sharma Family', v_priya,
          now() - interval '95 days', now() - interval '95 days');

  insert into public.household_settings (household_id, enabled_modules)
  values (
    v_house,
    array['pantry','shopping','expenses','plans','recipes','assets',
          'member_details','subscriptions','reminders']
  );

  insert into public.household_memberships (household_id, user_id, role, joined_at) values
    (v_house, v_priya, 'owner',    now() - interval '95 days'),
    (v_house, v_arjun, 'co_owner', now() - interval '92 days'),
    (v_house, v_kavya, 'member',   now() - interval '90 days');

  update public.profiles
  set active_household_id = v_house
  where id in (v_priya, v_arjun, v_kavya);

  -- Per-member module visibility (fallback is visible, but seed for completeness).
  insert into public.household_member_permissions (household_id, user_id, module, is_visible)
  select v_house, m.user_id, x.module, true
  from (values (v_priya), (v_arjun), (v_kavya)) as m(user_id)
  cross join unnest(array['pantry','shopping','expenses','plans','recipes',
                          'assets','member_details','subscriptions','reminders']) as x(module)
  on conflict (household_id, user_id, module) do nothing;

  -- ---------------------------------------------------------------------------
  -- 3. Family roster (3 app members + 2 profile-only members) + detail cards.
  -- ---------------------------------------------------------------------------
  insert into public.household_family_members (
    id, household_id, user_id, display_name, relationship, member_type,
    invite_status, phone, date_of_birth, created_by, created_at
  ) values
    (fm_priya, v_house, v_priya, 'Priya Sharma',   'self',        'app',    'active', '+91 90000 00001', '1988-04-12', v_priya, now() - interval '95 days'),
    (fm_arjun, v_house, v_arjun, 'Arjun Sharma',   'spouse',      'app',    'active', '+91 90000 00002', '1986-09-30', v_priya, now() - interval '92 days'),
    (fm_kavya, v_house, v_kavya, 'Kavya Sharma',   'child',       'app',    'active', '+91 90000 00003', '2009-01-15', v_priya, now() - interval '90 days'),
    (fm_laksh, v_house, null,    'Lakshmi Sharma', 'grandparent', 'roster', null,     '+91 90000 00004', '1955-06-05', v_priya, now() - interval '90 days'),
    (fm_rohan, v_house, null,    'Rohan Sharma',   'child',       'roster', null,     null,              '2014-11-20', v_priya, now() - interval '90 days');

  insert into public.household_member_details (
    family_member_id, household_id, user_id, phone, date_of_birth, blood_group,
    allergies, medicines, doctor_name, doctor_phone, dietary_preference, notes
  ) values
    (fm_priya, v_house, v_priya, '+91 90000 00001', '1988-04-12', 'O+', null,      null,                 null,       null,              'veg',     null),
    (fm_arjun, v_house, v_arjun, '+91 90000 00002', '1986-09-30', 'B+', 'Pollen',  null,                 null,       null,              'non_veg', null),
    (fm_kavya, v_house, v_kavya, '+91 90000 00003', '2009-01-15', 'O+', 'Peanuts', null,                 null,       null,              'veg',     'Class 10 student'),
    (fm_laksh, v_house, null,    '+91 90000 00004', '1955-06-05', 'A+', null,      'BP & sugar tablets', 'Dr. Rao',  '+91 90000 12345', 'veg',     'Diabetic - monitor sugar levels'),
    (fm_rohan, v_house, null,    null,              '2014-11-20', 'A+', 'Dust',    null,                 null,       null,              'veg',     null);

  -- ---------------------------------------------------------------------------
  -- 4. Pantry items (mix of well-stocked, low, and out of stock).
  -- ---------------------------------------------------------------------------
  insert into public.pantry_items (
    id, household_id, name, quantity, unit, low_stock_threshold, low_stock_unit,
    category, brand, created_by, created_at
  ) values
    (p01, v_house, 'Basmati Rice', 8,    'kg',   2,   'kg',   'Grains',     'India Gate',   v_priya, now() - interval '88 days'),
    (p02, v_house, 'Wheat Flour',  5,    'kg',   2,   'kg',   'Grains',     'Aashirvaad',   v_priya, now() - interval '88 days'),
    (p03, v_house, 'Milk',         0,    'L',    1,   'L',    'Dairy',      'Amul',         v_arjun, now() - interval '88 days'),
    (p04, v_house, 'Sugar',        0.4,  'kg',   1,   'kg',   'Other',      'Madhur',       v_priya, now() - interval '88 days'),
    (p05, v_house, 'Salt',         1,    'kg',   0.5, 'kg',   'Spices',     'Tata',         v_priya, now() - interval '88 days'),
    (p06, v_house, 'Cooking Oil',  2,    'L',    1,   'L',    'Oils',       'Fortune',      v_priya, now() - interval '88 days'),
    (p07, v_house, 'Tomatoes',     1.5,  'kg',   1,   'kg',   'Vegetables', null,           v_arjun, now() - interval '80 days'),
    (p08, v_house, 'Onions',       3,    'kg',   1,   'kg',   'Vegetables', null,           v_arjun, now() - interval '80 days'),
    (p09, v_house, 'Eggs',         6,    'pcs',  12,  'pcs',  'Dairy',      null,           v_arjun, now() - interval '80 days'),
    (p10, v_house, 'Tea Powder',   0.25, 'kg',   0.2, 'kg',   'Other',      'Red Label',    v_priya, now() - interval '75 days'),
    (p11, v_house, 'Coffee',       0.2,  'kg',   0.1, 'kg',   'Other',      'Bru',          v_priya, now() - interval '75 days'),
    (p12, v_house, 'Pasta',        2,    'pack', 1,   'pack', 'Grains',     'Del Monte',    v_kavya, now() - interval '70 days'),
    (p13, v_house, 'Toor Dal',     3,    'kg',   1,   'kg',   'Pulses',     'Tata Sampann', v_priya, now() - interval '70 days'),
    (p14, v_house, 'Butter',       0.5,  'pack', 1,   'pack', 'Dairy',      'Amul',         v_priya, now() - interval '60 days'),
    (p15, v_house, 'Bread',        1,    'pack', 1,   'pack', 'Snacks',     'Britannia',    v_arjun, now() - interval '60 days');

  -- Stock movement history (daily-ish milk usage + periodic restocks).
  insert into public.stock_events (item_id, delta, reason, note, created_by, created_at)
  select p03, -1, 'used', 'Daily milk', v_priya, d
  from generate_series(now() - interval '60 days', now() - interval '1 day', interval '2 days') d;

  insert into public.stock_events (item_id, delta, reason, note, created_by, created_at)
  select p03, 6, 'restocked', 'Milk packets', v_arjun, d
  from generate_series(now() - interval '58 days', now() - interval '3 days', interval '6 days') d;

  insert into public.stock_events (item_id, delta, reason, note, created_by, created_at)
  select p07, -0.5, 'used', 'Cooking', v_priya, d
  from generate_series(now() - interval '40 days', now() - interval '1 day', interval '4 days') d;

  insert into public.stock_events (item_id, delta, reason, note, created_by, created_at)
  select p01, 5, 'restocked', 'Monthly rice', v_priya, d
  from generate_series(now() - interval '85 days', now(), interval '30 days') d;

  -- ---------------------------------------------------------------------------
  -- 5. Expenses over the last ~3 months.
  -- ---------------------------------------------------------------------------
  select id into cat_groc from public.expense_categories where household_id is null and name = 'Groceries' limit 1;
  select id into cat_util from public.expense_categories where household_id is null and name = 'Utilities' limit 1;
  select id into cat_rent from public.expense_categories where household_id is null and name = 'Rent' limit 1;
  select id into cat_tran from public.expense_categories where household_id is null and name = 'Transport' limit 1;
  select id into cat_med  from public.expense_categories where household_id is null and name = 'Medical' limit 1;
  select id into cat_ent  from public.expense_categories where household_id is null and name = 'Entertainment' limit 1;

  -- Weekly groceries
  insert into public.expenses (household_id, category_id, amount, currency, title, expense_date, paid_by, created_by, created_at)
  select v_house, cat_groc, round((1200 + random() * 1500)::numeric, 0), 'INR',
         'Weekly groceries', d::date,
         case when (extract(doy from d)::int / 7) % 2 = 0 then v_priya else v_arjun end,
         v_priya, d
  from generate_series(now() - interval '90 days', now(), interval '7 days') d;

  -- Monthly rent (fixed)
  insert into public.expenses (household_id, category_id, amount, currency, title, expense_date, paid_by, created_by, created_at)
  select v_house, cat_rent, 18000, 'INR', 'House rent',
         (date_trunc('month', d) + interval '0 days')::date, v_priya, v_priya, d
  from generate_series(now() - interval '90 days', now(), interval '1 month') d;

  -- Monthly electricity + water
  insert into public.expenses (household_id, category_id, amount, currency, title, expense_date, paid_by, created_by, created_at)
  select v_house, cat_util, round((900 + random() * 700)::numeric, 0), 'INR', 'Electricity bill',
         (date_trunc('month', d) + interval '5 days')::date, v_arjun, v_arjun, d
  from generate_series(now() - interval '90 days', now(), interval '1 month') d;

  insert into public.expenses (household_id, category_id, amount, currency, title, expense_date, paid_by, created_by, created_at)
  select v_house, cat_util, round((250 + random() * 200)::numeric, 0), 'INR', 'Water bill',
         (date_trunc('month', d) + interval '8 days')::date, v_arjun, v_arjun, d
  from generate_series(now() - interval '90 days', now(), interval '1 month') d;

  -- Transport (every 3 days)
  insert into public.expenses (household_id, category_id, amount, currency, title, expense_date, paid_by, created_by, created_at)
  select v_house, cat_tran, round((80 + random() * 350)::numeric, 0), 'INR',
         case when random() < 0.5 then 'Fuel' else 'Auto / cab' end, d::date,
         case when (extract(doy from d)::int) % 2 = 0 then v_priya else v_arjun end,
         v_arjun, d
  from generate_series(now() - interval '90 days', now(), interval '3 days') d;

  -- Medical (every ~18 days)
  insert into public.expenses (household_id, category_id, amount, currency, title, expense_date, paid_by, created_by, created_at)
  select v_house, cat_med, round((300 + random() * 1400)::numeric, 0), 'INR',
         'Pharmacy / clinic', d::date, v_priya, v_priya, d
  from generate_series(now() - interval '88 days', now(), interval '18 days') d;

  -- Entertainment (every 10 days)
  insert into public.expenses (household_id, category_id, amount, currency, title, expense_date, paid_by, created_by, created_at)
  select v_house, cat_ent, round((200 + random() * 900)::numeric, 0), 'INR',
         case when random() < 0.5 then 'Dining out' else 'Movie / outing' end, d::date,
         case when random() < 0.5 then v_priya else v_arjun end, v_priya, d
  from generate_series(now() - interval '85 days', now(), interval '10 days') d;

  -- ---------------------------------------------------------------------------
  -- 6. Recipes + ingredients (linked to pantry where possible).
  -- ---------------------------------------------------------------------------
  insert into public.recipes (id, household_id, name, servings, instructions, created_by, created_at) values
    (r01, v_house, 'Veg Pulao',       4, 'Saute onions, add rice and veggies, cook with spices.', v_priya, now() - interval '70 days'),
    (r02, v_house, 'Tomato Pasta',    3, 'Boil pasta, toss in tomato sauce and herbs.',           v_kavya, now() - interval '60 days'),
    (r03, v_house, 'Masala Omelette', 2, 'Whisk eggs with onions and spices, cook on tawa.',      v_arjun, now() - interval '50 days'),
    (r04, v_house, 'Dal Tadka',       4, 'Pressure cook dal, temper with spices and tomato.',     v_priya, now() - interval '40 days');

  insert into public.recipe_ingredients (recipe_id, name, quantity, unit, pantry_item_id, sort_order) values
    (r01, 'Basmati Rice', 0.5,  'kg',  p01, 1),
    (r01, 'Onions',       0.2,  'kg',  p08, 2),
    (r01, 'Cooking Oil',  0.05, 'L',   p06, 3),
    (r02, 'Pasta',        1,    'pack', p12, 1),
    (r02, 'Tomatoes',     0.3,  'kg',  p07, 2),
    (r02, 'Cooking Oil',  0.03, 'L',   p06, 3),
    (r03, 'Eggs',         4,    'pcs', p09, 1),
    (r03, 'Onions',       0.1,  'kg',  p08, 2),
    (r04, 'Toor Dal',     0.3,  'kg',  p13, 1),
    (r04, 'Tomatoes',     0.2,  'kg',  p07, 2),
    (r04, 'Cooking Oil',  0.03, 'L',   p06, 3);

  -- ---------------------------------------------------------------------------
  -- 7. Shopping list (manual + auto-generated, some checked off).
  -- ---------------------------------------------------------------------------
  insert into public.shopping_list_items (household_id, name, quantity, unit, source, recipe_id, pantry_item_id, is_checked, created_by, created_at) values
    (v_house, 'Milk',      2,   'L',   'low_stock', null, p03, false, v_priya, now() - interval '2 days'),
    (v_house, 'Sugar',     1,   'kg',  'low_stock', null, p04, false, v_priya, now() - interval '2 days'),
    (v_house, 'Eggs',      12,  'pcs', 'low_stock', null, p09, false, v_arjun, now() - interval '1 day'),
    (v_house, 'Butter',    1,   'pack','low_stock', null, p14, true,  v_priya, now() - interval '5 days'),
    (v_house, 'Paneer',    0.5, 'kg',  'manual',    null, null, false, v_kavya, now() - interval '1 day'),
    (v_house, 'Dish soap', 1,   'pcs', 'manual',    null, null, true,  v_arjun, now() - interval '6 days'),
    (v_house, 'Tomatoes',  1,   'kg',  'recipe',    r02,  p07, false, v_kavya, now() - interval '3 days');

  -- ---------------------------------------------------------------------------
  -- 8. Home assets (warranty valid / expiring / expired / none) + service log.
  -- ---------------------------------------------------------------------------
  insert into public.home_assets (
    id, household_id, created_by, name, description, category, item_kind, status,
    location, acquisition_type, purchase_date, purchase_amount, vendor_name,
    warranty_start, warranty_end, warranty_provider, created_at
  ) values
    (a01, v_house, v_priya, 'Samsung Refrigerator', '253L double door', 'appliance',   'permanent', 'active', 'Kitchen',     'shop',   (now() - interval '400 days')::date, 32000, 'Reliance Digital', (now() - interval '400 days')::date, (now() + interval '330 days')::date, 'Samsung', now() - interval '85 days'),
    (a02, v_house, v_arjun, 'LG Washing Machine',   'Front load 7kg',   'appliance',   'permanent', 'active', 'Utility area','online', (now() - interval '380 days')::date, 28000, 'Amazon',           (now() - interval '380 days')::date, (now() + interval '20 days')::date,  'LG',      now() - interval '85 days'),
    (a03, v_house, v_priya, 'Sony LED TV',          '55 inch 4K',       'electronics', 'permanent', 'active', 'Living Room', 'shop',   (now() - interval '800 days')::date, 65000, 'Croma',            (now() - interval '800 days')::date, (now() - interval '70 days')::date,  'Sony',    now() - interval '85 days'),
    (a04, v_house, v_arjun, 'Dell Laptop',          'Inspiron 15',      'electronics', 'permanent', 'active', 'Study',       'online', (now() - interval '200 days')::date, 58000, 'Dell Store',       (now() - interval '200 days')::date, (now() + interval '530 days')::date, 'Dell',    now() - interval '80 days'),
    (a05, v_house, v_priya, 'Prestige Mixer',       '750W grinder',     'appliance',   'permanent', 'active', 'Kitchen',     'shop',   (now() - interval '150 days')::date,  4500, 'Local Store',      (now() - interval '150 days')::date, (now() + interval '215 days')::date, 'Prestige',now() - interval '70 days'),
    (a06, v_house, v_arjun, 'Office Chair',         'Ergonomic mesh',   'furniture',   'permanent', 'active', 'Study',       'online', (now() - interval '90 days')::date,   7000, 'Pepperfry',        null,                                null,                                null,      now() - interval '60 days');

  insert into public.asset_service_records (asset_id, household_id, created_by, service_type, service_date, shop_name, cost, notes) values
    (a02, v_house, v_arjun, 'shop_repair', (now() - interval '40 days')::date, 'LG Service Center', 1200, 'Drain pump replaced'),
    (a03, v_house, v_priya, 'third_party', (now() - interval '120 days')::date, 'City Electronics',  2500, 'Panel backlight repair');

  -- ---------------------------------------------------------------------------
  -- 9. Subscriptions (monthly + yearly, active + paused, with reminders).
  -- ---------------------------------------------------------------------------
  insert into public.subscriptions (
    household_id, created_by, name, amount, currency, billing_cycle, due_day,
    due_month, auto_renew, reminder_enabled, reminder_days_before, reminder_at,
    is_active, notes, created_at
  ) values
    (v_house, v_priya, 'Netflix',           649,  'INR', 'monthly', 12, null, true, true,  3, now() + interval '6 minutes',  true,  'Premium 4K plan',    now() - interval '80 days'),
    (v_house, v_arjun, 'Amazon Prime',      1499, 'INR', 'yearly',  5,  7,    true, true,  7, now() + interval '30 days', true,  'Annual membership',  now() - interval '80 days'),
    (v_house, v_priya, 'Spotify',           119,  'INR', 'monthly', 20, null, true, false, 3, null,                       true,  null,                 now() - interval '75 days'),
    (v_house, v_arjun, 'Airtel Broadband',  999,  'INR', 'monthly', 1,  null, true, true,  2, now() + interval '12 minutes', true,  'Fiber 200 Mbps',     now() - interval '70 days'),
    (v_house, v_priya, 'Electricity',       null, 'INR', 'monthly', 5,  null, false,false, 3, null,                       true,  'Amount varies',      now() - interval '70 days'),
    (v_house, v_kavya, 'YouTube Premium',   129,  'INR', 'monthly', 15, null, true, true,  2, now() + interval '10 days', false, 'Paused for now',     now() - interval '60 days');

  -- ---------------------------------------------------------------------------
  -- 10. Plans (open, overdue, completed) across types and members.
  -- ---------------------------------------------------------------------------
  insert into public.plans (
    household_id, created_by, scope, plan_type, title, description, status,
    due_at, reminder_enabled, reminder_at, about_member_id, assigned_to,
    reminder_notify_user_id, recipe_id, meal_slot, completed_at, created_at
  ) values
    (v_house, v_priya, 'household', 'task',     'Pay school fees',       'Kavya term 2 fees',      'open',      now() + interval '4 days',  true,  now() + interval '4 minutes',  fm_kavya, fm_priya, v_priya, null, null, null,                       now() - interval '5 days'),
    (v_house, v_arjun, 'household', 'purchase', 'Buy new geyser',        'Old one is leaking',     'open',      now() + interval '10 days', false, null,                       null,     fm_arjun, null,    null, null, null,                       now() - interval '3 days'),
    (v_house, v_priya, 'household', 'medicine', 'Grandma BP checkup',    'Monthly checkup',        'open',      now() + interval '2 days',  true,  now() + interval '10 minutes', fm_laksh, fm_priya, v_priya, null, null, null,                       now() - interval '6 days'),
    (v_house, v_kavya, 'personal',  'task',     'Science project',       'Finish model & report',  'open',      now() + interval '6 days',  true,  now() + interval '18 minutes', fm_kavya, fm_kavya, v_kavya, null, null, null,                       now() - interval '2 days'),
    (v_house, v_priya, 'household', 'meal',     'Idli & Sambar',         null,                     'open',      date_trunc('day', now()) + interval '8 hours',  false, null, null, null, null, null, 'breakfast', null,                       now() - interval '1 day'),
    (v_house, v_priya, 'household', 'meal',     'Dal Rice',              null,                     'open',      date_trunc('day', now()) + interval '13 hours', false, null, null, null, null, null, 'lunch',     null,                       now() - interval '1 day'),
    (v_house, v_priya, 'household', 'meal',     'Roti & Sabzi',          null,                     'open',      date_trunc('day', now()) + interval '19 hours', false, null, null, null, null, null, 'dinner',    null,                       now() - interval '1 day'),
    (v_house, v_priya, 'household', 'meal',     'Sunday lunch: Pulao',   null,                     'open',      now() + interval '1 day',   false, null,                       null,     null,     null,    null, 'lunch',  null,                       now() - interval '1 day'),
    (v_house, v_arjun, 'household', 'task',     'Service the car',       'Due for service',        'open',      now() - interval '3 days',  true,  now() - interval '4 days',  null,     fm_arjun, v_arjun, null, null, null,                       now() - interval '15 days'),
    (v_house, v_priya, 'household', 'purchase', 'Diwali shopping',       'Gifts & decorations',    'completed', now() - interval '40 days', false, null,                       null,     null,     null,    null, null, now() - interval '38 days', now() - interval '50 days'),
    (v_house, v_arjun, 'household', 'task',     'Renew car insurance',   null,                     'completed', now() - interval '25 days', false, null,                       null,     fm_arjun, null,    null, null, now() - interval '24 days', now() - interval '35 days'),
    (v_house, v_priya, 'household', 'medicine', 'Kavya dentist visit',   null,                     'completed', now() - interval '20 days', false, null,                       fm_kavya, fm_priya, null,    null, null, now() - interval '20 days', now() - interval '30 days'),
    (v_house, v_kavya, 'personal',  'task',     'Pay math tuition',      null,                     'completed', now() - interval '10 days', false, null,                       fm_kavya, fm_kavya, null,    null, null, now() - interval '9 days',  now() - interval '18 days'),
    (v_house, v_priya, 'household', 'meal',     'Dal Tadka dinner',      null,                     'completed', now() - interval '5 days',  false, null,                       null,     null,     null,    null, 'dinner', now() - interval '5 days',  now() - interval '6 days'),
    (v_house, v_arjun, 'household', 'other',    'Fix bedroom light',     null,                     'open',      now() + interval '8 days',  false, null,                       null,     fm_arjun, null,    null, null, null,                       now() - interval '2 days');

  -- ---------------------------------------------------------------------------
  -- 11. Standalone reminders.
  -- ---------------------------------------------------------------------------
  insert into public.reminders (household_id, user_id, title, notes, reminder_at, is_active, created_at) values
    (v_house, v_priya, 'Water the plants',  'Balcony garden',         now() + interval '3 minutes',  true, now() - interval '3 days'),
    (v_house, v_priya, 'Call electrician',  'Fix fan regulator',      now() + interval '8 minutes', true, now() - interval '3 days'),
    (v_house, v_arjun, 'Bank KYC update',   'Before month end',       now() + interval '20 minutes', true, now() - interval '2 days'),
    (v_house, v_priya, 'Kavya PTM',         'Parent-teacher meeting', now() + interval '1 day',     true, now() - interval '1 day'),
    (v_house, v_priya, 'Pay maid salary',   'Monthly',                now() + interval '3 days',    true, now() - interval '1 day');

  -- ---------------------------------------------------------------------------
  -- 12. Medicine schedules (grandmother, twice/once daily).
  -- ---------------------------------------------------------------------------
  insert into public.member_medicine_schedules (
    family_member_id, household_id, medicine_for, medicine_name, dosage, times_per_day,
    reminder_notify_user_id, is_active, created_by, created_at
  ) values
    (fm_laksh, v_house, 'Diabetes', 'Metformin', '500mg', jsonb_build_array(to_char(now() + interval '5 minutes', 'HH24:MI'), '08:00', '20:00'), v_priya, true, v_priya, now() - interval '80 days'),
    (fm_laksh, v_house, 'Blood pressure', 'Amlodipine', '5mg', '["09:00"]'::jsonb, v_priya, true, v_priya, now() - interval '80 days');

  raise notice 'Demo family seeded: household %, 3 login users (priya/arjun/kavya @myplanr.test, password Demo@1234).', v_house;
end $$;
