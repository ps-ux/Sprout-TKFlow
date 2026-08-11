-- users only ever got a SELECT policy (see the init migration) -- RLS defaults to denying
-- everything else, so every write to this table (toggleUserPermission()'s permission-flag
-- updates, and likely any "edit team member" save too) has been silently failing this whole
-- time. Matches every other table's permissive-for-now policy set.

drop policy if exists "authenticated update" on users;
create policy "authenticated update" on users for update to authenticated using (true) with check (true);
