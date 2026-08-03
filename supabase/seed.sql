-- Seed data extracted from TKFlow_Hub.html's hardcoded seed objects:
-- `clients` (line 1465), `clientGroups` (line 1655), `allDisputes` (line 16413).
-- Run this AFTER all migrations. Safe to re-run only on an empty set of these
-- tables -- primary keys will conflict on a second run.

insert into company_groups (code, name) values
  ('KN', 'Kuehne + Nagel'),
  ('HDI', 'HDI Group of Companies');

insert into companies (short_key, group_id, name, status, headcount, payroll_type, ticketing_mode)
select v.short_key, cg.id, v.name, 'active', v.headcount, 'Semi-monthly', 'otk'
from (values
  ('KNI',     'KN',  'Kuehne + Nagel, Inc.',                          126),
  ('KNLSI',   'KN',  'Kuehne + Nagel Logistics Solutions, Inc.',       98),
  ('HDI_CG',  'HDI', 'Capital Growth Inc.',                            45),
  ('HDI_EL',  'HDI', 'Erminland Realty Corporation',                   38),
  ('HDI_ADV', 'HDI', 'HDI Adventures Inc.',                            52),
  ('HDI_STF', 'HDI', 'Stanford Finance Corporation',                   41),
  ('HDI_HC',  'HDI', 'Hillcroft Philippines Inc.',                     29),
  ('HDI_WLD', 'HDI', 'HDI World Phils Inc',                            33)
) as v(short_key, group_code, name, headcount)
left join company_groups cg on cg.code = v.group_code;

insert into company_pocs (company_id, name, role, phone, email)
select c.id, v.name, v.role, nullif(v.phone, ''), v.email
from (values
  ('KNI',     'Francesca Atengco', 'Main POC',                     '09773052013', 'francesca.atengco@kuehne-nagel.com'),
  ('KNI',     'Charlie Aguilar',   'Secondary POC (her superior)', '',            'charlie.aguilar@kuehne-nagel.com'),
  ('KNLSI',   'Francesca Atengco', 'Main POC',                     '09773052013', 'francesca.atengco@kuehne-nagel.com'),
  ('KNLSI',   'Charlie Aguilar',   'Secondary POC (her superior)', '',            'charlie.aguilar@kuehne-nagel.com'),
  ('HDI_CG',  'Judy Delos Reyes',  'Main POC',                     '09332192147', 'judydelosreyes@hdiholdings.com'),
  ('HDI_EL',  'Judy Delos Reyes',  'Main POC',                     '09332192147', 'judydelosreyes@hdiholdings.com'),
  ('HDI_ADV', 'Judy Delos Reyes',  'Main POC',                     '09332192147', 'judydelosreyes@hdiholdings.com'),
  ('HDI_STF', 'Judy Delos Reyes',  'Main POC',                     '09332192147', 'judydelosreyes@hdiholdings.com'),
  ('HDI_HC',  'Judy Delos Reyes',  'Main POC',                     '09332192147', 'judydelosreyes@hdiholdings.com'),
  ('HDI_WLD', 'Judy Delos Reyes',  'Main POC',                     '09332192147', 'judydelosreyes@hdiholdings.com')
) as v(short_key, name, role, phone, email)
join companies c on c.short_key = v.short_key;

-- `entity` below is the free-text label as originally submitted with each
-- dispute -- kept as raw text because it does NOT reliably match the
-- resolved company's real name (e.g. 'Kuehne + Nagel LSSI' vs the actual
-- company name 'Kuehne + Nagel Logistics Solutions, Inc.', or 'HDI Global
-- SE - Philippines' vs 'HDI Adventures Inc.'). This is a live example of
-- the company-name-matching fragility flagged in the migration doc.
insert into disputes (
  id, company_id, emp_no, emp_name, manager, location, shift, payroll_schedule,
  date_submitted, nature, dispute_dates, full_details, date_action,
  findings, recommended_resolution, payout_cutoff, amount, update_open,
  other_remarks, cutoff, tat, tat_label, status, entity, source
)
select
  v.id, c.id, v.emp_no, v.emp_name, v.manager, v.location, v.shift, v.payroll_schedule,
  v.date_submitted::date, v.nature, jsonb_build_array(v.dispute_date), v.full_details,
  v.date_action::date, v.findings, v.recommended_resolution, v.payout_cutoff, v.amount,
  v.update_open, v.other_remarks, v.cutoff, v.tat, v.tat_label, v.status, v.entity, 'manual'
