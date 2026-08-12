-- Leave Credits Monitoring: per-client, per-calendar-year roster of tenure-based leave-credit
-- transfers (Vacation + Sick, each split into a 1-year tier and a 5+-year tier). Previously
-- held only in an in-memory window.leaveMonitoringStore global with zero persistence -- a
-- reload wiped the whole roster.
--
-- Keyed by (company, year), not just company -- a year's roster must never carry over into
-- the next (an employee who resigned mid-year must NOT reappear in next year's monitoring),
-- so each year gets its own empty bucket, populated fresh from that year's own Employee List +
-- Leave Report uploads. This also lets staff open next year's tab and start setting it up from
-- ~Dec 1 while the current year's tab is still active, and makes "archiving" on Jan 1
-- automatic and free: a past year is simply any year less than the real current year,
-- computed client-side on read -- no stored is_archived flag, no scheduled job.

create table if not exists leave_monitoring_state (
  company_id uuid not null references companies(id) on delete cascade,
  year int not null,
  data jsonb not null default '{}',
  updated_at timestamptz not null default now(),
  primary key (company_id, year)
);

alter table leave_monitoring_state enable row level security;

drop policy if exists "authenticated read" on leave_monitoring_state;
create policy "authenticated read" on leave_monitoring_state for select to authenticated using (true);
drop policy if exists "authenticated insert" on leave_monitoring_state;
create policy "authenticated insert" on leave_monitoring_state for insert to authenticated with check (true);
drop policy if exists "authenticated update" on leave_monitoring_state;
create policy "authenticated update" on leave_monitoring_state for update to authenticated using (true) with check (true);
drop policy if exists "authenticated delete" on leave_monitoring_state;
create policy "authenticated delete" on leave_monitoring_state for delete to authenticated using (true);
