-- Disputes/ticketing group. `id` is kept as a natural text key (e.g. 'TK-1001')
-- shared with the ticketing portal's ticket IDs, so the webhook can upsert
-- idempotently by id instead of needing a separate mapping table.

create table disputes (
  id text primary key,
  company_id uuid references companies(id) on delete set null,
  emp_no text,
  emp_name text,
  emp_email text,
  manager text,
  location text,
  shift text,
  payroll_schedule text,
  date_submitted date,
  submitted_at timestamptz,         -- preferred over date_submitted for TAT calc when present
  nature text,
  dispute_dates jsonb not null default '[]',
  full_details text,
  date_action date,
  findings text,                    -- OTK-only: never sent by the ticketing tool
  recommended_resolution text,      -- OTK-only
  update_open text,                 -- OTK-only ("Update for Open Tickets")
  other_remarks text,               -- OTK-only
  payout_cutoff text,
  amount numeric,
  cutoff text,                      -- assigned from the company's own current cut-off, never from payload
  tat interval,
  tat_label text,
  status text not null default 'dst-open'
    check (status in ('dst-open', 'dst-rev', 'dst-resolved', 'dst-closed')),
  processor_id uuid references users(id) on delete set null,
  source text not null default 'manual' check (source in ('manual', 'ticketing_tool')),
  is_unrecognized_client boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index disputes_company_id_idx on disputes(company_id);
create index disputes_status_idx on disputes(status);

create table dispute_logs (
  id uuid primary key default gen_random_uuid(),
  dispute_id text not null references disputes(id) on delete cascade,
  author text not null,             -- e.g. 'Ticketing Tool' or a staff name
  message text not null,
  created_at timestamptz not null default now()
);

create index dispute_logs_dispute_id_idx on dispute_logs(dispute_id);

create table dispute_payroll_instructions (
  id uuid primary key default gen_random_uuid(),
  dispute_id text not null references disputes(id) on delete cascade,
  code text,
  number text,
  unit text,
  add_ded text,
  remarks text,
  created_at timestamptz not null default now()
);

create index dispute_payroll_instructions_dispute_id_idx on dispute_payroll_instructions(dispute_id);

alter table disputes enable row level security;
alter table dispute_logs enable row level security;
alter table dispute_payroll_instructions enable row level security;

-- Placeholder policies: any authenticated user can read everything.
-- Deliberately permissive for now -- tighten once real role-based RLS is designed.
create policy "authenticated read" on disputes for select to authenticated using (true);
create policy "authenticated read" on dispute_logs for select to authenticated using (true);
create policy "authenticated read" on dispute_payroll_instructions for select to authenticated using (true);
