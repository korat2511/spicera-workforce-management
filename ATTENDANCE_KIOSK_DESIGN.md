# Attendance Kiosk — Design Doc (for review)

## 1. What's being asked

One shared device (tablet/phone mounted at the restaurant) runs the app in
"kiosk" mode. After the splash screen, instead of going straight to Login,
staff see a gate screen with two choices:

- **Mark Attendance** — any staff member can self-serve: front camera selfie
  → enter their 6-digit PIN → attendance is recorded against whichever staff
  member owns that PIN.
- **Login as Admin** — the existing admin email/password flow, unchanged.

Admins also get a new **Attendance** tab (already a placeholder in the bottom
nav) showing everyone's attendance records.

## 2. New screen flow

```
Splash
  └─▶ Gate screen  ("Mark Attendance" | "Login as Admin")
        ├─▶ Login as Admin  → existing LoginScreen → MainShellScreen
        └─▶ Mark Attendance
              ├─▶ Camera screen (front camera, in-app capture UI)
              ├─▶ PIN entry screen (6-digit)
              └─▶ Result screen (success/error, auto-dismiss back to Gate)
```

The Gate screen replaces Login as the splash's non-authenticated destination.
Admins who are already logged in still skip straight to `MainShellScreen` as
today — this only changes what a *logged-out* device shows.

## 3. Check-in vs check-out

A PIN by itself doesn't say whether this is a check-in or check-out — the
server has to infer it:

