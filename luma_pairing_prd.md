# Luma — Pairing Flow PRD
**Product:** Luma / Dinner Circle App
**Area:** Pairing Flow — End-to-End
**Status:** Draft
**Last updated:** March 2026

---

## 1. Overview

This document covers everything required to ship the pairing flow end-to-end: the agent tools Luma needs to call, the schema changes required to support them, and the exact state transitions each screen drives. It is scoped to the 9 screens defined in the pairing flow mockups.

The pairing flow begins when a host creates a dinner event and ends when guests submit post-dinner feedback. It is the core loop of the product.

---

## 2. Screens in Scope

| # | Screen | Trigger |
|---|--------|---------|
| 01 | Dinner Invite — Pending RSVP | `dinner_invite` notification |
| 02 | Waiting for Pairs | After accepting invite |
| 03 | Pair Revealed | `dinner_paired` notification + `now() >= reveal_at` |
| 04 | Waiting for Partner | After confirming, partner hasn't yet |
| 04b | Partner Declined | `match_cancelled` notification |
| 05 | Confirmed Dinner Detail | `match_confirmed` notification |
| 06 | Day-of Check In | User taps Check In chip on screen 05 |
| 07 | Attendance Report | Proactive prompt after `scheduled_date` |
| 08 | Feedback | After `report_attendance(attended: true)` |

---

## 3. State Machines

### 3.1 Dinner Event Status

```
draft → inviting → pairing → paired → in_progress → completed → cancelled
```

### 3.2 Match Status (`dinner_matches.status`)

```
pending → revealed → confirmed → completed
                  ↘ expired
                  ↘ cancelled
```

- **pending** — match created, before reveal window opens
- **revealed** — `now() >= reveal_at`, guests can see their pair
- **confirmed** — both guests have `confirmed = true`
- **completed** — dinner happened, attendance reported
- **expired** — `reporting_deadline` passed with no attendance reports
- **cancelled** — one or both guests declined after reveal

### 3.3 Guest State (`dinner_match_guests` per row)

```
confirmed: null/false → true
declined_at: null → timestamptz   (new column)
attended: null → true | false
```

### 3.4 Full State Matrix

| Scenario | Match status | Guest A confirmed | Guest B confirmed | What each sees |
|----------|-------------|-------------------|-------------------|----------------|
| Just paired, pre-reveal | `pending` | false | false | Countdown to reveal |
| Revealed, neither confirmed | `revealed` | false | false | Screen 03 — Pair Reveal |
| A confirms, B hasn't | `revealed` | true | false | A → Screen 04 (waiting). B → Screen 03 |
| Both confirm | `confirmed` | true | true | Screen 05 — Confirmed Detail |
| A declines | `cancelled` | declined_at set | — | A → skip/requeue msg. B → Screen 04b |
| Deadline passed, unreported | `expired` | null | null | Neutral, no flake impact |
| Both reported attended | `completed` | attended=true | attended=true | Screen 08 — Feedback |
| One no-show | `completed` | attended=true | attended=false | Flake score updates for no-show |

---

## 4. Schema Changes Required

### 4.1 `dinner_match_guests` — new columns

```sql
ALTER TABLE public.dinner_match_guests
  ADD COLUMN IF NOT EXISTS declined_at timestamptz,
  ADD COLUMN IF NOT EXISTS decline_reason text;
```

**Why:** The existing schema uses `confirmed = false` ambiguously — it means both "not yet confirmed" and "actively declined." These are very different states. `declined_at` being non-null is the unambiguous signal that a guest explicitly opted out, as distinct from simply not having responded yet. `decline_reason` is optional free text for future UX (e.g. "I'm sick", "scheduling conflict").

### 4.2 `dinner_events` — new columns

```sql
ALTER TABLE public.dinner_events
  ADD COLUMN IF NOT EXISTS checkin_open_hours  int NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS checkin_close_hours int NOT NULL DEFAULT 2;
```

**Why:** Check-in should only be active within a configurable window around `scheduled_date`. Default: opens 1 hour before, closes 2 hours after. This is enforced both client-side (disabling the chip) and server-side (RPC rejects out-of-window requests).

The `reveal_at` and `reporting_deadline` columns already exist from `20260212080000_dinner_auto_rotation.sql`. No changes needed there.

### 4.3 `dinner_matches` — status CHECK constraint update

The existing constraint does not include `revealed`. It needs to be updated to match the full state machine.

