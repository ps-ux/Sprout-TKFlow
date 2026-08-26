// Live ICS calendar feed -- one per user, addressed by an opaque secret token
// (users.calendar_feed_token, see supabase/migrations/20260826150000_calendar_feed_token.sql).
// Google Calendar (or any calendar app) subscribes to this URL once and re-polls it
// periodically on its own; there's no interactive login on this path, so the token itself is
// the only access control -- treat it like a bearer secret. Content = the same TAT-deadline +
// work-anniversary items the in-app Notifications dropdown already computes
// (renderNotifCard(), TKFlow_Hub.html:6030), scoped to just this user's own clients.
//
// No npm dependency (no @supabase/supabase-js) -- calls Supabase's REST API directly via
// Node's built-in fetch, so this repo doesn't need its first-ever package.json/node_modules.
// Requires the SUPABASE_SERVICE_ROLE_KEY env var (Vercel project settings) -- every relevant
// table's RLS select policy is `to authenticated using (true)`, which an unauthenticated feed
// request (anon key only) can never satisfy, so this route must bypass RLS with service role.

const SUPABASE_URL = 'https://vsfxgptuiudbhkevyako.supabase.co';
const PH_OFFSET_MS = 8 * 60 * 60 * 1000; // Philippines is UTC+8, no DST

// ── Supabase REST helpers ───────────────────────────────────────────────────────────────────

function restHeaders() {
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  return { apikey: key, Authorization: 'Bearer ' + key };
}

async function restGet(path) {
  const res = await fetch(SUPABASE_URL + '/rest/v1/' + path, { headers: restHeaders() });
  if (!res.ok) throw new Error('Supabase REST ' + path + ' -> ' + res.status);
  return res.json();
}

// PostgREST `in.(...)` list -- ids are UUIDs/known-safe text (never user-supplied free text),
// so a plain comma-join is fine here without extra escaping.
function inList(values) {
  return '(' + values.join(',') + ')';
}

// ── PH-local time arithmetic ────────────────────────────────────────────────────────────────
// Vercel's Node runtime defaults to UTC, not Philippine time, so a naive port of the client's
// parseTATEmailTime/getTATDeadline (TKFlow_Hub.html:8235-8281), which relies on the browser's
// LOCAL Date getters already being PH time, would silently compute everything 8 hours off --
// same bug class already fixed elsewhere in this app for calendar/leave dates (PH's positive
// UTC offset shifting things a day/hours in the wrong direction). Every function below operates
// on a Date whose UTC-getter fields hold PH wall-clock values (not real UTC) -- phToRealUTC()
// is the one place that converts to an actual UTC instant, done once, right before use.

function phToRealUTC(phFieldsDate) {
  return new Date(phFieldsDate.getTime() - PH_OFFSET_MS);
}

function nowAsPhFields() {
  return new Date(Date.now() + PH_OFFSET_MS);
}

// Mirrors TKFlow_Hub.html:8235 exactly, just re-anchored to PH-fields-as-UTC throughout.
function parseTATEmailTime(timeStr) {
  if (!timeStr) return null;
  const months = { Jan: 0, Feb: 1, Mar: 2, Apr: 3, May: 4, Jun: 5, Jul: 6, Aug: 7, Sep: 8, Oct: 9, Nov: 10, Dec: 11 };
  const m = String(timeStr).match(/([A-Za-z]+)\s+(\d+),\s*(\d+):(\d+)(AM|PM)/);
  if (!m) return null;
  const month = months[m[1]];
  if (month === undefined) return null;
  const day = parseInt(m[2], 10);
  let hour = parseInt(m[3], 10);
  const min = parseInt(m[4], 10);
  const ap = m[5];
  if (ap === 'PM' && hour !== 12) hour += 12;
  if (ap === 'AM' && hour === 12) hour = 0;
  const nowPh = nowAsPhFields();
  const year = nowPh.getUTCFullYear();
  let dt = new Date(Date.UTC(year, month, day, hour, min, 0));
  if (dt.getTime() - nowPh.getTime() > 2 * 24 * 60 * 60 * 1000) {
    dt = new Date(Date.UTC(year - 1, month, day, hour, min, 0));
  }
  return dt;
}

// Mirrors TKFlow_Hub.html:8292 exactly (re-anchored, see above).
function parseLegacyDateActionEOD(str) {
  if (!str) return null;
  const m = String(str).trim().match(/^(\d{4})-(\d{2})-(\d{2})/);
  if (!m) return null;
  return new Date(Date.UTC(parseInt(m[1], 10), parseInt(m[2], 10) - 1, parseInt(m[3], 10), 18, 0, 0));
}

