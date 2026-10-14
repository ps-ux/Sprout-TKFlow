-- Cut-off labels ("November 1st", "November 1st Payout · att 10/16-10/31") carry no year, so
-- next November's saved progress would load or overwrite this November's. Every table keyed on
-- cutoff_label gets a cutoff_year column that becomes part of its key. Existing rows are
-- backfilled from their own timestamps. The trigger fills the year for any row saved without
-- one, e.g. by a browser tab still running the old page.
-- Idempotent: safe to run more than once.

-- Same rule as cutoffYearOf() in TKFlow_Hub.html: an explicit 20xx in the label wins; otherwise
-- the year whose <Month> 15th falls closest to ref; no month name -> ref's own year.
create or replace function public.tk_cutoff_year(label text, ref timestamptz default now())
returns int language plpgsql stable as $$
declare
  r date := (coalesce(ref, now()) at time zone 'Asia/Manila')::date;
  explicit text := substring(coalesce(label, '') from '\m(20\d\d)\M');
  mon int;
  best int;
  best_diff int;
  d int;
begin
  if explicit is not null then return explicit::int; end if;
  mon := array_position(array['january','february','march','april','may','june','july',
                              'august','september','october','november','december'],
                        lower(substring(coalesce(label, '') from '^\s*([A-Za-z]+)')));
  if mon is null then return extract(year from r)::int; end if;
  best := extract(year from r)::int;
  for y in extract(year from r)::int - 1 .. extract(year from r)::int + 1 loop
    d := abs(make_date(y, mon, 15) - r);
    if best_diff is null or d < best_diff then best_diff := d; best := y; end if;
  end loop;
  return best;
end $$;

create or replace function public.tk_fill_cutoff_year() returns trigger language plpgsql as $$
begin
  if new.cutoff_year is null then
    new.cutoff_year := public.tk_cutoff_year(new.cutoff_label, now());
  end if;
  return new;
end $$;

do $$
declare
  t record;
  c record;
begin
  for t in select * from (values
    ('task_cutoff_review_state',  'updated_at',                         'company_id, task_key, cutoff_label, cutoff_year',  true),
    ('task_run_history',          'run_at',                             null,                                               false),
    ('client_cutoff_processing',  'coalesce(started_at, finished_at)',  'company_id, cutoff_label, cutoff_year',            true),
    ('company_headcount_history', 'recorded_at',                        'company_id, cutoff_label, cutoff_year',            false),
    ('cutoff_coverage',           'updated_at',                         'scope_type, scope_id, cutoff_label, cutoff_year',  true)
  ) v(tbl, ts, keycols, is_pk) loop
    execute format('alter table %I add column if not exists cutoff_year int', t.tbl);
    execute format('update %I set cutoff_year = public.tk_cutoff_year(cutoff_label, %s) where cutoff_year is null', t.tbl, t.ts);
    execute format('alter table %I alter column cutoff_year set not null', t.tbl);
    execute format('drop trigger if exists tk_fill_cutoff_year on %I', t.tbl);
    execute format('create trigger tk_fill_cutoff_year before insert on %I for each row execute function public.tk_fill_cutoff_year()', t.tbl);

    if t.keycols is not null then
      -- Drop the old yearless primary key / unique constraint (whatever it is named)...
      for c in
        select con.conname from pg_constraint con
        where con.conrelid = t.tbl::regclass and con.contype in ('p', 'u')
          and exists (select 1 from unnest(con.conkey) k join pg_attribute a on a.attrelid = con.conrelid and a.attnum = k where a.attname = 'cutoff_label')
          and not exists (select 1 from unnest(con.conkey) k join pg_attribute a on a.attrelid = con.conrelid and a.attnum = k where a.attname = 'cutoff_year')
      loop
        execute format('alter table %I drop constraint %I', t.tbl, c.conname);
      end loop;
      -- ...and replace it with the same key plus cutoff_year.
      if not exists (select 1 from pg_constraint where conrelid = t.tbl::regclass and conname = t.tbl || '_year_key') then
        execute format(
          case when t.is_pk then 'alter table %I add constraint %I primary key (%s)'
               else 'alter table %I add constraint %I unique (%s)' end,
          t.tbl, t.tbl || '_year_key', t.keycols);
      end if;
    end if;
  end loop;
end $$;

notify pgrst, 'reload schema';

-- Check: every row got a year, and each table's new key is in place.
select 'task_cutoff_review_state' as tbl, count(*) filter (where cutoff_year is null) as missing_year, string_agg(distinct cutoff_year::text, ', ') as years from task_cutoff_review_state
union all select 'task_run_history', count(*) filter (where cutoff_year is null), string_agg(distinct cutoff_year::text, ', ') from task_run_history
union all select 'client_cutoff_processing', count(*) filter (where cutoff_year is null), string_agg(distinct cutoff_year::text, ', ') from client_cutoff_processing
union all select 'company_headcount_history', count(*) filter (where cutoff_year is null), string_agg(distinct cutoff_year::text, ', ') from company_headcount_history
union all select 'cutoff_coverage', count(*) filter (where cutoff_year is null), string_agg(distinct cutoff_year::text, ', ') from cutoff_coverage;