```sql
ALTER TABLE public.dinner_matches
  DROP CONSTRAINT IF EXISTS dinner_matches_status_check;

ALTER TABLE public.dinner_matches
  ADD CONSTRAINT dinner_matches_status_check
  CHECK (status IN (
    'pending', 'revealed', 'confirmed',
    'completed', 'expired', 'cancelled'
  ));
```

**Note:** This constraint was partially updated in `20260212080000` but `revealed` was not included. This migration corrects that.

### 4.4 New notification types

No schema change needed — `notification_type` is an unconstrained `text` column. But the following values must be handled by the client and all notification-routing logic:

| notification_type | When fired | Who receives it |
|---|---|---|
| `dinner_invite` | Host sends invites | Each invitee |
| `dinner_pending` | Guest accepts invite | Guest themselves |
| `dinner_paired` | Event status → `paired` | All accepted invitees |
| `match_confirmed` | Both guests confirm | Both guests in the match |
| `match_cancelled` | One guest declines | The other guest |
| `attendance_reminder` | Scheduled after `scheduled_date` | Both guests if attendance unreported |
| `feedback_prompt` | After `attended = true` | The guest who attended |

`match_cancelled` and `attendance_reminder` and `feedback_prompt` are new and must be added to the client's notification router.

### 4.5 New trigger: `on_match_guest_declined`

When a guest sets `declined_at`, the system needs to cancel the match, notify the partner, and optionally requeue the decliner.

```sql
CREATE OR REPLACE FUNCTION public.handle_match_guest_declined()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_partner_id      uuid;
  v_event_id        uuid;
  v_event_title     text;
  v_cancel_policy   varchar;
BEGIN
  -- Only fire when declined_at transitions from null to a timestamp
  IF TG_OP != 'UPDATE' THEN RETURN NEW; END IF;
  IF NEW.declined_at IS NULL OR OLD.declined_at IS NOT NULL THEN RETURN NEW; END IF;

  -- Cancel the match
  UPDATE public.dinner_matches
  SET status = 'cancelled', updated_at = now()
  WHERE id = NEW.match_id AND status NOT IN ('cancelled', 'completed', 'expired');

  -- Find partner and event info
  SELECT dmg.user_id INTO v_partner_id
  FROM public.dinner_match_guests dmg
  WHERE dmg.match_id = NEW.match_id AND dmg.user_id != NEW.user_id
  LIMIT 1;

  SELECT de.id, de.title, de.cancellation_policy
  INTO v_event_id, v_event_title, v_cancel_policy
  FROM public.dinner_matches dm
  JOIN public.dinner_events de ON de.id = dm.dinner_event_id
  WHERE dm.id = NEW.match_id;

  -- Notify the partner
  IF v_partner_id IS NOT NULL THEN
    INSERT INTO public.notifications
      (user_id, title, body, notification_type, source_id, data)
    VALUES (
      v_partner_id,
      'Your dinner partner can''t make it',
      CASE v_cancel_policy
        WHEN 'requeue' THEN 'You''ve been re-added to the pool for ' || COALESCE(v_event_title, 'your dinner') || '.'
        ELSE 'This round has closed. You''ll be matched in the next cycle.'
      END,
      'match_cancelled',
      v_event_id,
      jsonb_build_object(
        'dinner_event_id', v_event_id,
        'match_id', NEW.match_id,
        'cancellation_policy', v_cancel_policy
      )
    );
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_match_guest_declined ON public.dinner_match_guests;

CREATE TRIGGER on_match_guest_declined
  AFTER UPDATE ON public.dinner_match_guests
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_match_guest_declined();
```

### 4.6 New trigger: `on_match_status_revealed`

Automatically transition match status from `pending` → `revealed` when `now() >= reveal_at`. This is driven by a scheduled job calling the helper below, or lazily on read.

```sql
CREATE OR REPLACE FUNCTION public.reveal_due_matches()
RETURNS int
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  updated_count int;
BEGIN
  WITH revealed AS (
    UPDATE public.dinner_matches
    SET status = 'revealed', updated_at = now()
    WHERE status = 'pending'
      AND reveal_at IS NOT NULL
      AND reveal_at <= now()
    RETURNING id
  )
  SELECT count(*) INTO updated_count FROM revealed;
  RETURN updated_count;
END;
$$;
```

Call this via Supabase pg_cron or from the client on app foreground.

### 4.7 New trigger: `on_attendance_reported` — feedback prompt notification

After attendance is confirmed, fire a `feedback_prompt` notification so Luma can surface Screen 08.

