-- Client Profile's "Date started", Status, Notes, and Handoff log (profileMeta) had zero
-- persistence -- _saveClientConfirmed() and saveProfile() only ever wrote to the in-memory
-- clientGroups[key]/clients[key] object. loadCompaniesFromSupabase() rebuilds both of those
-- from scratch on every reload with no source data for any of this, so whatever date/status/
-- notes were entered when adding a client (or later edited via Edit Profile) silently reset
-- the moment the page reloaded -- exactly why Add Client's date never matched Client Profile.
--
-- Scoped exactly like calendars/POCs (_calScope()): a real company_groups row for a true
-- multi-entity group, or the single companies row for a standalone client.

alter table company_groups add column if not exists profile_meta jsonb not null default '{}';
alter table companies add column if not exists profile_meta jsonb not null default '{}';
