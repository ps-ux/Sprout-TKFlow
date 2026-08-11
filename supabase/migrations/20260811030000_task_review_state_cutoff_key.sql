-- task_review_state had no cutoff dimension at all (one row per company/task_key -- see the
-- original migration's own comment flagging this as deferred). That meant a saved Validation
-- snapshot from an already-closed cutoff kept auto-restoring the moment the subcompany was
-- selected again, even once a brand-new cutoff had genuinely started.
--
-- cutoff_key identifies which cutoff a snapshot belongs to, computed from each client's own
-- calendar (the date of the first scheduled event after the Attendance Cutoff/Payout column --
-- e.g. Attendance Generation for KN, Attendance Variance processing for HDI, New Hires
-- instruction for Nippon -- whichever the client's own calendar happens to list first).
-- Nullable: clients with no calendar uploaded yet have no way to compute this, so those rows
-- fall back to the old always-restore behavior rather than being blocked.

alter table task_review_state add column if not exists cutoff_key text;
