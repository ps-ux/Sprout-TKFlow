-- Persists per-company task status (Pending/Done/Skipped), which until now was the plain
-- in-memory `taskStatus` object -- marking a task Done, reloading, and seeing it revert to
-- Pending was expected behavior, not a bug, since nothing ever wrote it anywhere durable.
--
-- One row per (company, task_key); task_key is one of the small fixed set already used
-- throughout the app (variance, validation, disputes_summary, newhires, profile,
-- payroll_instructions) -- read directly off each client's tasks/tasks2/tasks3 arrays, not
-- redefined here as a rigid enum, since new task types can be added without a migration.
--
-- The richer per-run audit trail (window.taskRunHistory/groupProcessingHistory) stays
-- in-memory only for now -- this table is just the "what's the current state" flag that
-- was actually causing the reported reload-reverts-everything problem.

create table if not exists task_runs (
  company_id uuid not null references companies(id) on delete cascade,
  task_key text not null,
  status text not null check (status in ('pending', 'done', 'skipped')),
  reason text,
  updated_at timestamptz not null default now(),
  primary key (company_id, task_key)
);

alter table task_runs enable row level security;

drop policy if exists "authenticated read" on task_runs;
create policy "authenticated read" on task_runs for select to authenticated using (true);
drop policy if exists "authenticated insert" on task_runs;
create policy "authenticated insert" on task_runs for insert to authenticated with check (true);
drop policy if exists "authenticated update" on task_runs;
create policy "authenticated update" on task_runs for update to authenticated using (true) with check (true);
