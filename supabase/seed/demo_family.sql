-- Demo "family" seed for app-store screenshots.
--
-- Self-contained: creates a dedicated DEMO LOGIN USER and one fully-populated
-- household ("Maple Home") with fictional names only (no real people).
--
-- HOW TO RUN (Supabase only, no local tooling needed):
--   Supabase Dashboard -> SQL Editor -> New query -> paste this whole file -> Run.
--
-- Safe to re-run: reuses the demo user and rebuilds the household from scratch.
--
-- DEMO LOGIN (use on the app's sign-in screen):
--   email:    demo.family@myplanr.app
--   username: maplehome
--   password: MapleDemo2026!

set search_path = public, extensions, auth;
create extension if not exists pgcrypto;

do $seed$
declare
  v_email    text := 'demo.family@myplanr.app';
  v_username text := 'maplehome';
  v_password text := 'MapleDemo2026!';
  v_display  text := 'Riley';

  v_user uuid;
  v_hh uuid;
  v_hh_name text := 'Maple Home';

  -- family members
  v_self uuid;
  v_spouse uuid;
  v_child1 uuid;
  v_child2 uuid;
  v_parent uuid;

  -- pantry items referenced by the shopping list
  v_milk uuid;
  v_banana uuid;
  v_soap uuid;

  -- receipts
  v_receipt1 uuid;
  v_receipt2 uuid;
begin
  -- 1) Create (or reuse) the dedicated demo auth user ------------------------
  select id into v_user from auth.users where lower(email) = lower(v_email);

  if v_user is null then
    v_user := gen_random_uuid();
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, recovery_token, email_change, email_change_token_new
    ) values (
      '00000000-0000-0000-0000-000000000000', v_user, 'authenticated', 'authenticated',
      lower(v_email), crypt(v_password, gen_salt('bf')), now(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      jsonb_build_object('display_name', v_display, 'username', v_username),
      now(), now(), '', '', '', ''
    );

    insert into auth.identities (
      id, provider_id, user_id, identity_data, provider,
      last_sign_in_at, created_at, updated_at
    ) values (
      gen_random_uuid(), v_user::text, v_user,
      jsonb_build_object('sub', v_user::text, 'email', lower(v_email), 'email_verified', true),
      'email', now(), now(), now()
    );
  else
    -- keep the password fresh in case it changed
    update auth.users
    set encrypted_password = crypt(v_password, gen_salt('bf')),
        email_confirmed_at = coalesce(email_confirmed_at, now()),
        updated_at = now()
    where id = v_user;
  end if;

  -- The on_auth_user_created trigger inserts the profile; make sure it exists
  -- and carries our display name / username.
  insert into public.profiles (id, display_name, username, is_admin)
  values (v_user, v_display, v_username, false)
  on conflict (id) do update
    set display_name = excluded.display_name,
        username = excluded.username;

  raise notice 'Demo user ready: % (%)', v_email, v_user;

  -- 2) Rebuild the demo household from scratch -------------------------------
  delete from public.households where owner_id = v_user and name = v_hh_name;

  insert into public.households (name, owner_id) values (v_hh_name, v_user)
  returning id into v_hh;

  insert into public.household_memberships (household_id, user_id, role)
  values (v_hh, v_user, 'owner');

  insert into public.household_settings (household_id) values (v_hh);
  perform public.seed_member_permissions(v_hh, v_user);

  -- 3) Family roster (fictional names) --------------------------------------
  insert into public.household_family_members
    (household_id, user_id, display_name, relationship, member_type, invite_status, created_by)
  values (v_hh, v_user, v_display, 'self', 'app', 'active', v_user)
  returning id into v_self;

  insert into public.household_family_members
    (household_id, display_name, relationship, member_type, created_by)
  values (v_hh, 'Alex', 'spouse', 'roster', v_user) returning id into v_spouse;

  insert into public.household_family_members
    (household_id, display_name, relationship, member_type, created_by)
  values (v_hh, 'Mia', 'child', 'roster', v_user) returning id into v_child1;

  insert into public.household_family_members
    (household_id, display_name, relationship, member_type, created_by)
  values (v_hh, 'Leo', 'child', 'roster', v_user) returning id into v_child2;

  insert into public.household_family_members
    (household_id, display_name, relationship, member_type, created_by)
  values (v_hh, 'Nora', 'parent', 'roster', v_user) returning id into v_parent;

  insert into public.household_member_details
    (family_member_id, household_id, user_id, date_of_birth, blood_group, dietary_preference, allergies)
  values
    (v_self,   v_hh, v_user, date '1990-04-12', 'O+',  'veg',      null),
    (v_spouse, v_hh, null,   date '1988-09-03', 'A+',  'non_veg',  null),
    (v_child1, v_hh, null,   date '2014-01-22', 'B+',  'veg',      'Peanuts'),
    (v_child2, v_hh, null,   date '2017-06-30', 'O+',  'veg',      null),
    (v_parent, v_hh, null,   date '1958-11-15', 'AB+', 'veg',      null);

  insert into public.member_medicine_schedules
    (family_member_id, household_id, medicine_name, dosage, medicine_for, times_per_day, is_active, created_by, reminder_notify_user_id)
  values
    (v_parent, v_hh, 'BP Tablet', '1 tablet', 'Nora', '["08:00","20:00"]'::jsonb, true, v_user, v_user);

  -- 4) Expenses (last few weeks) --------------------------------------------
  insert into public.expenses
    (household_id, category_id, amount, title, note, expense_date, paid_by, created_by, entry_type)
  values
    (v_hh, (select id from public.expense_categories where name='Groceries' and household_id is null limit 1), 2450, 'Weekly groceries', null, current_date - 1, v_user, v_user, 'expense'),
    (v_hh, (select id from public.expense_categories where name='Dining out' and household_id is null limit 1), 890, 'Family dinner', null, current_date - 2, v_user, v_user, 'expense'),
    (v_hh, (select id from public.expense_categories where name='Fuel' and household_id is null limit 1), 2000, 'Petrol', null, current_date - 3, v_user, v_user, 'expense'),
    (v_hh, (select id from public.expense_categories where name='Transport' and household_id is null limit 1), 240, 'Cab ride', null, current_date - 4, v_user, v_user, 'expense'),
    (v_hh, (select id from public.expense_categories where name='Utilities' and household_id is null limit 1), 1450, 'Electricity bill', null, current_date - 5, v_user, v_user, 'expense'),
    (v_hh, (select id from public.expense_categories where name='Entertainment' and household_id is null limit 1), 499, 'Movie tickets', null, current_date - 6, v_user, v_user, 'expense'),
    (v_hh, (select id from public.expense_categories where name='Rent' and household_id is null limit 1), 18000, 'House rent', null, current_date - 7, v_user, v_user, 'expense'),
    (v_hh, (select id from public.expense_categories where name='Medical' and household_id is null limit 1), 650, 'Pharmacy', null, current_date - 8, v_user, v_user, 'expense'),
    (v_hh, (select id from public.expense_categories where name='Personal care' and household_id is null limit 1), 350, 'Haircut', null, current_date - 9, v_user, v_user, 'expense'),
    (v_hh, (select id from public.expense_categories where name='Household supplies' and household_id is null limit 1), 780, 'Cleaning supplies', null, current_date - 10, v_user, v_user, 'expense'),
    (v_hh, (select id from public.expense_categories where name='Phone & Internet' and household_id is null limit 1), 999, 'Broadband', null, current_date - 11, v_user, v_user, 'expense'),
    (v_hh, (select id from public.expense_categories where name='Groceries' and household_id is null limit 1), 1320, 'Fruits & veggies', null, current_date - 12, v_user, v_user, 'expense'),
    (v_hh, (select id from public.expense_categories where name='Childcare' and household_id is null limit 1), 3000, 'Daycare fees', null, current_date - 14, v_user, v_user, 'expense'),
    (v_hh, (select id from public.expense_categories where name='Dining out' and household_id is null limit 1), 1240, 'Weekend brunch', null, current_date - 16, v_user, v_user, 'expense');

  -- Income (requires family member + source) --------------------------------
  insert into public.expenses
    (household_id, category_id, amount, title, expense_date, paid_by, created_by, entry_type, family_member_id, income_source)
  values
    (v_hh, (select id from public.expense_categories where name='Salary' and household_id is null limit 1), 65000, 'Monthly salary', date_trunc('month', current_date)::date, v_user, v_user, 'income', v_self, 'Monthly salary'),
    (v_hh, (select id from public.expense_categories where name='Freelance' and household_id is null limit 1), 15000, 'Design project', current_date - 3, v_user, v_user, 'income', v_spouse, 'Design freelance'),
    (v_hh, (select id from public.expense_categories where name='Rental' and household_id is null limit 1), 8000, 'Flat rent received', current_date - 6, v_user, v_user, 'income', v_spouse, 'Flat rent');

  -- Recurring money rules ----------------------------------------------------
  insert into public.recurring_money_rules
    (household_id, created_by, entry_type, title, amount, category_id, income_source, family_member_id, frequency, interval_count, day_of_month, start_date, next_due_date, is_active)
  values
    (v_hh, v_user, 'income', 'Monthly salary', 65000, (select id from public.expense_categories where name='Salary' and household_id is null limit 1), 'Monthly salary', v_self, 'monthly', 1, 1, current_date, (date_trunc('month', current_date) + interval '1 month')::date, true);

  insert into public.recurring_money_rules
    (household_id, created_by, entry_type, title, amount, category_id, frequency, interval_count, day_of_month, start_date, next_due_date, is_active)
  values
    (v_hh, v_user, 'expense', 'House rent', 18000, (select id from public.expense_categories where name='Rent' and household_id is null limit 1), 'monthly', 1, 5, current_date, (date_trunc('month', current_date) + interval '1 month' + interval '4 days')::date, true);

  -- 5) Pantry ----------------------------------------------------------------
  insert into public.pantry_items (household_id, name, quantity, unit, category, availability_status, low_stock_threshold, created_by)
  values (v_hh, 'Milk', 2, 'L', 'Dairy', 'required', 3, v_user) returning id into v_milk;

  insert into public.pantry_items (household_id, name, quantity, unit, category, availability_status, low_stock_threshold, created_by)
  values (v_hh, 'Bananas', 0, 'pcs', 'Fruits', 'emergency', 4, v_user) returning id into v_banana;

  insert into public.pantry_items (household_id, name, quantity, unit, category, availability_status, created_by)
  values (v_hh, 'Dish Soap', 1, 'pcs', 'Household', 'required', v_user) returning id into v_soap;

  insert into public.pantry_items (household_id, name, quantity, unit, category, availability_status, brand, created_by)
  values
    (v_hh, 'Basmati Rice', 5, 'kg', 'Grains', 'fine', 'Daawat', v_user),
    (v_hh, 'Wheat Flour', 2, 'kg', 'Grains', 'warning', 'Aashirvaad', v_user),
    (v_hh, 'Toor Dal', 1, 'kg', 'Pulses', 'fine', null, v_user),
    (v_hh, 'Turmeric Powder', 200, 'g', 'Spices', 'fine', null, v_user),
    (v_hh, 'Paneer', 400, 'g', 'Dairy', 'warning', null, v_user),
    (v_hh, 'Tomatoes', 1, 'kg', 'Vegetables', 'fine', null, v_user),
    (v_hh, 'Sunflower Oil', 1, 'L', 'Oils', 'fine', null, v_user),
    (v_hh, 'Biscuits', 3, 'pack', 'Snacks', 'fine', null, v_user);

  -- 6) Shopping list ---------------------------------------------------------
  insert into public.shopping_list_items (household_id, name, quantity, unit, source, pantry_item_id, created_by)
  values
    (v_hh, 'Milk', 2, 'L', 'low_stock', v_milk, v_user),
    (v_hh, 'Bananas', 6, 'pcs', 'low_stock', v_banana, v_user),
    (v_hh, 'Dish Soap', 1, 'pcs', 'low_stock', v_soap, v_user),
    (v_hh, 'Eggs', 12, 'pcs', 'manual', null, v_user),
    (v_hh, 'Bread', 1, 'pack', 'manual', null, v_user),
    (v_hh, 'Ground Coffee', 250, 'g', 'manual', null, v_user);

  -- 7) Home assets -----------------------------------------------------------
  insert into public.home_assets
    (household_id, created_by, name, category, item_kind, status, location, purchase_date, purchase_amount, warranty_start, warranty_end)
  values
    (v_hh, v_user, 'Laptop', 'electronics', 'permanent', 'active', 'Study room', current_date - 400, 72000, current_date - 400, current_date + 30),
    (v_hh, v_user, 'Refrigerator', 'appliance', 'permanent', 'active', 'Kitchen', current_date - 900, 38000, current_date - 900, current_date - 100),
    (v_hh, v_user, 'Sofa Set', 'furniture', 'permanent', 'active', 'Living room', current_date - 1200, 45000, null, null),
    (v_hh, v_user, 'Smart TV', 'electronics', 'permanent', 'active', 'Living room', current_date - 250, 55000, current_date - 250, current_date + 120),
    (v_hh, v_user, 'HDMI Cable', 'cable', 'temporary', 'active', 'TV unit', current_date - 60, 499, null, null);

  -- 8) Subscriptions (generic names) ----------------------------------------
  insert into public.subscriptions
    (household_id, created_by, name, amount, billing_cycle, due_day, due_month, reminder_enabled, reminder_days_before, payment_method, notes)
  values
    (v_hh, v_user, 'Streaming Plus', 499, 'monthly', 12, null, true, 3, 'upi', 'Family plan'),
    (v_hh, v_user, 'Music Unlimited', 129, 'monthly', 5, null, false, 3, 'credit_card', null),
    (v_hh, v_user, 'Cloud Storage', 130, 'monthly', 20, null, true, 2, 'upi', '200 GB'),
    (v_hh, v_user, 'Fitness App', 3999, 'yearly', 1, 6, true, 7, 'credit_card', 'Annual plan');

  -- 9) Reminders (shows off repeat patterns) --------------------------------
  insert into public.reminders (household_id, user_id, title, notes, reminder_at, is_active, repeat, repeat_config)
  values
    (v_hh, v_user, 'Pay electricity bill', 'Due this week', (current_date + 2) + time '18:00', true, 'monthly', null),
    (v_hh, v_user, 'School PTA meeting', 'Bring notebook', (current_date + 3) + time '10:00', true, 'none', null),
    (v_hh, v_user, 'Morning walk', null, current_date + time '06:30', true, 'weekly', '{"frequency":"weekly","interval":1,"days_of_week":[1,2,3,4,5]}'::jsonb),
    (v_hh, v_user, 'Yoga class', null, current_date + time '07:30', true, 'weekly', '{"frequency":"weekly","interval":1,"days_of_week":[2,4]}'::jsonb),
    (v_hh, v_user, 'Water the plants', null, current_date + time '07:00', true, 'daily', '{"frequency":"daily","interval":2}'::jsonb),
    (v_hh, v_user, 'Car service', 'Annual checkup', (current_date + 20) + time '09:00', true, 'yearly', null);

  -- 10) Plans (meals + tasks) -----------------------------------------------
  insert into public.plans
    (household_id, created_by, scope, plan_type, title, description, status, due_at, meal_slot, about_member_id, assigned_to, reminder_enabled, reminder_at, completed_at)
  values
    (v_hh, v_user, 'household', 'meal', 'Veg Pulao', 'Dinner tonight', 'open', current_date + time '20:00', 'dinner', null, v_self, false, null, null),
    (v_hh, v_user, 'household', 'meal', 'Pancakes', 'Weekend breakfast', 'open', (current_date + 1) + time '08:30', 'breakfast', null, null, false, null, null),
    (v_hh, v_user, 'household', 'task', 'Renew car insurance', null, 'open', (current_date + 6) + time '10:00', null, null, v_self, true, (current_date + 5) + time '10:00', null),
    (v_hh, v_user, 'household', 'purchase', 'Buy school notebooks', 'For Mia', 'open', (current_date + 4) + time '17:00', null, v_child1, v_self, false, null, null),
    (v_hh, v_user, 'household', 'task', 'Service the refrigerator', null, 'open', (current_date + 10) + time '11:00', null, null, null, false, null, null),
    (v_hh, v_user, 'personal', 'task', 'Book dentist appointment', null, 'completed', (current_date - 2) + time '15:00', null, v_self, v_self, false, null, (current_date - 2) + time '15:30');

  -- 11) Receipts -------------------------------------------------------------
  insert into public.receipts (household_id, created_by, fingerprint, merchant, purchased_at, total, currency, status)
  values (v_hh, v_user, 'demo-' || v_hh::text || '-1', 'Fresh Mart', current_date - 1, 1240.50, 'INR', 'processed')
  returning id into v_receipt1;

  insert into public.receipts (household_id, created_by, fingerprint, merchant, purchased_at, total, currency, status)
  values (v_hh, v_user, 'demo-' || v_hh::text || '-2', 'Green Grocer', current_date - 4, 860, 'INR', 'pending')
  returning id into v_receipt2;

  insert into public.receipt_line_items (receipt_id, line_index, name, qty, unit, destination, action)
  values
    (v_receipt1, 0, 'Milk', 2, 'L', 'pantry', 'restock'),
    (v_receipt1, 1, 'Bread', 1, 'pack', 'pantry', 'add'),
    (v_receipt1, 2, 'Apples', 1, 'kg', 'pantry', 'add'),
    (v_receipt2, 0, 'Tomatoes', 1, 'kg', 'pantry', 'add'),
    (v_receipt2, 1, 'Onions', 2, 'kg', 'pantry', 'add');

  -- 12) Make it the active household so it shows immediately on login --------
  update public.profiles set active_household_id = v_hh where id = v_user;

  raise notice 'Demo household "%" ready (id %).', v_hh_name, v_hh;
end;
$seed$;
