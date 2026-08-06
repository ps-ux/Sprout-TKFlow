-- Persists in-progress Validation review state (which employees are flagged, checked,
-- remarked on) plus the original uploaded source files, so an accidental reload mid-review
-- doesn't lose the work AND doesn't require re-uploading the Attendance Report/Approval
-- Center/Biologs files to get back to where you were -- tkDownloadOutput() patches the
-- original files' own bytes to build the final output, so those need to survive too, not
-- just the reviewed row data.
--
-- One row per (company, task_key). Starts with just 'validation' as the only real user of
-- this; task_key stays free text (matching task_runs' same choice) so Variance/Dispute
-- Summary can reuse this table later without a schema change to the column itself -- though
-- Variance's multi-cutoff-per-company case will need its own follow-up migration for that
-- dimension, not designed for speculatively here.

insert into storage.buckets (id, name, public)
values ('validation-uploads', 'validation-uploads', false)
on conflict (id) do nothing;

create table if not exists task_review_state (
  company_id uuid not null references companies(id) on delete cascade,
  task_key text not null,
  data jsonb not null default '{}',
  att_storage_path text,
  ac_storage_path text,
  bio_storage_path text,
  updated_at timestamptz not null default now(),
  primary key (company_id, task_key)
);

alter table task_review_state enable row level security;

drop policy if exists "authenticated read" on task_review_state;
create policy "authenticated read" on task_review_state for select to authenticated using (true);
drop policy if exists "authenticated insert" on task_review_state;
create policy "authenticated insert" on task_review_state for insert to authenticated with check (true);
drop policy if exists "authenticated update" on task_review_state;
create policy "authenticated update" on task_review_state for update to authenticated using (true) with check (true);

-- Storage RLS -- storage.objects is one shared table across every bucket, so policies must
-- be scoped by bucket_id or they'd apply to every other bucket too (same pattern as the
-- calendars/policy-files buckets).
drop policy if exists "authenticated read validation uploads" on storage.objects;
create policy "authenticated read validation uploads" on storage.objects
  for select to authenticated using (bucket_id = 'validation-uploads');
drop policy if exists "authenticated insert validation uploads" on storage.objects;
create policy "authenticated insert validation uploads" on storage.objects
  for insert to authenticated with check (bucket_id = 'validation-uploads');
drop policy if exists "authenticated update validation uploads" on storage.objects;
create policy "authenticated update validation uploads" on storage.objects
  for update to authenticated using (bucket_id = 'validation-uploads');
