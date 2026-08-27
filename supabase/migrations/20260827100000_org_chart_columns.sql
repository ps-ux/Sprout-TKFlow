-- Org chart Lead status and show/hide-in-chart have never had a real column to persist to --
-- saveOrgChart() only ever mutated the in-memory `orgStructure` object, so every edit reverted
-- on reload. `users.reports_to` already exists (first migration, 20260803035111) and other
-- flows (Add Team Member) already save/read it correctly, but saveOrgChart's own edits to it
-- were never written back either -- fixed alongside these two new columns.

alter table users add column if not exists is_org_lead boolean not null default false;
alter table users add column if not exists show_in_org_chart boolean not null default true;

-- The app is about to start trusting these DB columns over its hardcoded orgStructure literal
-- (TKFlow_Hub.html, ~8954: arianne is the only isLead:true; paula/zona report to arianne, mhae
-- reports to paula) -- backfill so the four original seeded accounts don't silently lose their
-- lead/reporting structure the moment this ships, before anyone's re-saved the org chart since.
-- Guarded so this is safe to re-run and never clobbers a real change made after this first runs.
update users set is_org_lead = true where short_key = 'arianne' and is_org_lead = false;

update users u set reports_to = (select id from users where short_key = 'arianne')
where u.short_key in ('paula', 'zona') and u.reports_to is null;

update users u set reports_to = (select id from users where short_key = 'paula')
where u.short_key = 'mhae' and u.reports_to is null;
