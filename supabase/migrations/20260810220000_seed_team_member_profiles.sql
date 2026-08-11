-- Paula, Arianne, and Mhae already exist as hardcoded USERS[] entries in the app (name, role,
-- org hierarchy, permissions) -- that seed data drives the UI, but was never backed by a real
-- Supabase Auth account, so none of them could actually log in. loadCurrentUserFromSession()
-- requires a matching public.users row keyed by the real auth.users id, or login is rejected
-- with "No TKFlow profile found for this account yet."
--
-- This does NOT create the Auth accounts -- that has to happen first, manually, via the
-- Supabase Dashboard (Authentication -> Users -> Add user / Invite), since creating another
-- person's Auth account requires the service-role key, which never touches this machine. Once
-- an account exists for a given email, this looks it up by email (auth.users is queryable from
-- the SQL Editor, which runs with elevated privileges -- the app's own client-side code cannot
-- do this) and inserts/updates the matching public.users row. Silently inserts nothing for any
-- email that doesn't have an Auth account yet, so it's safe to run before all three exist and
-- re-run afterward to pick up the rest.
--
-- short_key values ('arianne'/'paula'/'mhae') match the hardcoded USERS[] object's own keys --
-- loadUserRelationsFromSupabase() depends on this exact match to reconcile a real account back
-- to its USERS[] entry.

insert into users (id, short_key, name, initials, email, role_type, role, org_role, reports_to, can_service_view, can_see_all_disputes, can_manage_access, can_assign, can_archive)
select u.id, 'arianne', 'Arianne Mayie Carias', 'AC', 'arianneo@sprout.ph', 'admin',
  'Associate Director of Managed Payroll Services', 'Director', null,
  true, true, true, true, true
from auth.users u
where u.email = 'arianneo@sprout.ph'
on conflict (id) do update set
  short_key = excluded.short_key, name = excluded.name, initials = excluded.initials,
  email = excluded.email, role_type = excluded.role_type, role = excluded.role,
  org_role = excluded.org_role, reports_to = excluded.reports_to,
  can_service_view = excluded.can_service_view, can_see_all_disputes = excluded.can_see_all_disputes,
  can_manage_access = excluded.can_manage_access, can_assign = excluded.can_assign, can_archive = excluded.can_archive;

insert into users (id, short_key, name, initials, email, role_type, role, org_role, reports_to, can_service_view, can_see_all_disputes, can_manage_access, can_assign, can_archive)
select u.id, 'paula', 'Paula Angila Vaflor', 'PV', 'pvaflor@sprout.ph', 'member',
  'Lead Compensation and Benefits Specialist', 'Lead Processor',
  (select id from users where short_key = 'arianne'),
  false, true, false, false, false
from auth.users u
where u.email = 'pvaflor@sprout.ph'
on conflict (id) do update set
  short_key = excluded.short_key, name = excluded.name, initials = excluded.initials,
  email = excluded.email, role_type = excluded.role_type, role = excluded.role,
  org_role = excluded.org_role, reports_to = excluded.reports_to,
  can_service_view = excluded.can_service_view, can_see_all_disputes = excluded.can_see_all_disputes,
  can_manage_access = excluded.can_manage_access, can_assign = excluded.can_assign, can_archive = excluded.can_archive;

insert into users (id, short_key, name, initials, email, role_type, role, org_role, reports_to, can_service_view, can_see_all_disputes, can_manage_access, can_assign, can_archive)
select u.id, 'mhae', 'Mhae Lorenzo', 'ML', 'alorenzo@sprout.ph', 'member',
  'Senior Compensation and Benefits Specialist', 'Processor',
  (select id from users where short_key = 'paula'),
  false, false, false, false, false
from auth.users u
where u.email = 'alorenzo@sprout.ph'
on conflict (id) do update set
  short_key = excluded.short_key, name = excluded.name, initials = excluded.initials,
  email = excluded.email, role_type = excluded.role_type, role = excluded.role,
  org_role = excluded.org_role, reports_to = excluded.reports_to,
  can_service_view = excluded.can_service_view, can_see_all_disputes = excluded.can_see_all_disputes,
  can_manage_access = excluded.can_manage_access, can_assign = excluded.can_assign, can_archive = excluded.can_archive;

-- Verify all three landed -- if a row is missing here, that person's Auth account doesn't
-- exist yet; create it in the Dashboard, then re-run this whole file.
select short_key, name, email, role_type from users where short_key in ('arianne','paula','mhae');
