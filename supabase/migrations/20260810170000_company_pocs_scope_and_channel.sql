-- Points of Contact were never actually persisted at all -- savePOC()/removePOC() only ever
-- mutated the in-memory clients[sk].pocs array, so every add/remove vanished on reload. On top
-- of that, company_pocs only had an INSERT-free "authenticated read" policy (no insert/update/
-- delete), and every POC was tied to exactly one company_id -- a POC meant to cover a whole
-- multi-entity group (the common case) had to be hand-duplicated into every sub's row, and the
-- app only showed one consolidated list if every sub's list happened to be byte-identical.
-- Adding a POC to just one sub silently forked that sub's list from the rest of the group.
--
-- This adds a real scope: 'group' (shared across every sub in the group) or 'company' (one
-- specific sub only), mirroring the calendars table's scope_type/scope_id pattern already used
-- elsewhere in this app. Also adds phone_channel (Viber/WhatsApp/Call or SMS/Other) and notes,
-- which the Add POC form already collected but had nowhere to actually store.

alter table company_pocs alter column company_id drop not null;
alter table company_pocs add column if not exists group_id uuid references company_groups(id) on delete cascade;
alter table company_pocs add column if not exists scope_type text not null default 'company' check (scope_type in ('group', 'company'));
alter table company_pocs add column if not exists phone_channel text not null default '';
alter table company_pocs add column if not exists notes text not null default '';

alter table company_pocs drop constraint if exists company_pocs_scope_check;
alter table company_pocs add constraint company_pocs_scope_check check (
  (scope_type = 'company' and company_id is not null and group_id is null) or
  (scope_type = 'group' and group_id is not null and company_id is null)
);

drop policy if exists "authenticated insert" on company_pocs;
create policy "authenticated insert" on company_pocs for insert to authenticated with check (true);
drop policy if exists "authenticated update" on company_pocs;
create policy "authenticated update" on company_pocs for update to authenticated using (true) with check (true);
drop policy if exists "authenticated delete" on company_pocs;
create policy "authenticated delete" on company_pocs for delete to authenticated using (true);

-- Seeds Kuehne + Nagel's two existing POCs (previously hand-duplicated identically onto both
-- KNI and KNLSI in the hardcoded seed data) as group-scoped rows, so they come up correctly
-- shared under the new model instead of as two independent, now-divergent per-sub lists.
-- Guarded on the group actually existing and the POC not already present, so this is safe to
-- re-run and safe to no-op if company_groups hasn't been seeded into Supabase yet.
insert into company_pocs (group_id, scope_type, name, role, phone, email)
select cg.id, 'group', 'Francesca Atengco', 'Main POC', '09773052013', 'francesca.atengco@kuehne-nagel.com'
from company_groups cg
where cg.code = 'KN'
and not exists (
  select 1 from company_pocs p where p.group_id = cg.id and p.scope_type = 'group' and p.name = 'Francesca Atengco'
);

insert into company_pocs (group_id, scope_type, name, role, phone, email)
select cg.id, 'group', 'Charlie Aguilar', 'Secondary POC (her superior)', '', 'charlie.aguilar@kuehne-nagel.com'
from company_groups cg
where cg.code = 'KN'
and not exists (
  select 1 from company_pocs p where p.group_id = cg.id and p.scope_type = 'group' and p.name = 'Charlie Aguilar'
);
