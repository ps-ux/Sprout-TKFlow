-- Persists churn/archive events so the Archives tab survives a reload -- previously
-- `archivedClients` (churn date, reason, notes, which subcompanies) was a pure in-memory
-- array, never written to Supabase. Churn state itself already round-trips via
-- companies.status (see _persistCompanyStatus), so a churned client correctly stays hidden
-- from the active client list after a reload -- but it silently vanished from Archives too,
-- since nothing ever rebuilt archivedClients from anything persisted.
--
-- One row per churn EVENT (matching one addToArchives() call), not per company -- a whole-
-- group churn and an earlier single-subcompany churn of a sibling need to stay two distinct
-- archive entries with their own reason/date, not merge into one derived from company state
-- alone (which has no memory of past churn events, only the current status).

create table if not exists client_archive_entries (
  id uuid primary key default gen_random_uuid(),
  group_key text not null,
  sub_keys jsonb not null,
  is_partial boolean not null default false,
  churn_date date not null,
  reason text not null default '',
  notes text not null default '',
  last_handler text not null default 'Unknown',
  archived_at timestamptz not null default now()
);

alter table client_archive_entries enable row level security;

drop policy if exists "authenticated read" on client_archive_entries;
create policy "authenticated read" on client_archive_entries for select to authenticated using (true);
drop policy if exists "authenticated insert" on client_archive_entries;
create policy "authenticated insert" on client_archive_entries for insert to authenticated with check (true);
drop policy if exists "authenticated delete" on client_archive_entries;
create policy "authenticated delete" on client_archive_entries for delete to authenticated using (true);
