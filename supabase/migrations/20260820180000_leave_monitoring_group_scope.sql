-- Leave Monitoring was keyed straight to companies.id (one arbitrary subcompany), but the app
-- has no per-sub picker for this tab -- it was quietly removed everywhere once Tasks/Disputes/
-- Client Profile were redesigned to aggregate/group inline instead, and Leave Monitoring was
-- never updated to match. Opening a multi-sub group's workspace always defaults to its FIRST
-- sub, so uploads/edits silently landed under one arbitrary sub with zero indication that's
-- what was happening (confirmed live: KN's real roster was entirely under KNLSI, while KNI --
-- the group's first sub -- had nothing, making the whole roster look deleted the moment
-- currentWsClient happened to point at KNI instead).
--
-- Switches to the same polymorphic scope_type/scope_id pattern calendars/policy_files already
-- use successfully for this exact company-vs-group split: a real company_groups.id for a
-- multi-entity group (one shared roster), or the single company's own companies.id otherwise.

alter table leave_monitoring_state add column if not exists scope_type text;
alter table leave_monitoring_state add column if not exists scope_id uuid;

-- Backfill: every existing row defaults to its own company scope. Safe to re-run -- only
-- touches rows that haven't been backfilled yet.
update leave_monitoring_state
set scope_type = 'company', scope_id = company_id
where scope_type is null;

-- Move KN's real data (currently under KNLSI's own company scope) to KN's group scope, since
-- KN is a real multi-entity group and this roster is actually shared across KNI + KNLSI.
-- Guarded by the KNLSI short_key match, so this is a no-op (and safe to re-run) once done.
update leave_monitoring_state lms
set scope_type = 'group', scope_id = cg.id
from companies c
join company_groups cg on cg.id = c.group_id
where lms.company_id = c.id and c.short_key = 'KNLSI' and lms.scope_type = 'company';

-- Swap the primary key from (company_id, year) to (scope_type, scope_id, year).
alter table leave_monitoring_state drop constraint if exists leave_monitoring_state_pkey;
alter table leave_monitoring_state alter column scope_type set not null;
alter table leave_monitoring_state alter column scope_id set not null;
alter table leave_monitoring_state add primary key (scope_type, scope_id, year);

-- company_id is now redundant (superseded by scope_type/scope_id) -- drop it once every row has
-- been migrated above, rather than leaving a stale, misleading column around.
alter table leave_monitoring_state drop column if exists company_id;
