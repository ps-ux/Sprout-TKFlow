-- Persists in-progress Variance review state per (company, cut-off) -- unlike Validation,
-- Variance rebuilds its output workbook entirely from parsed data (aoa_to_sheet), rather than
-- patching the original uploaded files' bytes, so no original-file storage is needed here.
-- What DOES need to survive a reload: the already-built output workbook itself (rebuilding it
-- would need the original Orig/ACO/PayReg files re-uploaded) and the small JSON metadata the
-- result-card UI renders from (attData, withVar, counts, colors, finalized flag).
--
-- One row per (company, task_key, cutoff_label) since a company can have multiple cut-offs
-- (e.g. 1st/2nd payout) in progress at once -- cutoff_label is the payout date string already
-- shown in the UI (e.g. "May 28, 2026"), the same natural key the app already uses to tell
-- cut-offs apart (varDownload's filename, varResults[payout], etc).

insert into storage.buckets (id, name, public)
values ('variance-workbooks', 'variance-workbooks', false)
on conflict (id) do nothing;

create table if not exists task_cutoff_review_state (
  company_id uuid not null references companies(id) on delete cascade,
  task_key text not null,
  cutoff_label text not null,
  data jsonb not null default '{}',
  wb_storage_path text,
  updated_at timestamptz not null default now(),
  primary key (company_id, task_key, cutoff_label)
);

alter table task_cutoff_review_state enable row level security;

drop policy if exists "authenticated read" on task_cutoff_review_state;
create policy "authenticated read" on task_cutoff_review_state for select to authenticated using (true);
drop policy if exists "authenticated insert" on task_cutoff_review_state;
create policy "authenticated insert" on task_cutoff_review_state for insert to authenticated with check (true);
drop policy if exists "authenticated update" on task_cutoff_review_state;
create policy "authenticated update" on task_cutoff_review_state for update to authenticated using (true) with check (true);
drop policy if exists "authenticated delete" on task_cutoff_review_state;
create policy "authenticated delete" on task_cutoff_review_state for delete to authenticated using (true);

-- Storage RLS -- storage.objects is one shared table across every bucket, so policies must
-- be scoped by bucket_id (same pattern as the calendars/policy-files/validation-uploads buckets).
drop policy if exists "authenticated read variance workbooks" on storage.objects;
create policy "authenticated read variance workbooks" on storage.objects
  for select to authenticated using (bucket_id = 'variance-workbooks');
drop policy if exists "authenticated insert variance workbooks" on storage.objects;
create policy "authenticated insert variance workbooks" on storage.objects
  for insert to authenticated with check (bucket_id = 'variance-workbooks');
drop policy if exists "authenticated update variance workbooks" on storage.objects;
create policy "authenticated update variance workbooks" on storage.objects
  for update to authenticated using (bucket_id = 'variance-workbooks');
