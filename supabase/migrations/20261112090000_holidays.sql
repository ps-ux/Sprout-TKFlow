-- Team-wide holiday list (PH public holidays + sudden/special non-working days), editable in
-- the Hub (Settings > Holidays). Replaces the hardcoded _PH_HOLS list as the source of truth for
-- TAT deadlines, the To-Do calendar feed, the team calendar, payout roll-back and Leave
-- Monitoring reminder roll-back. Per-client calendar uploads can still add their own holidays
-- on top (calendars.cal_holidays). Idempotent: safe to run more than once.

create table if not exists holidays (
  id uuid primary key default gen_random_uuid(),
  holiday_date date not null unique,
  name text not null default 'Holiday',
  created_at timestamptz not null default now(),
  created_by text
);

alter table holidays enable row level security;

drop policy if exists "authenticated read" on holidays;
create policy "authenticated read" on holidays for select to authenticated using (true);
drop policy if exists "authenticated insert" on holidays;
create policy "authenticated insert" on holidays for insert to authenticated with check (true);
drop policy if exists "authenticated update" on holidays;
create policy "authenticated update" on holidays for update to authenticated using (true) with check (true);
drop policy if exists "authenticated delete" on holidays;
create policy "authenticated delete" on holidays for delete to authenticated using (true);

insert into holidays (holiday_date, name) values
  ('2025-01-01','New Year''s Day'),('2025-04-09','Araw ng Kagitingan'),('2025-04-17','Maundy Thursday'),
  ('2025-04-18','Good Friday'),('2025-04-19','Black Saturday'),('2025-05-01','Labor Day'),
  ('2025-06-12','Independence Day'),('2025-08-21','Ninoy Aquino Day'),('2025-08-25','National Heroes Day'),
  ('2025-11-01','All Saints'' Day'),('2025-11-02','All Souls'' Day'),('2025-11-30','Bonifacio Day'),
  ('2025-12-08','Feast of the Immaculate Conception'),('2025-12-24','Christmas Eve'),
  ('2025-12-25','Christmas Day'),('2025-12-30','Rizal Day'),('2025-12-31','Last Day of the Year'),
  ('2026-01-01','New Year''s Day'),('2026-02-17','Chinese New Year'),('2026-04-02','Maundy Thursday'),
  ('2026-04-03','Good Friday'),('2026-04-04','Black Saturday'),('2026-04-09','Araw ng Kagitingan'),
  ('2026-05-01','Labor Day'),('2026-06-12','Independence Day'),('2026-08-21','Ninoy Aquino Day'),
  ('2026-08-31','National Heroes Day'),('2026-11-01','All Saints'' Day'),('2026-11-02','All Souls'' Day'),
  ('2026-11-16','Special Non-Working Holiday'),('2026-11-17','Special Non-Working Holiday'),
  ('2026-11-18','Special Non-Working Holiday'),
  ('2026-11-30','Bonifacio Day'),('2026-12-08','Feast of the Immaculate Conception'),
  ('2026-12-24','Christmas Eve'),('2026-12-25','Christmas Day'),('2026-12-30','Rizal Day'),
  ('2026-12-31','Last Day of the Year')
on conflict (holiday_date) do nothing;
