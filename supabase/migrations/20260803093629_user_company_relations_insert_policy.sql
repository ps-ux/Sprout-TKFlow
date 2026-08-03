-- Needed so creating a new client can also grant admins/specialists access
-- to it in user_company_relations -- without this, a newly created client
-- never appears in anyone's assignedClients after a refresh, which crashes
-- openGroupWorkspace's access filter.
create policy "authenticated insert" on user_company_relations for insert to authenticated with check (true);
