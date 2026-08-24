-- Main/Second processor designation, mirroring the profile_meta/av_class dual-column
-- convention already used for other per-client-or-per-group values in this app: a real
-- multi-entity group's designation lives on company_groups, a standalone client's on
-- companies.
alter table companies add column if not exists main_processor_user_id uuid references users(id) on delete set null;
alter table companies add column if not exists second_processor_user_id uuid references users(id) on delete set null;
alter table company_groups add column if not exists main_processor_user_id uuid references users(id) on delete set null;
alter table company_groups add column if not exists second_processor_user_id uuid references users(id) on delete set null;

-- Cut-off coverage hand-off -- the same mechanism serves both the ordinary Main-to-Second
-- handoff and the rare "Third tier" escalation to someone not normally assigned to the client
-- at all. One row = this person explicitly overrides the designated Main processor for this
-- client's current cut-off; no row = Main is active. Keyed by the canonical
-- getCurrentCutoffLabel(), not the old date-math label the coverage feature used to use.
create table if not exists cutoff_coverage (
  scope_type text not null check (scope_type in ('company', 'group')),
  scope_id uuid not null,
  cutoff_label text not null,
  covering_user_id uuid not null references users(id) on delete cascade,
  assigned_by_user_id uuid references users(id) on delete set null,
  assigned_by_role text,
  updated_at timestamptz not null default now(),
  primary key (scope_type, scope_id, cutoff_label)
);

alter table cutoff_coverage enable row level security;

drop policy if exists "authenticated read" on cutoff_coverage;
create policy "authenticated read" on cutoff_coverage for select to authenticated using (true);
drop policy if exists "authenticated insert" on cutoff_coverage;
create policy "authenticated insert" on cutoff_coverage for insert to authenticated with check (true);
drop policy if exists "authenticated update" on cutoff_coverage;
create policy "authenticated update" on cutoff_coverage for update to authenticated using (true) with check (true);
drop policy if exists "authenticated delete" on cutoff_coverage;
create policy "authenticated delete" on cutoff_coverage for delete to authenticated using (true);
