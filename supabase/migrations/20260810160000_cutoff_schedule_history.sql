-- Records every change to a company's manual Cut-off Schedule (companies.cutoffs) so staff can
-- look back at when/why a client's payout day or attendance cut-off range changed --
-- companies.cutoffs itself only ever holds the current state, with no trace of prior values.
-- Stores whole before/after snapshots (not per-field diffs) since the schedule is small
-- (1-4 periods) and a diff can always be derived by comparing the two snapshots when displaying
-- history, rather than needing to get the diff computation right at write time.

create table if not exists cutoff_schedule_history (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references companies(id) on delete cascade,
  changed_by text not null default '',
  cutoffs_before jsonb not null,
  cutoffs_after jsonb not null,
  changed_at timestamptz not null default now()
);

alter table cutoff_schedule_history enable row level security;

drop policy if exists "authenticated read" on cutoff_schedule_history;
create policy "authenticated read" on cutoff_schedule_history for select to authenticated using (true);
drop policy if exists "authenticated insert" on cutoff_schedule_history;
create policy "authenticated insert" on cutoff_schedule_history for insert to authenticated with check (true);
