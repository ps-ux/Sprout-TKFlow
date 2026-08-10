-- Auto-numbers dispute tickets per client scope (group-shared like POCs/calendars, or a
-- standalone client's own key) and per year, resetting to 1 automatically on each new year --
-- there was previously no real ticket-numbering system at all; "Ticket ID" was a free-text
-- field with a weak fallback (a hardcoded 2026 base + total dispute count, shared across every
-- client, easily colliding). KN gets seeded to start at 119 since its real ticket history
-- already exists in a separate tracker up through 118.

create table if not exists dispute_ticket_counters (
  scope_key text not null,
  year int not null,
  next_number int not null default 1,
  primary key (scope_key, year)
);

alter table dispute_ticket_counters enable row level security;

drop policy if exists "authenticated read" on dispute_ticket_counters;
create policy "authenticated read" on dispute_ticket_counters for select to authenticated using (true);
drop policy if exists "authenticated insert" on dispute_ticket_counters;
create policy "authenticated insert" on dispute_ticket_counters for insert to authenticated with check (true);
drop policy if exists "authenticated update" on dispute_ticket_counters;
create policy "authenticated update" on dispute_ticket_counters for update to authenticated using (true) with check (true);

insert into dispute_ticket_counters (scope_key, year, next_number)
values ('KN', 2026, 119)
on conflict (scope_key, year) do nothing;
