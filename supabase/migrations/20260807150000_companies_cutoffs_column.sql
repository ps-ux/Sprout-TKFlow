-- Persists each company's manual cut-off schedule (payout day + attendance cut-off range per
-- period, shown in Client Profile) -- this was never written to Supabase at all, for any
-- client, even at creation (_saveClientConfirmed built newClientCutoffs from the Add Client
-- wizard's fields but only ever attached it to the in-memory clients[] entry). It's read-only
-- reference data (not used by any live cutoff computation, which reads companies.cutoff
-- instead), so a single jsonb column matching the in-memory shape exactly
-- ([{label, payoutDay, attStart, attEnd, note}, ...]) is enough -- same pattern as task_config.

alter table companies add column if not exists cutoffs jsonb not null default '[]';