```sql
-- Extend handle_attendance_tracking() to also fire feedback_prompt notification
-- Add after the dinners_attended increment block:

IF NEW.attended = true AND (OLD.attended IS NULL OR OLD.attended = false) THEN
  -- existing: increment dinners_attended
  -- new: fire feedback_prompt notification
  INSERT INTO public.notifications
    (user_id, title, body, notification_type, source_id, data)
  SELECT
    NEW.user_id,
    'How was your dinner?',
    'Share a quick note about your evening.',
    'feedback_prompt',
    dm.dinner_event_id,
    jsonb_build_object(
      'match_id', NEW.match_id,
      'dinner_event_id', dm.dinner_event_id
    )
  FROM public.dinner_matches dm
  WHERE dm.id = NEW.match_id;
END IF;
```

This should be folded into the existing `handle_attendance_tracking` function in a new migration.

---

## 5. Tool Definitions

Each tool maps to an agent action Luma can invoke. All tools are SECURITY DEFINER RPCs callable by the authenticated role unless noted.

---

### 5.1 `get_dinner_invite`

**Screen:** 01 — Pending RSVP

| Field | Value |
|---|---|
| **Purpose** | Fetch a single dinner invite with full event context for display |
| **Input** | `p_invite_id uuid`, `p_viewer_user_id uuid` |
| **Returns** | JSON: invite row + event (title, date, venue, circle name) + accepted count + avatar list |
| **Auth** | Caller must be the invitee or the host |
| **Backed by** | SELECT on `dinner_invites` JOIN `dinner_events` JOIN `dinner_invites` (count) |

```sql
CREATE OR REPLACE FUNCTION public.get_dinner_invite(
  p_invite_id      uuid,
  p_viewer_user_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_result jsonb;
BEGIN
  SELECT jsonb_build_object(
    'invite_id',       di.id,
    'status',          di.status,
    'dinner_event_id', di.dinner_event_id,
    'event_title',     de.title,
    'scheduled_date',  de.scheduled_date,
    'venue',           de.venue,
    'venue_address',   de.venue_address,
    'circle_name',     g.groupname,
    'host_id',         de.host_id,
    'accepted_count', (
      SELECT count(*) FROM public.dinner_invites
      WHERE dinner_event_id = de.id AND status = 'accepted'
    ),
    'accepted_avatars', (
      SELECT COALESCE(jsonb_agg(jsonb_build_object(
        'user_id', up.userid,
        'first_name', up.first_name,
        'profile_photo_path', up.profile_photo_path
      )) FILTER (WHERE up.userid IS NOT NULL), '[]'::jsonb)
      FROM public.dinner_invites di2
      JOIN public.user_profiles up ON up.userid = di2.invitee_id
      WHERE di2.dinner_event_id = de.id AND di2.status = 'accepted'
      LIMIT 5
    )
  )
  INTO v_result
  FROM public.dinner_invites di
  JOIN public.dinner_events de ON de.id = di.dinner_event_id
  JOIN public.groups g ON g.groupid = de.circle_id
  WHERE di.id = p_invite_id
    AND (di.invitee_id = p_viewer_user_id OR de.host_id = p_viewer_user_id);

  RETURN v_result;
END;
$$;
```

---

### 5.2 `respond_to_dinner_invite`

**Screen:** 01 → 02 (accept) or exit flow (decline)

| Field | Value |
|---|---|
| **Purpose** | Accept or decline a dinner invite |
| **Input** | `p_invite_id uuid`, `p_user_id uuid`, `p_response text` — `'accepted'` or `'declined'` |
| **Returns** | `{ invite_id, status, dinner_event_id }` |
| **Auth** | Caller must be the invitee |
| **Side effects** | UPDATE `dinner_invites` → triggers `on_dinner_invite_changed` → fires `dinner_pending` notification on accept |

This RPC already exists implicitly via direct table UPDATE + the trigger. Wrap in an explicit RPC for:
- Input validation (reject invalid statuses)
- Guard: cannot accept after `scheduled_date` has passed
- Returns enough context for Luma to transition the conversation state

