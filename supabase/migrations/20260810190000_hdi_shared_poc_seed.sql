-- Same issue as the KN group (see 20260810170000): HDI's one POC (Judy Delos Reyes) was
-- hand-duplicated identically across all 6 of its subs in the hardcoded seed data, and never
-- persisted to Supabase at all. Deleting one of the "duplicates" via the UI only ever removed
-- it from that session's in-memory state -- with nothing in company_pocs to delete, and the
-- per-sub guard in loadPocsFromSupabase() deliberately preserving hardcoded seed data when the
-- DB has nothing for that company, the hardcoded duplicate just came back on every reload.
--
-- Seeds it once as a real group-scoped row so it's shared correctly going forward; the
-- matching hardcoded pocs:[...] arrays in the 6 HDI_* seed entries are cleared in the same
-- app update as this migration.

insert into company_pocs (group_id, scope_type, name, role, phone, email)
select cg.id, 'group', 'Judy Delos Reyes', 'Main POC', '09332192147', 'judydelosreyes@hdiholdings.com'
from company_groups cg
where cg.code = 'HDI'
and not exists (
  select 1 from company_pocs p where p.group_id = cg.id and p.scope_type = 'group' and p.name = 'Judy Delos Reyes'
);
