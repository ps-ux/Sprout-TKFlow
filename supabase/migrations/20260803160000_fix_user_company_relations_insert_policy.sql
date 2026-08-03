-- The original insert policy from 20260803093629 should already allow this unconditionally,
-- but a live 403 ("new row violates row-level security policy for table
-- user_company_relations") on insert means it isn't actually present in the database --
-- these migrations are pasted into the SQL Editor by hand rather than applied via a tracked
-- migration run, so one can go missing without anything else noticing. Recreated idempotently.
drop policy if exists "authenticated insert" on user_company_relations;
create policy "authenticated insert" on user_company_relations for insert to authenticated with check (true);
