-- Needed for the "Add Client" wizard to actually persist -- previously
-- only select was allowed, so new clients only ever lived in memory and
-- vanished on refresh.
create policy "authenticated insert" on company_groups for insert to authenticated with check (true);
create policy "authenticated insert" on companies for insert to authenticated with check (true);