// Mirrors TKFlow_Hub.html:8263 exactly (re-anchored, see above). Returns PH-fields-as-UTC --
// caller must phToRealUTC() before treating it as a real instant.
function getTATDeadline(emailTimeStr) {
  const emailDt = parseTATEmailTime(emailTimeStr);
  if (!emailDt) return null;
  const cutoff = new Date(emailDt);
  cutoff.setUTCHours(12, 0, 0, 0);
  const deadline = new Date(emailDt);
  if (emailDt <= cutoff) {
    deadline.setUTCHours(18, 0, 0, 0); // before 12NN -> EOD same day
  } else {
    deadline.setUTCDate(deadline.getUTCDate() + 1); // after 12:01PM -> EOD next working day
    if (deadline.getUTCDay() === 6) deadline.setUTCDate(deadline.getUTCDate() + 2);
    if (deadline.getUTCDay() === 0) deadline.setUTCDate(deadline.getUTCDate() + 1);
    deadline.setUTCHours(18, 0, 0, 0);
  }
  return deadline;
}

// Same "still awaiting reply" gate getTATClass (TKFlow_Hub.html:8306) uses -- date_action is
// read as opaque text regardless of its underlying SQL column type, and interpreted with the
// exact same two parsers the client already uses, so this route can't disagree with the app
// about whether a ticket has been replied to.
function hasBeenRepliedTo(dateActionStr) {
  if (!dateActionStr) return false;
  return !!(parseTATEmailTime(dateActionStr) || parseLegacyDateActionEOD(dateActionStr));
}

// ── ICS building ─────────────────────────────────────────────────────────────────────────────

function pad(n) { return n < 10 ? '0' + n : '' + n; }

// RFC 5545 TEXT escaping -- backslash first, then the other reserved characters, then newlines.
// The existing one-off exporter (downloadLeaveMonitoringICS, TKFlow_Hub.html:17241) only escapes
// commas, which is fine for its controlled "Lastname, Firstname - ..." strings but not safe to
// reuse as-is for freer-text ticket/employee names here.
function icsEscape(str) {
  return String(str == null ? '' : str)
    .replace(/\\/g, '\\\\')
    .replace(/;/g, '\\;')
    .replace(/,/g, '\\,')
    .replace(/\r\n|\r|\n/g, '\\n');
}

// realUtcDate -> "YYYYMMDDTHHMMSSZ"
function icsTimestamp(realUtcDate) {
  return realUtcDate.getUTCFullYear() + pad(realUtcDate.getUTCMonth() + 1) + pad(realUtcDate.getUTCDate())
    + 'T' + pad(realUtcDate.getUTCHours()) + pad(realUtcDate.getUTCMinutes()) + pad(realUtcDate.getUTCSeconds()) + 'Z';
}

// y/m/d (1-indexed month, matching how callers already have these from a "YYYY-MM-DD" prefix
// or UTC getters) -> "YYYYMMDD", for VALUE=DATE all-day events.
function icsDateOnly(y, m, d) {
  return y + pad(m) + pad(d);
}

function icsDateOnlyNextDay(y, m, d) {
  // Deliberately goes through a real Date to get correct month/year rollover (e.g. Jan 31 -> Feb 1).
  const dt = new Date(Date.UTC(y, m - 1, d));
  dt.setUTCDate(dt.getUTCDate() + 1);
  return icsDateOnly(dt.getUTCFullYear(), dt.getUTCMonth() + 1, dt.getUTCDate());
}

// events: array of either
//   { kind: 'timed', uid, summary, start: realUtcDate, durationMinutes }
//   { kind: 'allday', uid, summary, year, month, day }  (month is 1-indexed)
function buildICS(calName, events, dtstampNow) {
  const stamp = icsTimestamp(dtstampNow);
  const lines = [
    'BEGIN:VCALENDAR', 'VERSION:2.0', 'PRODID:-//TKFlow Hub//To-Do Calendar//EN',
    'CALSCALE:GREGORIAN', 'X-WR-CALNAME:' + icsEscape(calName)
  ];
  events.forEach(function (e) {
    lines.push('BEGIN:VEVENT');
    lines.push('UID:' + e.uid + '@tkflowhub');
    lines.push('DTSTAMP:' + stamp);
    if (e.kind === 'timed') {
      const end = new Date(e.start.getTime() + (e.durationMinutes || 30) * 60000);
      lines.push('DTSTART:' + icsTimestamp(e.start));
      lines.push('DTEND:' + icsTimestamp(end));
    } else {
      lines.push('DTSTART;VALUE=DATE:' + icsDateOnly(e.year, e.month, e.day));
      lines.push('DTEND;VALUE=DATE:' + icsDateOnlyNextDay(e.year, e.month, e.day));
    }
    lines.push('SUMMARY:' + icsEscape(e.summary));
    lines.push('END:VEVENT');
  });
  lines.push('END:VCALENDAR');
  return lines.join('\r\n');
}

// ── Data assembly ────────────────────────────────────────────────────────────────────────────

