-- Populated incrementally as real Supabase Auth accounts get created for
-- each of the four staff in USERS (TKFlow_Hub.html line 3606). Run each
-- block only after the matching auth.users account exists (Authentication
-- -> Users -> Add user), using the UID Supabase assigns.

-- zona (Zona Rocelle Merto) -- auth UID eda702f7-3df8-48ab-9628-37b6eae7e548
insert into users (
  id, short_key, name, initials, email, role_type, role, org_role,
  can_service_view, can_see_all_disputes, can_manage_access, can_assign, can_archive
) values (
  'eda702f7-3df8-48ab-9628-37b6eae7e548', 'zona', 'Zona Rocelle Merto', 'ZM', 'zmerto@sprout.ph',
  'admin', 'Admin and Compliance Services Specialist', 'Processor / Service Lead',
  true, true, true, true, true
);

-- zona's assignedClients and processClients are identical (all 8 companies); auditClients is empty.
insert into user_company_relations (user_id, company_id, relation_type)
select 'eda702f7-3df8-48ab-9628-37b6eae7e548', c.id, r.relation_type
from companies c
cross join (values ('assigned'), ('processing')) as r(relation_type)
where c.short_key in ('KNI','KNLSI','HDI_CG','HDI_EL','HDI_ADV','HDI_STF','HDI_HC','HDI_WLD');

-- Note: zona.reportsTo = 'arianne' in the original data, but arianne has no
-- auth account yet, so reports_to is left null here. Once arianne's account
-- exists, run: update users set reports_to = '<arianne-uid>' where short_key = 'zona';