```sql
CREATE OR REPLACE FUNCTION public.respond_to_dinner_invite(
  p_invite_id uuid,
  p_user_id   uuid,
  p_response  text  -- 'accepted' | 'declined'
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_invite  public.dinner_invites;
  v_event   public.dinner_events;
BEGIN
  IF p_response NOT IN ('accepted', 'declined') THEN
    RETURN jsonb_build_object('error', 'invalid_response');
  END IF;

  SELECT * INTO v_invite FROM public.dinner_invites
  WHERE id = p_invite_id AND invitee_id = p_user_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'not_found');
  END IF;

  SELECT * INTO v_event FROM public.dinner_events WHERE id = v_invite.dinner_event_id;

  IF v_event.scheduled_date IS NOT NULL AND v_event.scheduled_date < now() THEN
    RETURN jsonb_build_object('error', 'event_passed');
  END IF;

  IF v_invite.status != 'pending' THEN
    RETURN jsonb_build_object('error', 'already_responded', 'current_status', v_invite.status);
  END IF;

  UPDATE public.dinner_invites
  SET status = p_response, responded_at = now()
  WHERE id = p_invite_id;

  RETURN jsonb_build_object(
    'invite_id',       p_invite_id,
    'status',          p_response,
    'dinner_event_id', v_invite.dinner_event_id
  );
END;
$$;
```

---

### 5.3 `get_dinner_event_for_guest`

**Screen:** 02 — Waiting, 05 — Confirmed Detail

| Field | Value |
|---|---|
| **Purpose** | Full event view from a guest's perspective — invite status, match if one exists, partner details (reveal-gated), check-in eligibility |
| **Input** | `p_dinner_event_id uuid`, `p_viewer_user_id uuid` |
| **Returns** | Full JSON blob — see structure below |
| **Auth** | Caller must have an accepted invite for this event OR be the host |
| **Reveal gating** | Partner identity fields are `null` if `now() < match.reveal_at` |

**Return structure:**

```json
{
  "event": {
    "id", "title", "scheduled_date", "venue", "venue_address",
    "venue_lat", "venue_lng", "status", "circle_name",
    "reporting_deadline", "checkin_open_hours", "checkin_close_hours"
  },
  "invite": { "id", "status" },
  "match": {
    "id", "status", "reveal_at", "revealed",
    "my_confirmed", "my_declined_at",
    "partner": {
      "user_id", "first_name",
      "last_name",          // null if not yet revealed
      "profile_photo_path",
      "occupation",
      "bio",
      "shared_interests"    // intersect of both users' interests[]
    },
    "partner_confirmed"
  },
  "checkin": {
    "eligible",             // bool: now() within window
    "my_checked_in",
    "partner_checked_in",
    "window_opens_at",
    "window_closes_at"
  },
  "feedback_submitted": false
}
```

This is the primary data-loading tool for Screens 04, 04b, and 05. Luma calls it on load and after any state-changing action.

---

### 5.4 `confirm_match_guest`

**Screen:** 03 → 04

| Field | Value |
|---|---|
| **Purpose** | Guest confirms they will attend their paired dinner |
| **Input** | `p_match_id uuid`, `p_user_id uuid` |
| **Returns** | `{ match_id, match_status, all_confirmed }` |
| **Auth** | Caller must be a guest in this match |
| **Side effects** | UPDATE `dinner_match_guests.confirmed = true`, `confirmed_at = now()`. If both guests now confirmed, `handle_match_guest_confirmed` trigger fires → match status → `confirmed` → `match_confirmed` notification to both. |

```sql
CREATE OR REPLACE FUNCTION public.confirm_match_guest(
  p_match_id uuid,
  p_user_id  uuid
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_status      text;
  v_all_confirmed boolean;
BEGIN
  -- Guard: must be a guest in this match
  IF NOT EXISTS (
    SELECT 1 FROM public.dinner_match_guests
    WHERE match_id = p_match_id AND user_id = p_user_id
  ) THEN
    RETURN jsonb_build_object('error', 'not_a_guest');
  END IF;

  -- Guard: cannot confirm if already declined
  IF EXISTS (
    SELECT 1 FROM public.dinner_match_guests
    WHERE match_id = p_match_id AND user_id = p_user_id
      AND declined_at IS NOT NULL
  ) THEN
    RETURN jsonb_build_object('error', 'already_declined');
  END IF;

  UPDATE public.dinner_match_guests
  SET confirmed = true, confirmed_at = now()
  WHERE match_id = p_match_id AND user_id = p_user_id;

  SELECT status INTO v_status FROM public.dinner_matches WHERE id = p_match_id;
  SELECT bool_and(confirmed) INTO v_all_confirmed
  FROM public.dinner_match_guests WHERE match_id = p_match_id;

  RETURN jsonb_build_object(
    'match_id',      p_match_id,
    'match_status',  v_status,
    'all_confirmed', v_all_confirmed
  );
END;
$$;
```

---

### 5.5 `decline_match_guest`

