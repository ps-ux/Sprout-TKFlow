-- Cross-cutting audit trail: who did what, and what changed from/to what, across sign-ins,
-- task processing, ticket edits, member reassignment, and client profile edits. Deliberately
-- given a real DB-level admin-only read policy (unlike the rest of this repo's permissive
-- using(true) policies) since it's meant to hold a sensitive activity trail.

create table if not exists audit_log (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  actor_name text not null default '',
  actor_email text,
  action text not null,
  entity_type text,
  entity_id text,
  entity_label text,
  field text,
  old_value text,
  new_value text,
  description text not null default ''
);

create index if not exists audit_log_created_at_idx on audit_log (created_at desc);
create index if not exists audit_log_entity_idx on audit_log (entity_type, entity_id);

alter table audit_log enable row level security;

drop policy if exists "authenticated insert" on audit_log;
create policy "authenticated insert" on audit_log for insert to authenticated with check (true);

drop policy if exists "admin read" on audit_log;
create policy "admin read" on audit_log for select to authenticated
  using (exists (select 1 from users where id = auth.uid() and role_type = 'admin'));
