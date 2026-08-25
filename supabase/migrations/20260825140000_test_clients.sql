-- Per-member "test client" support: a private sandbox client per team member, excluded from
-- every metrics/count aggregation (Dashboard, Admin overview, Team Capacity, Member Metrics)
-- but otherwise fully usable (sidebar, workspace, task runners) -- see the app's `_isTest`
-- field (TKFlow_Hub.html) for how this gets read/used.

alter table companies add column if not exists is_test boolean not null default false;

-- Remove the old shared "Sample Client for Testing" -- it counted fully in every metric with
-- no exclusion, and is being replaced by one private client per member below. Cascades to its
-- own user_company_relations rows (see init migration's FK).
delete from companies where name = 'Sample Client for Testing';

-- One private test client per real team member (queried live, not a hardcoded roster, so this
-- also covers anyone who joined after this file was written), named "<First name>'s Test
-- Client", short_key "TEST_<their short_key>".
insert into companies (short_key, name, status, headcount, payroll_type, basic_pay_offset, task_config, ticketing_mode, is_test)
select
  'TEST_' || upper(u.short_key),
  split_part(u.name, ' ', 1) || '''s Test Client',
  'active', 0, 'Semi-monthly', 0,
  '{"shift_management": true, "holiday_setup": true, "leave_credits_validation": false, "validation": true, "variance": true, "disputes_summary": true, "newhires": true, "profile": true, "payroll_id_sync": true, "email_support": false, "leave_monitoring": false}'::jsonb,
  'otk', true
from users u
where u.short_key is not null
  and not exists (select 1 from companies c where c.short_key = 'TEST_' || upper(u.short_key));

-- Grant the owning member both assigned + processing access to their own test client (same as
-- a normal new client's specialist gets), and every can_assign admin assigned access to all
-- test clients (same auto-grant every real client already gets).
insert into user_company_relations (user_id, company_id, relation_type)
select u.id, c.id, 'assigned'
from users u
join companies c on c.short_key = 'TEST_' || upper(u.short_key)
where not exists (
  select 1 from user_company_relations r where r.user_id = u.id and r.company_id = c.id and r.relation_type = 'assigned'
);

insert into user_company_relations (user_id, company_id, relation_type)
select u.id, c.id, 'processing'
from users u
join companies c on c.short_key = 'TEST_' || upper(u.short_key)
where not exists (
  select 1 from user_company_relations r where r.user_id = u.id and r.company_id = c.id and r.relation_type = 'processing'
);

insert into user_company_relations (user_id, company_id, relation_type)
select a.id, c.id, 'assigned'
from users a
cross join companies c
where a.can_assign = true and c.is_test = true
and not exists (
  select 1 from user_company_relations r where r.user_id = a.id and r.company_id = c.id and r.relation_type = 'assigned'
);
