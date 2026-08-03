-- Persists Policy Bank uploads and TK Calendar uploads to Supabase Storage.
-- Both were previously held only in an in-memory JS array (policyFiles, _calStore),
-- so every reload silently discarded everything anyone had uploaded.

insert into storage.buckets (id, name, public)
values ('policy-files', 'policy-files', false),
       ('calendars', 'calendars', false)
on conflict (id) do nothing;

create table policy_files (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references companies(id) on delete cascade,
  name text not null,
  content_type text,
  size bigint,
  storage_path text not null,
  created_at timestamptz not null default now()
);

create index policy_files_company_id_idx on policy_files(company_id);

alter table policy_files enable row level security;

create policy "authenticated read" on policy_files for select to authenticated using (true);
create policy "authenticated insert" on policy_files for insert to authenticated with check (true);
create policy "authenticated delete" on policy_files for delete to authenticated using (true);

-- One row per scope (a real multi-entity group, or a standalone company) -- unique on
-- (scope_type, scope_id) so a reupload upserts in place instead of accumulating rows,
-- matching the app's "the newest upload is the one followed" behavior for the active
-- calendar. Historical versions are kept separately, as ordinary rows in policy_files.
create table calendars (
  id uuid primary key default gen_random_uuid(),
  scope_type text not null check (scope_type in ('company', 'group')),
  scope_id uuid not null,
  file_name text not null,
  storage_path text not null,
  cal_periods jsonb not null default '[]',
  cal_holidays jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (scope_type, scope_id)
);

alter table calendars enable row level security;

create policy "authenticated read" on calendars for select to authenticated using (true);
create policy "authenticated insert" on calendars for insert to authenticated with check (true);
create policy "authenticated update" on calendars for update to authenticated using (true) with check (true);
create policy "authenticated delete" on calendars for delete to authenticated using (true);

-- Storage RLS -- storage.objects is one shared table across every bucket, so policies
-- must be scoped by bucket_id or they'd apply to every other bucket too.
create policy "authenticated read policy files" on storage.objects
  for select to authenticated using (bucket_id = 'policy-files');
create policy "authenticated insert policy files" on storage.objects
  for insert to authenticated with check (bucket_id = 'policy-files');
create policy "authenticated delete policy files" on storage.objects
  for delete to authenticated using (bucket_id = 'policy-files');

create policy "authenticated read calendars" on storage.objects
  for select to authenticated using (bucket_id = 'calendars');
create policy "authenticated insert calendars" on storage.objects
  for insert to authenticated with check (bucket_id = 'calendars');
create policy "authenticated update calendars" on storage.objects
  for update to authenticated using (bucket_id = 'calendars');
create policy "authenticated delete calendars" on storage.objects
  for delete to authenticated using (bucket_id = 'calendars');
