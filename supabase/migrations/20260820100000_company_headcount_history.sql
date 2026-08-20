-- Snapshots a company's headcount per cut-off, separate from companies.headcount (which is
-- always just the current number). Nothing has ever recorded this before, so Group Overview's
-- headcount card had no way to show "history of headcounts in previous processes" -- only ever
-- today's number. Written whenever Current Attendance Validation updates headcount (see
-- _persistHeadcountHistory in TKFlow_Hub.html); history only starts accumulating from here
-- forward, nothing retroactive.

create table if not exists company_headcount_history (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references companies(id) on delete cascade,
  cutoff_label text not null,
  headcount int not null,
  recorded_at timestamptz not null default now(),
  unique (company_id, cutoff_label)
);

alter table company_headcount_history enable row level security;

drop policy if exists "authenticated read" on company_headcount_history;
create policy "authenticated read" on company_headcount_history for select to authenticated using (true);
drop policy if exists "authenticated insert" on company_headcount_history;
create policy "authenticated insert" on company_headcount_history for insert to authenticated with check (true);
drop policy if exists "authenticated update" on company_headcount_history;
create policy "authenticated update" on company_headcount_history for update to authenticated using (true) with check (true);
