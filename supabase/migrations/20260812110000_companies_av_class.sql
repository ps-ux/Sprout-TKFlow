-- Lets an admin manually override a company's automatically-assigned avatar/calendar color
-- (see assignAvClass / setCompanyAvClass in TKFlow_Hub.html). The automatic assignment is a
-- deterministic hash of the company's short_key rather than a stored value, so a manual pick
-- needs its own persisted column to survive a reload -- otherwise it would just get
-- recomputed back to the hash-based default on the next load.

alter table companies add column if not exists av_class text;
