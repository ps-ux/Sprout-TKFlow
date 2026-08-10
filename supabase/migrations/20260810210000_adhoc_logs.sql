-- Ad hoc Logs had zero persistence at all -- buildAndInsertAdhocCard() only ever built a DOM
-- node and inserted it into the page; the two "seed" cards under KNI were literal static HTML
-- baked into the page itself. That meant every real ad hoc log anyone typed in was just as
-- ephemeral as the demo ones -- gone the moment the page reloaded, and the two demo cards kept
-- reappearing no matter how many times someone clicked Delete, since deleting only ever did a
-- DOM .remove() with nothing behind it to actually delete.
--
-- Scope mirrors POCs/calendars (group-shared vs. one specific company), plus sub_short_key,
-- which is a *separate*, optional concept: which sibling entity within that group this
-- particular log is about, for display grouping -- not a sharing rule.

create table if not exists adhoc_logs (
  id uuid primary key default gen_random_uuid(),
  scope_type text not null check (scope_type in ('group', 'company')),
  group_id uuid references company_groups(id) on delete cascade,
  company_id uuid references companies(id) on delete cascade,
  sub_short_key text not null default '',
  type text not null default 'Other',
  employee_name text not null default '',
  description text not null default '',
  before_value text not null default '',
  after_value text not null default '',
  date_requested date,
  cutoff_label text not null default '',
  is_dispute boolean not null default false,
  remarks text not null default '',
  field_changed text not null default '',
  effective_date date,
  channels text not null default '', -- comma-joined (email/viber/chat) from the Bulk Log form
  status text not null default 'pending' check (status in ('pending', 'done')),
  profile_pulled boolean not null default false,
  created_at timestamptz not null default now()
);

alter table adhoc_logs drop constraint if exists adhoc_logs_scope_check;
alter table adhoc_logs add constraint adhoc_logs_scope_check check (
  (scope_type = 'company' and company_id is not null and group_id is null) or
  (scope_type = 'group' and group_id is not null and company_id is null)
);

alter table adhoc_logs enable row level security;

drop policy if exists "authenticated read" on adhoc_logs;
create policy "authenticated read" on adhoc_logs for select to authenticated using (true);
drop policy if exists "authenticated insert" on adhoc_logs;
create policy "authenticated insert" on adhoc_logs for insert to authenticated with check (true);
drop policy if exists "authenticated update" on adhoc_logs;
create policy "authenticated update" on adhoc_logs for update to authenticated using (true) with check (true);
drop policy if exists "authenticated delete" on adhoc_logs;
create policy "authenticated delete" on adhoc_logs for delete to authenticated using (true);