**Screen:** 03 or 04 → exit / requeue

| Field | Value |
|---|---|
| **Purpose** | Guest opts out of their assigned match after reveal |
| **Input** | `p_match_id uuid`, `p_user_id uuid`, `p_reason text` (optional) |
| **Returns** | `{ match_id, cancellation_policy, requeued }` |
| **Auth** | Caller must be a guest in this match |
| **Side effects** | Sets `declined_at` on the guest row → triggers `on_match_guest_declined` → cancels match → notifies partner. If `cancellation_policy = 'requeue'`, guest's invite status is set back to `'accepted'` so they can be re-paired. |

```sql
CREATE OR REPLACE FUNCTION public.decline_match_guest(
  p_match_id uuid,
  p_user_id  uuid,
  p_reason   text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_policy  varchar;
  v_event_id uuid;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.dinner_match_guests
    WHERE match_id = p_match_id AND user_id = p_user_id
  ) THEN
    RETURN jsonb_build_object('error', 'not_a_guest');
  END IF;

  -- Get cancellation policy
  SELECT de.cancellation_policy, de.id
  INTO v_policy, v_event_id
  FROM public.dinner_matches dm
  JOIN public.dinner_events de ON de.id = dm.dinner_event_id
  WHERE dm.id = p_match_id;

  -- Set declined_at (triggers on_match_guest_declined)
  UPDATE public.dinner_match_guests
  SET declined_at = now(), decline_reason = p_reason
  WHERE match_id = p_match_id AND user_id = p_user_id;

  -- If requeue policy, put them back in the pool
  IF v_policy = 'requeue' THEN
    UPDATE public.dinner_invites
    SET status = 'accepted'
    WHERE dinner_event_id = v_event_id
      AND invitee_id = p_user_id
      AND status = 'accepted';
    -- (status stays accepted — they simply have no active match now)
  END IF;

  RETURN jsonb_build_object(
    'match_id',            p_match_id,
    'cancellation_policy', v_policy,
    'requeued',            v_policy = 'requeue'
  );
END;
$$;
```

---

### 5.6 `check_in_to_dinner`

**Screen:** 06 — Day-of Check In

| Field | Value |
|---|---|
| **Purpose** | Record guest check-in with proximity validation |
| **Input** | `p_match_id uuid`, `p_user_id uuid`, `p_latitude float8`, `p_longitude float8` |
| **Returns** | `{ checked_in, distance_meters, partner_checked_in }` or `{ error: 'too_far' \| 'window_closed' \| 'not_a_guest' }` |
| **Auth** | Caller must be a guest in this match |
| **Side effects** | INSERT into `dinner_check_ins`. On first check-in, optionally notify partner. |

**Proximity check:** Uses Haversine formula to validate the guest is within 500m of `dinner_events.venue_lat/venue_lng`. This threshold should be configurable — add to `dinner_events` or keep as a constant in the function.

**Window check:** Validates `now()` is within `scheduled_date - checkin_open_hours` to `scheduled_date + checkin_close_hours`.

```sql
CREATE OR REPLACE FUNCTION public.check_in_to_dinner(
  p_match_id  uuid,
  p_user_id   uuid,
  p_latitude  double precision,
  p_longitude double precision
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_event           public.dinner_events;
  v_distance_m      float8;
  v_window_open     timestamptz;
  v_window_close    timestamptz;
  v_partner_checkin boolean;
  v_threshold_m     float8 := 500.0;
BEGIN
  -- Verify guest
  IF NOT EXISTS (
    SELECT 1 FROM public.dinner_match_guests
    WHERE match_id = p_match_id AND user_id = p_user_id
  ) THEN
    RETURN jsonb_build_object('error', 'not_a_guest');
  END IF;

  -- Get event
  SELECT de.* INTO v_event
  FROM public.dinner_matches dm
  JOIN public.dinner_events de ON de.id = dm.dinner_event_id
  WHERE dm.id = p_match_id;

  -- Check window
  v_window_open  := v_event.scheduled_date - (v_event.checkin_open_hours  || ' hours')::interval;
  v_window_close := v_event.scheduled_date + (v_event.checkin_close_hours || ' hours')::interval;

  IF now() < v_window_open OR now() > v_window_close THEN
    RETURN jsonb_build_object(
      'error',          'window_closed',
      'window_opens_at', v_window_open,
      'window_closes_at', v_window_close
    );
  END IF;

  -- Haversine distance (metres)
  IF v_event.venue_lat IS NOT NULL AND v_event.venue_lng IS NOT NULL THEN
    v_distance_m := 6371000 * acos(
      cos(radians(v_event.venue_lat)) * cos(radians(p_latitude)) *
      cos(radians(p_longitude) - radians(v_event.venue_lng)) +
      sin(radians(v_event.venue_lat)) * sin(radians(p_latitude))
    );

    IF v_distance_m > v_threshold_m THEN
      RETURN jsonb_build_object('error', 'too_far', 'distance_meters', round(v_distance_m));
    END IF;
  END IF;

  -- Insert (or no-op if already checked in)
  INSERT INTO public.dinner_check_ins (match_id, user_id, latitude, longitude)
  VALUES (p_match_id, p_user_id, p_latitude, p_longitude)
  ON CONFLICT (match_id, user_id) DO NOTHING;

  -- Partner check-in status
  SELECT EXISTS (
    SELECT 1 FROM public.dinner_check_ins dci
    JOIN public.dinner_match_guests dmg ON dmg.user_id = dci.user_id
    WHERE dci.match_id = p_match_id AND dci.user_id != p_user_id
  ) INTO v_partner_checkin;

  RETURN jsonb_build_object(
    'checked_in',         true,
    'distance_meters',    round(COALESCE(v_distance_m, 0)),
    'partner_checked_in', v_partner_checkin
  );
END;
$$;
```