from (values
  ('#2026-093', 'KNI',   'EMP-0455', 'Marasigan, Kevin',   'Ana Villareal', 'Cebu Warehouse', 'Night Shift', 'Semi-monthly',
   '2026-05-14', 'Missing Time Log', '2026-05-13',
   'Missing IN log for May 13. Bio scan device offline that night per site supervisor. DTR attached.', null,
   '', '', 'May 16-31', '', '', '', 'May 2nd', 'tat-yellow', '3h left', 'dst-open', 'Kuehne + Nagel Inc.'),

  ('#2026-092', 'KNI',   'EMP-0142', 'Santos, Maria', null, null, null, 'Semi-monthly',
   '2026-05-13', 'Leave / Absence Dispute', '2026-05-13',
   'Leave application not reflected in payroll. Filed COA and leave form on May 10, approved by manager on May 11.', null,
   '', '', 'May 16-31', '', '', '', 'May 2nd', 'tat-red', 'TAT breached', 'dst-open', 'Kuehne + Nagel Inc.'),

  ('#2026-091', 'KNI',   'EMP-0088', 'Reyes, Alvin', null, null, null, 'Semi-monthly',
   '2026-05-12', 'Missing Time Log', '2026-05-12',
   'Missing OUT log for May 12. Bio scan not captured due to device error. DTR attached.', null,
   'DTR confirms 2 hrs OT worked past shift end.', 'Add 2 hrs OT to May 2nd payout.', 'May 16-31', '+2 hrs OT',
   'Awaiting HR confirmation', '', 'May 2nd', 'tat-yellow', '1h 20m left', 'dst-rev', 'Kuehne + Nagel Inc.'),

  ('#2026-088', 'KNI',   'EMP-0031', 'Dela Cruz, Jose', null, null, null, 'Semi-monthly',
   '2026-05-10', 'Incorrect Time Log', '2026-05-10',
   'IN log recorded at 9:15 AM but actual clock-in was 8:00 AM. CCTV request submitted.', null,
   '', '', 'May 16-31', '', '', '', 'May 1st', 'tat-green', '4h left', 'dst-open', 'Kuehne + Nagel Inc.'),

  ('#2026-083', 'KNI',   'EMP-0077', 'Acosta, Stephanie', null, null, null, 'Semi-monthly',
   '2026-05-06', 'Half Day / Absence Dispute', '2026-05-06',
   'Half day filed but not reflected in payroll. Leave form attached.', '2026-05-08',
   'Half day leave confirmed approved on May 7.', 'Include in Apr 2nd payout.', 'Apr 16-30', '+0.5 day',
   '', 'Resolved', 'Apr 2nd', 'tat-grey', 'Resolved', 'dst-closed', 'Kuehne + Nagel Inc.'),

  ('#2026-090', 'KNLSI', 'EMP-0201', 'Cruz, Maria', null, null, null, 'Semi-monthly',
   '2026-05-10', 'Schedule Adjustment', '2026-05-10',
   'Schedule adjustment not reflected. Filed on May 8, approved May 9.', null,
   '', '', 'May 16-31', '', '', '', 'May 1st', 'tat-yellow', '2h left', 'dst-open', 'Kuehne + Nagel LSSI'),

  ('#2026-087', 'KNLSI', 'EMP-0155', 'Cerbo, Anna', null, null, null, 'Semi-monthly',
   '2026-05-09', 'Special Allowance Pending', '2026-05-09',
   'SA application pending approval. Submitted May 8 with supporting docs.', null,
   '', '', 'May 16-31', '', '', '', 'May 1st', 'tat-green', '5h left', 'dst-rev', 'Kuehne + Nagel LSSI'),

  ('#2026-084', 'KNLSI', 'EMP-0099', 'Bautista, Rey', null, null, null, 'Semi-monthly',
   '2026-05-07', 'Missing Time Log', '2026-05-07',
   'Missing OUT log May 7. Manual DTR filed and endorsed.', '2026-05-09',
   'DTR confirmed valid.', 'Log corrected.', 'Apr 16-30', '',
   '', 'Resolved', 'Apr 2nd', 'tat-grey', 'Resolved', 'dst-closed', 'Kuehne + Nagel LSSI'),

  ('#2026-089', 'HDI_ADV', 'EMP-0312', 'Tan, Robert', null, null, null, 'Staggered',
   '2026-05-08', 'Overtime Dispute', '2026-05-08',
   'OT hours for May 8 not reflected. OT form approved by supervisor on May 7.', null,
   '', '', 'May 16-31', '+3hrs OT', '', '', 'May 1st', 'tat-red', 'TAT breached', 'dst-open', 'HDI Global SE - Philippines'),

  ('#2026-086', 'HDI_ADV', 'EMP-0298', 'Riego, Mark', null, null, null, 'Staggered',
   '2026-05-08', 'OUT Log Exceeded Threshold', '2026-05-08',
   'OUT log exceeded threshold by 45 mins. Employee claims system delay.', null,
   '', '', 'May 16-31', '', '', '', 'May 1st', 'tat-yellow', '1h 40m left', 'dst-open', 'HDI Global SE - Philippines'),

  ('#2026-085', 'HDI_ADV', 'EMP-0267', 'Fernandez, Liza', null, null, null, 'Staggered',
   '2026-05-07', 'Leave / Absence Dispute', '2026-05-07',
   'Leave application filed May 6, approved same day. Not reflected in payroll.', '2026-05-09',
   'Leave approved and confirmed by HR.', 'Include in next payout.', 'Apr 16-30', '+1 day leave',
   '', 'Resolved', 'Apr 2nd', 'tat-grey', 'Resolved', 'dst-closed', 'HDI Global SE - Philippines')

) as v(
  id, short_key, emp_no, emp_name, manager, location, shift, payroll_schedule,
  date_submitted, nature, dispute_date, full_details, date_action,
  findings, recommended_resolution, payout_cutoff, amount, update_open,
  other_remarks, cutoff, tat, tat_label, status, entity
)
join companies c on c.short_key = v.short_key;

insert into dispute_payroll_instructions (dispute_id, code, number, unit, add_ded, remarks)
values ('#2026-091', 'Ord-OT', '2', null, 'Addition', '');
