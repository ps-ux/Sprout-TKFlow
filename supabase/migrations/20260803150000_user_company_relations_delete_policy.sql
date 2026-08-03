-- Needed so reassigning an existing client's specialist/auditor via Client Assignments can
-- actually clear the previous assignment in Supabase -- previously only insert/select were
-- allowed on user_company_relations, so saveClientAssignment() was entirely in-memory and
-- any reassignment made there silently reverted on the next reload.
create policy "authenticated delete" on user_company_relations for delete to authenticated using (true);
