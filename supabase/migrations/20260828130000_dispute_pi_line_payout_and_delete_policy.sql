-- Two fixes from the same session:
--
-- 1. A payroll-instruction line needs its own "Payout Inclusion" override, separate from its
--    ticket's own field -- a ticket with several disputed dates can have one date's line pulled
--    into THIS cut-off's Dispute Summary Report / Payroll Instructions while another date's line
--    waits for a later cut-off, and the ticket itself has to stay open (not tagged for either
--    cut-off specifically) until every date is resolved. Null = inherit the ticket's own
--    pi_payout, so every existing line keeps behaving exactly as before.
alter table dispute_payroll_instructions add column if not exists pi_payout text;

-- 2. The delete-ticket feature (added 2026-08-28) needs a real DELETE policy -- disputes was
--    deliberately built with none (see 20260806100000_dispute_persistence_columns_and_rls.sql:
--    "tickets only ever transition to dst-closed, never get hard-deleted"), so the app's delete
--    call was silently rejected by RLS the whole time; the ticket only ever disappeared from the
--    current browser session, never from the database. Adding delete on dispute_logs too rather
--    than relying on its cascade-from-disputes to bypass RLS on its own.
drop policy if exists "authenticated delete" on disputes;
create policy "authenticated delete" on disputes for delete to authenticated using (true);
drop policy if exists "authenticated delete" on dispute_logs;
create policy "authenticated delete" on dispute_logs for delete to authenticated using (true);
-- dispute_payroll_instructions already has a delete policy (added in 20260806100000 for its
-- own delete-all-then-reinsert sync pattern) -- nothing to add there.