---

### 5.7 `report_attendance`

**Screen:** 07 — Attendance Report

| Field | Value |
|---|---|
| **Purpose** | Guest self-reports whether they attended the dinner |
| **Input** | `p_match_id uuid`, `p_user_id uuid`, `p_attended boolean` |
| **Returns** | `{ match_id, attended, reported_at, deadline_passed }` or `{ error: 'deadline_passed' \| 'not_a_guest' }` |
| **Auth** | Caller must be a guest in this match |
| **Side effects** | UPDATE `dinner_match_guests.attended`, `reported_at`. Triggers `on_attendance_tracked` → increments `dinners_attended` if `true`. If both guests reported, match status → `completed`. Fires `feedback_prompt` notification if attended. |

```sql
CREATE OR REPLACE FUNCTION public.report_attendance(
  p_match_id  uuid,
  p_user_id   uuid,
  p_attended  boolean
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_deadline  timestamptz;
  v_now       timestamptz := now();
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.dinner_match_guests
    WHERE match_id = p_match_id AND user_id = p_user_id
  ) THEN
    RETURN jsonb_build_object('error', 'not_a_guest');
  END IF;

  -- Check reporting deadline
  SELECT de.reporting_deadline INTO v_deadline
  FROM public.dinner_matches dm
  JOIN public.dinner_events de ON de.id = dm.dinner_event_id
  WHERE dm.id = p_match_id;

  IF v_deadline IS NOT NULL AND v_now > v_deadline THEN
    RETURN jsonb_build_object('error', 'deadline_passed', 'deadline', v_deadline);
  END IF;

  UPDATE public.dinner_match_guests
  SET attended = p_attended, reported_at = v_now
  WHERE match_id = p_match_id AND user_id = p_user_id;

  -- If both guests have reported, mark match completed
  IF (SELECT bool_and(attended IS NOT NULL) FROM public.dinner_match_guests WHERE match_id = p_match_id) THEN
    UPDATE public.dinner_matches
    SET status = 'completed', updated_at = v_now
    WHERE id = p_match_id AND status NOT IN ('completed', 'cancelled', 'expired');
  END IF;

  RETURN jsonb_build_object(
    'match_id',    p_match_id,
    'attended',    p_attended,
    'reported_at', v_now
  );
END;
$$;
```

---

### 5.8 `submit_dinner_feedback`

**Screen:** 08 — Feedback

| Field | Value |
|---|---|
| **Purpose** | Submit post-dinner rating, tags, notes, and optional photos |
| **Input** | `p_dinner_event_id uuid`, `p_match_id uuid`, `p_user_id uuid`, `p_star_rating int`, `p_quick_tags text[]`, `p_tell_us_more text`, `p_photo_paths text[]` |
| **Returns** | `{ feedback_id }` |
| **Auth** | Caller must have attended the dinner (`attended = true`) |
| **Guards** | Cannot submit twice (UNIQUE constraint on `dinner_feedback(dinner_event_id, user_id)`) |

