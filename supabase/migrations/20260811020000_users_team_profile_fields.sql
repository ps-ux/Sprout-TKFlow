-- The Team page's "Edit profile" modal (saveMemberProfile()) only ever wrote to the
-- hardcoded in-memory teamProfiles[] object -- name/role/email/phone/tenure dates/
-- certifications all reset to the seed defaults on every reload. name/role/email already
-- have a home on users; these four don't yet.

alter table users add column if not exists phone text not null default '';
alter table users add column if not exists sprout_started text not null default '';
alter table users add column if not exists hr_started text not null default '';
alter table users add column if not exists certifications text[] not null default '{}';
