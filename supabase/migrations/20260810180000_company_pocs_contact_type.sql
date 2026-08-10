-- The Add/Edit POC modal's "Type" dropdown (Primary/Secondary/Timekeeping/Payroll/Manager/
-- Others) was never actually persisted as its own field -- savePOC() only ever wrote it into
-- `role` as a fallback ("role: position || type"), so it silently had no effect whenever
-- Position/title was already filled in, which is true for nearly every real POC. Editing an
-- existing POC's Type and saving looked like it worked but never actually changed anything.
--
-- Adds a real contact_type column so Type is stored (and shown) independently of Position/
-- title, and can now correctly round-trip on edit instead of always resetting to the default.

alter table company_pocs add column if not exists contact_type text not null default '';
