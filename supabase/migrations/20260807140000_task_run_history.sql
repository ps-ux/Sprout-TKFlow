-- Persists the richer per-run audit trail that task_runs (Phase 2) deliberately deferred:
-- window.taskRunHistory (every run within a cutoff, not just the current status -- running a
-- task twice in one cutoff previously kept both records in memory but lost the first one on
-- reload) and window.groupProcessingHistory (per-client, per-cutoff start/finish tracking,
-- intentionally never cleared on rollover so it builds real history).
--
-- task_run_history is append-only (one row per run event) -- distinct from task_runs, which
-- upserts a single "current state" row per (company, task_key). Two runs of the same task in
-- the same cutoff are two rows here, not one overwritten row.
--
-- client_cutoff_processing is one row per (company, cutoff_label), upserted as tasks progress
-- within that period -- matches groupProcessingHistory's shape (startedAt/finishedAt/tasksDone/
-- totalTasks) exactly so it can be read back into the same in-memory structure on load.

create table if not exists task_run_history (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references companies(id) on delete cascade,
  task_key text not null,
  cutoff_label text not null,
  status text not null,
  reason text not null default '',
  run_at timestamptz not null default now()
);

alter table task_run_history enable row level security;

drop policy if exists "authenticated read" on task_run_history;
create policy "authenticated read" on task_run_history for select to authenticated using (true);
drop policy if exists "authenticated insert" on task_run_history;
create policy "authenticated insert" on task_run_history for insert to authenticated with check (true);

create table if not exists client_cutoff_processing (
  company_id uuid not null references companies(id) on delete cascade,
  cutoff_label text not null,
  started_at timestamptz,
  finished_at timestamptz,
  tasks_done int not null default 0,
  total_tasks int not null default 0,
  primary key (company_id, cutoff_label)
);

alter table client_cutoff_processing enable row level security;

drop policy if exists "authenticated read" on client_cutoff_processing;
create policy "authenticated read" on client_cutoff_processing for select to authenticated using (true);
drop policy if exists "authenticated insert" on client_cutoff_processing;
create policy "authenticated insert" on client_cutoff_processing for insert to authenticated with check (true);
drop policy if exists "authenticated update" on client_cutoff_processing;
create policy "authenticated update" on client_cutoff_processing for update to authenticated using (true) with check (true);
