-- Persists clients[k].cutoff (the "current cut-off period" label used by checkCutoffRollover's
-- Catch Up flow), which previously had no Supabase column at all -- it only ever lived in the
-- hardcoded JS seed data or an in-memory update that vanished on reload.
alter table companies add column if not exists cutoff text;
