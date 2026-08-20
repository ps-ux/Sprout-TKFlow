-- Persists the "Replied At" field added to the Dispute Ticket Manager, mirroring email_time's
-- own migration (20260812090000). This is the moment a reply was actually sent -- once set,
-- TAT stops counting against the live clock and freezes at whether that moment beat the
-- deadline (see getTATClass/getTATLabel in TKFlow_Hub.html), instead of a ticket answered well
-- within TAT still drifting toward/into "red" purely because nobody's formally closed it out.

alter table disputes add column if not exists replied_at text;
