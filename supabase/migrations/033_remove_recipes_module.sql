-- Remove deprecated recipes module from household feature settings.

update public.household_settings
set enabled_modules = array_remove(enabled_modules, 'recipes')
where 'recipes' = any(enabled_modules);
