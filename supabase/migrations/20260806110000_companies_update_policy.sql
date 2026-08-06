-- companies only ever had select (init) and insert (Add Client wizard) policies -- no update
-- policy exists at all, so any per-company field edit (starting with the ticketing tool
-- mode/url toggle) can only ever live in memory and reverts to whatever Supabase has on
-- every reload. Recreated idempotently, matching this repo's other RLS migrations.
drop policy if exists "authenticated update" on companies;
create policy "authenticated update" on companies for update to authenticated using (true) with check (true);
