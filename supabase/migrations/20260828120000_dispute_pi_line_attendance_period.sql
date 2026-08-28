-- Lets one payroll-instruction line be tagged to a different cut-off ("Attendance Period")
-- than the ticket it belongs to -- needed when a ticket has several disputed dates and only
-- some of them get resolved this cut-off, with the rest resolved (and pulled into Payroll
-- Instructions / Dispute Summary) in a later one. Null = inherit the ticket's own
-- attendance_period, so every existing line keeps behaving exactly as before.
alter table dispute_payroll_instructions add column if not exists attendance_period text;