```sql
CREATE OR REPLACE FUNCTION public.submit_dinner_feedback(
  p_dinner_event_id uuid,
  p_match_id        uuid,
  p_user_id         uuid,
  p_star_rating     int,
  p_quick_tags      text[]  DEFAULT '{}',
  p_tell_us_more    text    DEFAULT NULL,
  p_photo_paths     text[]  DEFAULT '{}'
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_feedback_id uuid;
BEGIN
  -- Guard: must have attended
  IF NOT EXISTS (
    SELECT 1 FROM public.dinner_match_guests
    WHERE match_id = p_match_id AND user_id = p_user_id AND attended = true
  ) THEN
    RETURN jsonb_build_object('error', 'attendance_not_confirmed');
  END IF;

  IF p_star_rating < 1 OR p_star_rating > 5 THEN
    RETURN jsonb_build_object('error', 'invalid_rating');
  END IF;

  INSERT INTO public.dinner_feedback
    (dinner_event_id, match_id, user_id, star_rating, quick_tags, tell_us_more, photo_paths)
  VALUES
    (p_dinner_event_id, p_match_id, p_user_id, p_star_rating, p_quick_tags, p_tell_us_more, p_photo_paths)
  ON CONFLICT (dinner_event_id, user_id) DO UPDATE SET
    star_rating   = EXCLUDED.star_rating,
    quick_tags    = EXCLUDED.quick_tags,
    tell_us_more  = EXCLUDED.tell_us_more,
    photo_paths   = EXCLUDED.photo_paths
  RETURNING id INTO v_feedback_id;

  RETURN jsonb_build_object('feedback_id', v_feedback_id);
END;
$$;
```

---

### 5.9 `get_match_detail`

**Screens:** 03, 04, 04b, 05, 06

| Field | Value |
|---|---|
| **Purpose** | Load full match state for Luma to render the correct screen. Single source of truth for all match-related screens. |
| **Input** | `p_match_id uuid`, `p_viewer_user_id uuid` |
| **Returns** | Full match JSON — see structure below |
| **Auth** | Caller must be a guest in this match OR the host |
| **Reveal gating** | `partner.last_name`, `partner.bio`, `partner.occupation` are `null` if `now() < reveal_at` AND match is not `confirmed` |

**Return structure:**

```json
{
  "match": {
    "id", "status", "reveal_at", "revealed",
    "created_at", "updated_at"
  },
  "event": {
    "id", "title", "scheduled_date", "venue",
    "venue_address", "venue_lat", "venue_lng",
    "reporting_deadline", "cancellation_policy",
    "checkin_window_opens_at", "checkin_window_closes_at"
  },
  "circle": { "id", "name" },
  "me": {
    "confirmed", "confirmed_at", "declined_at",
    "attended", "reported_at", "checked_in"
  },
  "partner": {
    "user_id", "first_name",
    "last_name",             // null pre-reveal or pre-confirm
    "profile_photo_path",
    "occupation",            // null pre-reveal
    "bio",                   // null pre-reveal
    "interests",
    "shared_interests",
    "confirmed",
    "declined_at",
    "checked_in"
  },
  "feedback_submitted": false
}
```

---

### 5.10 `format_calendar_event` (client-side only — no RPC needed)

**Screen:** 05 — Confirmed Detail, "Add to Calendar" chip

This is not a Supabase tool. Luma returns a structured payload and the Flutter app invokes the platform calendar API.

**Payload Luma returns:**

```json
{
  "title": "Dinner · Rec Center Ballers",
  "start_iso": "2026-03-19T19:30:00",
  "end_iso": "2026-03-19T21:30:00",
  "location": "Spoon & Stable, 211 N 1st St, Minneapolis, MN 55401",
  "notes": "Your dinner partner: Priya. Organized by Rec Center Ballers on Luma.",
  "url": "luma://dinner/{dinner_event_id}"
}
```

The app uses `add_2_calendar` (Flutter package) or platform intent. No server round-trip.

---

## 6. RLS Policies Required

### 6.1 `dinner_match_guests` — UPDATE for declined_at

The existing UPDATE policy `"User can update own match guest entry"` already uses `user_id = auth.uid()`, which covers the `declined_at` update. No new policy needed.

### 6.2 `dinner_check_ins` — SELECT for partner status

Screen 06 needs to show whether the partner has checked in. The existing `"User can view own check-ins"` policy only shows the caller's own rows. Add:

```sql
CREATE POLICY "Guests can view co-match check-ins"
  ON public.dinner_check_ins FOR SELECT
  USING (
    match_id IN (
      SELECT match_id FROM public.dinner_match_guests
      WHERE user_id = auth.uid()
    )
  );
```