- Look up the staff member's most recent attendance record **for today**
  (in the business's configured timezone, `Australia/Sydney`).
- No record yet today → this scan is a **check-in**.
- Last record today is an open check-in (no matching check-out yet) → this
  scan is a **check-out**.
- Last record today is already closed (check-in + check-out both present) →
  policy decision needed (see §6, open question 1).

This means the PIN-entry result screen must say "Checked in" or "Checked
out" — the staff member isn't asked to choose.

## 4. Backend changes

### 4.1 New table: `attendance_records`

| Column | Type | Notes |
|---|---|---|
| `id` | bigint | |
| `business_id` | FK → businesses | kiosk has no logged-in user, so this still needs resolving (see §4.4) |
| `staff_id` | FK → staff | |
| `shift_id` | FK → shifts, nullable | snapshot of whatever shift was assigned *at scan time* |
| `type` | enum `check_in` / `check_out` | |
| `recorded_at` | timestamp | UTC, as always |
| `photo_path` | string, nullable | storage path to the selfie |
| `status` | enum `on_time` / `late` / `early_leave` / `overtime`, nullable | derived from shift start/end + `grace_period_minutes` (already on `Shift`) |
| `device_note` | string, nullable | free text, e.g. "Kiosk" vs future per-device identifiers |
| `created_at` / `updated_at` | | |

Pairing logic (which check-in a check-out closes) is derived at query time
from `staff_id` + date, not stored as an explicit FK — simpler, and avoids a
second write when closing a record.

### 4.2 New endpoints (public, no Sanctum token — the kiosk isn't logged in)

- `POST /api/v1/attendance/punch`
  - multipart: `pin`, `photo` (image file)
  - resolves staff by PIN (hash-compare against every active staff member's
    `pin_hash` in the business — see §6, open question 2 on PIN uniqueness),
    determines check-in/out per §3, stores the photo, returns the staff
    member's name + punch type + time for the confirmation screen.
  - Rate-limited per IP/device to blunt PIN brute-forcing (e.g. Laravel's
    built-in throttle middleware, 5 attempts/minute).

- `GET /api/v1/attendance` *(auth:sanctum, admin-only — joins the existing
  protected route group)*
  - filters: `date_from`, `date_to`, `staff_id`, `status`
  - returns paginated records with staff name/photo/shift for the Admin
    Attendance tab.

### 4.3 Photo storage

Selfies go through the same `Storage::url()` pattern already used for staff
profile photos. Given this runs on shared Hostinger hosting, worth deciding
now: compress/resize on upload (e.g. cap at 480px wide) and set a retention
job (e.g. auto-delete photos older than 90 days) so storage doesn't creep —
see §6, open question 3.

### 4.4 Business resolution without a logged-in user

`BusinessContext::resolve()` currently falls back to `Business::firstOrFail()`
when there's no authenticated user — which already works for a single-tenant
deployment (today's reality) but is a soft spot: it silently picks "the
business" and would misbehave the moment there's more than one. Flagging
this now rather than letting it become a surprise later (see §6, open
question 4).

## 5. Flutter changes

- **`GateScreen`** (new) — replaces `LoginScreen` as splash's logged-out
  destination. Two large buttons: "Mark Attendance" (primary) and "Login as
  Admin" (secondary/outlined). Reuses `AnimatedBrandBackground`.
- **`AttendanceCameraScreen`** (new) — in-app front-camera capture using
  `camera` package (new dependency) rather than the OS camera UI, so the
  framing/instructions can be controlled (e.g. face-guide overlay). On
  capture, holds the photo in memory and pushes to PIN entry.
- **`AttendancePinScreen`** (new) — 6-digit PIN pad (custom numeric keypad,
  not the system keyboard, so no autofill/keyboard-flicker concerns like the
  login screen had). Submits photo + PIN to `/attendance/punch`.
- **`AttendanceResultScreen`** (new) — success state shows staff name +
  "Checked In at 9:02 AM" (or Checked Out), auto-returns to `GateScreen`
  after ~3s. Error state (wrong PIN, inactive staff, no PIN set) shows a
  message and a "Try Again" button.
- **Admin `AttendanceScreen`** (fills the existing placeholder tab) — list of
  attendance records with date-range + staff filters, status chips
  (on-time/late), thumbnail of the punch photo, matching the card/list style
  already used on the Staff and Shifts screens.
- **`AttendanceApiService`** (new) — `punch()` and `list()`.

## 6. Open questions (need your call before implementation)

1. **Re-punching after a closed day** — if someone accidentally checks out
   early and scans again, should the 3rd scan reopen as a new check-in (shift
   split into two sessions), or be rejected with "You've already completed
   today's attendance, see your manager"? Affects payroll hour totals.
2. ~~**PIN uniqueness**~~ — **Resolved: enforced at set-time, built.** PIN
   hashes are bcrypt (salted), so the same PIN hashed twice produces two
   *different* hash strings — a DB unique constraint on the hash column
   can't catch a collision. Instead, `StaffService::setPin()` now checks the
   candidate PIN against every other staff member's existing hash in the
   same business individually (`Hash::check()` per candidate) before saving,
   and rejects with a 422 if any match. Scoped per-business, so two
   different businesses can still have staff sharing the same PIN (no
   cross-business conflict) — and a staff member resetting to their own
   current PIN is allowed (only checks *other* staff). 3 new tests, all
   passing, deployed to production.
3. **Photo retention** — keep forever, or auto-purge after N days? Affects
   storage cost on shared hosting.
4. ~~**Single business assumption**~~ — **Resolved: device pairing, built.**
   An admin registers the physical kiosk once (More → Kiosk Devices →
   Register). The backend issues a long random device token (only the SHA-256
   hash is stored, same approach as password hashing), the app stores it
   locally, and every kiosk request now sends it via an `X-Kiosk-Token`
   header. `BusinessContext::resolve()` checks (in order): authenticated
   admin's business → paired kiosk device's business → fallback to the
   single seeded business. This also closes the security hole where the
   future public `/attendance/punch` endpoint would otherwise be callable by
   anyone on the internet — it now requires a valid, non-revoked device
   token regardless of business count. Admins can revoke a device (e.g. a
   lost/stolen tablet) from the same screen, instantly cutting off its
   ability to accept punches. Shipped: `kiosk_devices` table,
   `ResolveKioskDevice` middleware (`kiosk` alias, ready for the punch route),
   `POST/GET/DELETE /api/v1/kiosk-devices`, Flutter pairing UI in More.
5. **No camera / permission denied** — should the kiosk allow PIN-only
   punching as a fallback, or hard-require a photo every time?
6. **Failed PIN attempts** — lock the kiosk out for a cooldown after N wrong
   PINs in a row (anti brute-force), in addition to the per-IP rate limit?
7. **Network outage at the kiosk** — out of scope for v1 (no offline queue),
   but flagging since a shared single device with no connectivity means *no
   one* can punch in until it's back — worth knowing going in.
8. **Breaks** — current schema only supports one check-in + one check-out
   per day; `break_duration_minutes` on `Shift` is informational only (not
   independently tracked). Multi-punch-per-day (lunch break out/in) is a
   larger feature — flagging as explicitly out of scope for v1 unless you
   want it now.
9. **Manual correction** — if a staff member forgets to punch out, should
   admins be able to edit/backfill a record from the Admin Attendance tab?
   Not in scope above; flagging since it's a near-certain real-world need.

## 7. Payroll & overtime calculation

Attendance records are only useful once they turn into pay. This section is
really the design for the future **Payroll** tab's calculation engine
(currently also just a placeholder), pulled forward now because it has to be
decided before attendance data is structured — retrofitting it later means
reprocessing every historical record.

### 7.1 Overtime — the basic rule

For a day where the staff member worked a **scheduled** shift (see §7.3 for
off-days):

```
scheduled_hours = Shift.durationHours − (Shift.break_duration_minutes / 60)
worked_hours    = check_out.recorded_at − check_in.recorded_at   (raw punch gap)
overtime_hours  = max(0, worked_hours − scheduled_hours − grace_period_minutes/60)
```

The existing `grace_period_minutes` on `Shift` (already used for the
late-arrival check) doubles as a buffer here too — a few minutes over
shouldn't count as billable overtime. `overtime_hours` then gets priced per
the staff member's `overtime_rate_type`/`overtime_custom_type`/
`overtime_custom_rate` (already built — see §7.2 for how that price is
derived when the staff member isn't paid hourly).

Note `worked_hours` is the raw check-in-to-check-out gap — it is **not**
reduced for breaks, because breaks aren't independently punched (flagged as
out of scope in §6, item 8 of the attendance doc above). If a shift has a
30-minute paid break baked into `scheduled_hours` but the staff member
actually took 45 minutes, that's currently invisible to this calculation.

### 7.2 Daily/Monthly staff — deriving an hourly-equivalent rate

`overtime_rate_type` values like `1.5x` assume there's a regular **hourly**
rate to multiply. That's direct for `salary_type = Hourly`
(`salary_rate` IS the hourly rate), but `Daily` and `Monthly` staff don't
have one stored — it has to be derived:

```
Daily:    hourly_equivalent = salary_rate / scheduled_hours_for_that_shift
Monthly:  hourly_equivalent = (salary_rate × 12) / (52 × standard_hours_per_week)
```

The `Monthly` formula needs a "standard hours per week" number from
somewhere — there's no field for that today. Either add it to `Business`
(one setting, applies to all monthly staff) or to `Shift` (each shift
template declares its own standard week), and `Custom` + `fixed_rate`
sidesteps this entirely since it's already an absolute $/hr figure, not a
multiplier. **This needs a decision — see open question 10.**

### 7.3 Working on a scheduled off-day

`Shift.scheduled_days` defines which weekdays the shift normally runs. If a
staff member punches in on a day that isn't in their shift's
`scheduled_days` (e.g. working a Sunday on a Mon–Sat shift), that's a
fundamentally different case from regular overtime — in Australian hospitality
awards, weekend/public-holiday work typically carries its **own** penalty
rate, separate from (and often higher than) weekday overtime (indicatively:
Saturday ~1.25x, Sunday ~1.5x, public holiday ~2.5x under common awards —
exact figures depend on the applicable award/agreement and aren't something
this app should hard-code without confirming with you).

The current `overtime_rate_type` design has **one** rate per staff member,
which doesn't leave room for "this rate applies on weekdays, that rate
applies on Sundays." Attendance records would tag these hours with a new
`off_day` status (distinct from `overtime`) so they're at least visible and
reportable, but pricing them correctly needs a scope decision —
**see open question 11.**

### 7.4 Mid-month pay rate changes

`Staff.salary_rate` (and `overtime_rate_type`/`salary_type`) are single
mutable columns — editing them today just overwrites the value, with no
record of what it was before. For payroll run on a period that spans a rate
change, this silently applies the *current* rate to the *entire* period,
including days worked under the old rate.

The Create/Edit Staff screens already collect an "Effective From Date" for
compensation (`create_staff_screen.dart` has this field) — but it isn't
actually wired to anything: there's no history table, so that date is
currently captured and then has nowhere to go. Fixing this properly needs a
new table:

**`staff_compensation_history`**

| Column | Type | Notes |
|---|---|---|
| `id` | bigint | |
| `staff_id` | FK → staff | |
| `salary_type` | string | snapshot |
| `salary_rate` | decimal(10,2) | snapshot |
| `overtime_rate_type` / `overtime_custom_type` / `overtime_custom_rate` | | snapshot |
| `effective_from` | date | |
| `effective_to` | date, nullable | null = currently active; set when superseded |
| `created_at` | | |

Editing compensation on the Edit Staff screen would, instead of only
overwriting `Staff`'s columns, close out the currently-open history row
(`effective_to = new effective_from − 1 day`) and insert a new one. `Staff`
keeps its current columns too, kept in sync as a denormalized "latest value"
cache so existing reads (staff list, profile) don't need a join — only
payroll calculation reads the history table, picking whichever row's
`[effective_from, effective_to]` range contains each day being paid.

This is a real gap in what's already shipped, not just new scope for
attendance — worth fixing regardless of the kiosk feature's timeline.

## 8. Open questions — payroll & overtime

10. **Hourly-equivalent formula for Monthly staff** — where does "standard
    hours per week" live (a `Business`-level setting, or per-`Shift`), and
    what number should it default to?
11. **Off-day / weekend / public-holiday pay rate** — is one `overtime_rate_type`
    per staff member sufficient (off-days just reuse the normal OT rate), or
    does the business need separate weekday-OT vs Saturday vs Sunday vs
    public-holiday rates? This changes the `Staff` schema, not just
    attendance.
12. **Retroactive compensation edits** — if `staff_compensation_history` is
    added, can an admin backdate an `effective_from` to correct a mistake
    (e.g. forgot to raise a rate last month), and should that trigger
    recalculation of already-processed pay periods?
13. **Payroll period boundaries** — weekly, fortnightly, or calendar-month
    pay runs? Needed before "a pay period spanning a rate change" has a
    concrete meaning.
14. **Unpaid vs paid breaks** — does `break_duration_minutes` represent time
    that's deducted from pay (unpaid break) or already included in the
    shift's paid hours? Affects the `scheduled_hours` formula in §7.1.
15. **Daily staff & partial days** — if a `Daily`-rate staff member works a
    partial day (sick half-day, left early), are they paid the full daily
    rate regardless, or pro-rated by hours? Affects whether `hourly_equivalent`
    in §7.2 is ever used for *regular* (non-overtime) pay too.
16. **Overtime approval** — should overtime hours require admin sign-off
    before counting toward pay (common in hospitality to prevent
    self-authorized overtime), or is any punch past scheduled hours
    automatically payable?

## 9. Suggested phasing

1. Backend: `attendance_records` table, `punch`/`list` endpoints, PIN
   uniqueness constraint, rate limiting.
2. Flutter: Gate screen, camera capture, PIN pad, result screen (the
   kiosk-facing half — this is what staff use every day).
3. Flutter: Admin Attendance tab (list + filters) — the oversight half.
4. Backend: `staff_compensation_history` table + wiring the existing
   "Effective From Date" field to actually use it (§7.4) — independent of
   the kiosk work, but needed before any payroll math can be trusted.
5. Payroll calculation engine (§7) — blocked on open questions 10–16 above
   being answered, since each changes the schema or formula involved.
6. Revisit §6's open questions once the core attendance loop is confirmed
   working.
