-- Bulk log "Same activity for all rows" saves every row as ONE ad hoc card; the individual
-- entries (employee/reference, description, before, after) live in this JSON array.
-- Single logs and "Different activity per row" logs leave it empty.
alter table adhoc_logs add column if not exists items jsonb not null default '[]'::jsonb;