This replaces the existing `"User can view own check-ins"` policy which is too restrictive.

### 6.3 `dinner_feedback` — SELECT for host aggregate view

Already exists in the base migration. No change needed.

---

## 7. Migration Sequence

These migrations should be applied in order:

| # | File name | What it does |
|---|-----------|-------------|
| 1 | `_add_match_guest_decline_columns.sql` | Adds `declined_at`, `decline_reason` to `dinner_match_guests` |
| 2 | `_add_checkin_window_columns.sql` | Adds `checkin_open_hours`, `checkin_close_hours` to `dinner_events` |
| 3 | `_fix_match_status_constraint.sql` | Adds `revealed` to `dinner_matches` status CHECK |
| 4 | `_handle_match_guest_declined_trigger.sql` | New trigger on `dinner_match_guests` for `declined_at` |
| 5 | `_reveal_due_matches_function.sql` | Scheduled helper to flip `pending → revealed` |
| 6 | `_feedback_prompt_notification.sql` | Extends `handle_attendance_tracking` to fire `feedback_prompt` |
| 7 | `_fix_checkin_rls.sql` | Updates check-in SELECT policy for co-match visibility |
| 8 | `_pairing_rpcs.sql` | All 9 RPCs from Section 5 in a single migration |

---

## 8. Tool → Screen Mapping

| Screen | Tools Called | Direction |
|--------|-------------|-----------|
| 01 — Pending Invite | `get_dinner_invite` | Load |
| 01 — Accept/Decline | `respond_to_dinner_invite` | Action |
| 02 — Waiting | `get_dinner_event_for_guest` | Load (polling or realtime) |
| 03 — Pair Revealed | `get_match_detail` | Load |
| 03 — Confirm | `confirm_match_guest` | Action |
| 03 — Decline | `decline_match_guest` | Action |
| 04 — Waiting for Partner | `get_match_detail` | Load (realtime sub) |
| 04 — Cancel spot | `decline_match_guest` | Action |
| 04b — Partner Declined | `get_match_detail` | Load (pushed via notification) |
| 04b — Keep me in / Skip | `respond_to_dinner_invite` (re-accept) or no-op | Action |
| 05 — Confirmed Detail | `get_match_detail` | Load |
| 05 — Add to Calendar | `format_calendar_event` (client only) | Action |
| 05 — Can't go | `decline_match_guest` | Action |
| 06 — Check In | `check_in_to_dinner` | Action |
| 06 — Partner status | `get_match_detail` (realtime sub on `dinner_check_ins`) | Load |
| 07 — Attendance Report | `report_attendance` | Action |
| 08 — Feedback | `submit_dinner_feedback` | Action |

---

## 9. Realtime Subscriptions

Luma needs Supabase Realtime subscriptions on the following tables to push state changes without polling:

| Table | Event | Purpose |
|---|---|---|
| `dinner_match_guests` | UPDATE on `confirmed` | Screen 04: detect when partner confirms → transition to Screen 05 |
| `dinner_match_guests` | UPDATE on `declined_at` | Screen 04: detect when partner declines → transition to Screen 04b |
| `dinner_check_ins` | INSERT | Screen 06: show partner check-in status live |
| `notifications` | INSERT | All screens: surface new notifications inline in conversation |

RLS on all these tables already restricts subscription events to rows the user owns or is a guest on. The check-in policy change in Section 6.2 is required for the `dinner_check_ins` subscription to work correctly.

---

## 10. Open Questions

| # | Question | Owner | Notes |
|---|----------|-------|-------|
| 1 | Should `decline_match_guest` be allowed after `match_confirmed`? Currently yes, with flake score impact. Should there be a late-cancel grace period? | Product | Affects flake score calculation |
| 2 | Proximity threshold for check-in is hardcoded at 500m. Should this be per-event or per-circle? | Product | Some venues (outdoor festivals, parks) may need a larger radius |
| 3 | Should `reveal_at` be mandatory or optional? If null, pairs are visible immediately on creation. | Product | Current schema allows null |
| 4 | `feedback_prompt` notification: should it be sent even if `attended = false`? Could be useful for asking why. | Product | Currently only fires on `attended = true` |
| 5 | `get_match_detail` reveals `partner.last_name` only after `match_confirmed`. Is first-name-only sufficient until both confirm, or should full name reveal on `revealed` status? | Product | Privacy tradeoff |
| 6 | Attendance reminder notification scheduling — this requires pg_cron or an external scheduler. Where does this live? | Eng | Not covered in this PRD |
