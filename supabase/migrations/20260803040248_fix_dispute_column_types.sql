-- Corrections found while extracting real seed data from TKFlow_Hub.html:
-- `amount` holds free text ('+2 hrs OT', '+0.5 day'), not a number.
-- `tat` holds a color-code key ('tat-red'/'tat-yellow'/'tat-green'/'tat-grey'),
-- not a duration -- tat_label already carries the human-readable text.
-- `entity` is a free-text label submitted with the dispute; it does not
-- reliably match any company name (see migration doc risk #1), so it's
-- kept as raw text alongside the resolved company_id rather than relied on.

alter table disputes alter column amount type text using amount::text;
alter table disputes alter column tat type text using tat::text;
alter table disputes add column entity text;