async function buildEventsForUser(userId) {
  const rels = await restGet('user_company_relations?user_id=eq.' + userId + '&relation_type=eq.processing&select=company_id');
  const companyIds = rels.map(function (r) { return r.company_id; });
  if (!companyIds.length) return [];

  const companies = await restGet('companies?id=in.' + inList(companyIds) + '&select=id,group_id');

  const events = [];

  // TAT deadlines -- every still-open, not-yet-replied ticket, regardless of how much time is
  // left (the dropdown only shows red/yellow since it's an urgency alert; a calendar's value is
  // forward planning, so this deliberately shows more than the dropdown does).
  const disputes = await restGet(
    'disputes?company_id=in.' + inList(companyIds) +
    '&status=neq.dst-closed&email_time=not.is.null&select=id,emp_name,email_time,date_action'
  );
  disputes.forEach(function (d) {
    if (hasBeenRepliedTo(d.date_action)) return;
    const deadlinePh = getTATDeadline(d.email_time);
    if (!deadlinePh) return;
    events.push({
      kind: 'timed',
      uid: 'tat-' + d.id,
      summary: 'TAT due: ' + (d.emp_name || d.id) + ' (' + d.id + ')',
      start: phToRealUTC(deadlinePh),
      durationMinutes: 30
    });
  });

  // Work anniversaries -- mirrors lmScope()'s company-vs-group scope resolution
  // (TKFlow_Hub.html:16411) so the same leave_monitoring_state rows the app itself reads/writes
  // get found here too.
  const groupScopeIds = [];
  const companyScopeIds = [];
  companies.forEach(function (c) {
    if (c.group_id) groupScopeIds.push(c.group_id); else companyScopeIds.push(c.id);
  });
  const nowPh = nowAsPhFields();
  const years = [nowPh.getUTCFullYear(), nowPh.getUTCFullYear() + 1];

  const lmRows = [];
  if (groupScopeIds.length) {
    const rows = await restGet(
      'leave_monitoring_state?scope_type=eq.group&scope_id=in.' + inList(groupScopeIds) +
      '&year=in.' + inList(years) + '&select=scope_id,year,data'
    );
    lmRows.push.apply(lmRows, rows);
  }
  if (companyScopeIds.length) {
    const rows = await restGet(
      'leave_monitoring_state?scope_type=eq.company&scope_id=in.' + inList(companyScopeIds) +
      '&year=in.' + inList(years) + '&select=scope_id,year,data'
    );
    lmRows.push.apply(lmRows, rows);
  }

  lmRows.forEach(function (row) {
    ['oneYear', 'fiveYear'].forEach(function (category) {
      (row.data && row.data[category] || []).forEach(function (r) {
        if (r.done) return;
        // Anniversary dates are read as a plain "YYYY-MM-DD" string prefix, never round-tripped
        // through a Date object -- avoids re-triggering the exact class of PH-timezone-shift bug
        // already fixed elsewhere in this app for calendar/leave dates (see PH-local comment
        // block above): a naive `new Date(iso)` read with UTC getters on a value that was
        // originally serialized as PH-local midnight can land on the wrong calendar day.
        const m = String(r.anniversary || '').match(/^(\d{4})-(\d{2})-(\d{2})/);
        if (!m) return;
        const label = category === 'fiveYear'
          ? (r.lastName + ', ' + r.firstName + ' — Transfer to ' + r.yearsOfService + ' Years Tenure')
          : (r.lastName + ', ' + r.firstName + ' — 1yr transfer');
        events.push({
          kind: 'allday',
          uid: 'lm-' + row.scope_id + '-' + r.empId + '-' + row.year + '-' + category,
          summary: label,
          year: parseInt(m[1], 10), month: parseInt(m[2], 10), day: parseInt(m[3], 10)
        });
      });
    });
  });

  return events;
}

module.exports = async function handler(req, res) {
  // The URL is .../api/calendar/<token>.ics -- the .ics suffix is there so calendar apps
  // recognize it as a calendar resource, but Vercel's [token] dynamic segment captures the
  // WHOLE path piece between slashes, .ics included. Strip it before using the value as the
  // actual lookup key, or every request 404s (real token + literal ".ics" never matches).
  let token = req.query && req.query.token;
  if (token && token.slice(-4) === '.ics') token = token.slice(0, -4);
  if (!token) { res.status(404).send('Not found'); return; }

  try {
    const users = await restGet('users?calendar_feed_token=eq.' + encodeURIComponent(token) + '&select=id,name');
    const user = users[0];
    if (!user) { res.status(404).send('Not found'); return; }

    const events = await buildEventsForUser(user.id);
    const ics = buildICS('TKFlow — ' + user.name + '’s To-Dos', events, new Date());

    res.setHeader('Content-Type', 'text/calendar; charset=utf-8');
    res.setHeader('Cache-Control', 'public, max-age=1800');
    res.status(200).send(ics);
  } catch (err) {
    console.error('calendar feed error', err);
    res.status(500).send('Could not build calendar feed');
  }
};

module.exports._internal = { buildICS, getTATDeadline, parseTATEmailTime, parseLegacyDateActionEOD, hasBeenRepliedTo, icsEscape, phToRealUTC };
