-- Foundation tables: companies/groups/POCs and users.
-- Everything else (disputes, webhook, calendars, files) references these.

create table company_groups (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,        -- was clientGroups key, e.g. 'KN', 'HDI'
  name text not null,
  avatar_bg text,
  avatar_text text,
  created_at timestamptz not null default now()
);

create table companies (
  id uuid primary key default gen_random_uuid(),
  short_key text unique not null,   -- was clients key, e.g. 'KNI', 'HDI_CG'
  group_id uuid references company_groups(id) on delete set null,
  name text not null,               -- must match ticketing portal's `company` field exactly
  status text not null default 'active',
  headcount int,
  payroll_type text,
  basic_pay_offset int,
  task_config jsonb not null default '{}',
  ticketing_mode text not null default 'own' check (ticketing_mode in ('otk', 'own')),
  ticketing_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table company_pocs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references companies(id) on delete cascade,
  name text not null,
  role text,
  phone text,
  email text,
  created_at timestamptz not null default now()
);

-- Profile row per Supabase Auth user. id matches auth.users(id) 1:1.
create table users (
  id uuid primary key references auth.users(id) on delete cascade,
  short_key text unique,            -- was USERS key, e.g. 'zona' -- kept for migration continuity
  name text not null,
  initials text,
  email text not null,
  role_type text not null default 'member' check (role_type in ('admin', 'member')),
  role text,                        -- job title, e.g. "Lead Specialist"
  org_role text,
  reports_to uuid references users(id) on delete set null,
  can_service_view boolean not null default false,
  can_see_all_disputes boolean not null default false,
  can_manage_access boolean not null default false,
  can_assign boolean not null default false,
  can_archive boolean not null default false,
  created_at timestamptz not null default now()
);

-- Replaces assignedClients/processClients/auditClients arrays with one join table.
create table user_company_relations (
  user_id uuid not null references users(id) on delete cascade,
  company_id uuid not null references companies(id) on delete cascade,
  relation_type text not null check (relation_type in ('assigned', 'processing', 'audit')),
  primary key (user_id, company_id, relation_type)
);

alter table company_groups enable row level security;
alter table companies enable row level security;
alter table company_pocs enable row level security;
alter table users enable row level security;
alter table user_company_relations enable row level security;

-- Placeholder policies: any authenticated user can read everything.
-- Deliberately permissive for now -- tighten once real role-based RLS is designed.
create policy "authenticated read" on company_groups for select to authenticated using (true);
create policy "authenticated read" on companies for select to authenticated using (true);
create policy "authenticated read" on company_pocs for select to authenticated using (true);
create policy "authenticated read" on users for select to authenticated using (true);
create policy "authenticated read" on user_company_relations for select to authenticated using (true);
