-- users.avatar_bg/avatar_text are listed in the very first migration's create table statement
-- (20260803035111_init_companies_and_users.sql) but turned out to have never actually been
-- applied to the live database -- confirmed live via a real PostgREST error today:
-- "column users.avatar_bg does not exist" (code 42703), thrown from
-- loadUserRelationsFromSupabase() the moment its select list started referencing them (this
-- session's avatar-color-persistence fix). That one failed query aborted the whole function
-- early (see the `if (usersRes.error) return;` guard, TKFlow_Hub.html ~694), which is why EVERY
-- other thing that function loads -- specialist/processor assignments, org chart data -- also
-- went stale/empty in the same reload: not several separate bugs, one missing column cascading.
--
-- Safe to re-run regardless of whether the columns already exist.

alter table users add column if not exists avatar_bg text;
alter table users add column if not exists avatar_text text;
