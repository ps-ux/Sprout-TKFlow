-- Payroll Instructions is now fully per-line: Payout Inclusion and Attendance Period
-- (columns added 2026-08-28, previously an unused "override" concept) are now the ONLY
-- source for those two facts -- the ticket-level global fields have been removed from the
-- UI entirely. A PI line also needs its own "date of dispute" now, for the auto-generated
-- Remarks template (see dtmPiLineRemarkTemplate) -- there was no per-line date column yet,
-- only the ticket-level "Date/s of Dispute" field, which a line's date now references.
alter table dispute_payroll_instructions add column if not exists date_of_dispute text;
