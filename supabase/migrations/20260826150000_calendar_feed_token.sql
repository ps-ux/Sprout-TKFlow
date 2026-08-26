-- Per-user secret token for the live ICS calendar feed (api/calendar/[token].js).
-- gen_random_uuid() is a Postgres built-in since v13 -- no pgcrypto extension needed.
-- Adding a column with a volatile default forces a rewrite where the default is evaluated
-- once per existing row, so every current user gets a distinct token automatically.
alter table users add column if not exists calendar_feed_token text unique default gen_random_uuid()::text;
