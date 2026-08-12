-- Persists the "Email Received" field added to the Dispute Ticket Manager. emailTime is the
-- real basis time every TAT calculation (getTATDeadline/getTATClass) runs off of, but it
-- previously lived in memory only -- auto-stamped once when a ticket was logged and never
-- written to Supabase, so a specialist's correction (when a ticket was logged well after the
-- email/report actually came in) was silently lost on the very next reload.

alter table disputes add column if not exists email_time text;
