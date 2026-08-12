-- company_groups only ever had select (init) and insert (Add Client wizard) policies -- no
-- update policy existed at all, same gap as the companies table had before 20260806110000
-- and the users table had before 20260811010000. Every update() call against this table
-- (profile_meta in two places, and the new av_class color picker) has been reporting success
-- with res.error === null while silently saving 0 rows for any real multi-entity group (KNI,
-- HDI) the whole time -- a standalone client was never affected since it writes to companies
-- instead, which already has its update policy.

drop policy if exists "authenticated update" on company_groups;
create policy "authenticated update" on company_groups for update to authenticated using (true) with check (true);
