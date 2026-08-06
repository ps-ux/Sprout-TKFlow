-- Wires the disputes/dispute_logs/dispute_payroll_instructions tables (created in
-- 20260803035611_disputes_and_logs.sql) up for actual use by the app. Two gaps:
--
-- 1. A few columns the frontend needs don't exist yet: the Payroll Instructions section's
--    attendance-period selector and payout-cutoff field (attendance_period, pi_payout on
--    disputes), and a type tag on log entries (system/manual/email/status/ai) that drives
--    icon/color in the log view (type on dispute_logs).
-- 2. Only a SELECT policy exists on any of the three tables -- there's no insert/update/
--    delete policy at all, so the app can read seed-equivalent rows but any write would
--    403. allDisputes has been a hardcoded in-memory array until now for exactly this reason.
--
-- Written to be safely re-runnable (if not exists / drop-then-create policy) since this
-- gets pasted into the SQL Editor by hand rather than applied via a tracked migration run.

alter table disputes add column if not exists attendance_period text
  check (attendance_period in ('current', 'previous'));
alter table disputes add column if not exists pi_payout text;
alter table dispute_logs add column if not exists type text
  check (type in ('system', 'manual', 'email', 'status', 'ai'));

drop policy if exists "authenticated insert" on disputes;
create policy "authenticated insert" on disputes for insert to authenticated with check (true);
drop policy if exists "authenticated update" on disputes;
create policy "authenticated update" on disputes for update to authenticated using (true) with check (true);
-- No delete policy -- tickets only ever transition to dst-closed, never get hard-deleted.

drop policy if exists "authenticated insert" on dispute_logs;
create policy "authenticated insert" on dispute_logs for insert to authenticated with check (true);
-- No update/delete policy -- logs are append-only in the app (dtmAddLog only ever pushes).

drop policy if exists "authenticated insert" on dispute_payroll_instructions;
create policy "authenticated insert" on dispute_payroll_instructions for insert to authenticated with check (true);
drop policy if exists "authenticated delete" on dispute_payroll_instructions;
create policy "authenticated delete" on dispute_payroll_instructions for delete to authenticated using (true);
-- No update policy -- PI lines are synced by delete-all-then-reinsert, not per-row updates.
