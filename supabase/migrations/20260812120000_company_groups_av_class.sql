-- Manual company color override now lives at the group level, not per subcompany -- calendars
-- are already scoped to the whole group (see avClassForStoreKey in TKFlow_Hub.html), so a
-- per-subcompany override (companies.av_class, added in the previous migration) never actually
-- showed up anywhere separately. companies.av_class is kept for standalone clients, which are
-- their own group with no company_groups row of their own.

alter table company_groups add column if not exists av_class text;
