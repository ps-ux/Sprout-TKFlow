-- disputes.date_action has been a `date` column since the original 20260803035611 schema.
-- The 2026-08-25 "Merge Replied At into Date of Action" change (commit 7a6a141) started
-- saving it as a formatted text string with a time component, e.g. "Aug 25, 6:00PM" -- Postgres's
-- `date` type requires a full year and rejects that format outright, so every save since 08-25
-- has been silently failing (fire-and-forget write, only a toast on error). Reloading then shows
-- whatever legacy plain date (if any) was already stored before 08-25, reinterpreted through the
-- app's own "no time recorded, assume 6PM EOD" fallback (parseLegacyDateActionEOD) -- which is
-- why every ticket's Date of Action appeared stuck at 6PM regardless of what was actually typed.
--
-- Casting date -> text produces the same "YYYY-MM-DD" string parseLegacyDateActionEOD already
-- expects, so existing values keep working exactly as before (still shown at their old 6PM
-- fallback) until each ticket's Date of Action is re-set with a real time.
--
-- Safe to re-run: altering an already-text column to text via ::text is a harmless no-op.

alter table disputes alter column date_action type text using date_action::text;
