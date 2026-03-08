# agents.md — Luma

## Problem Statement

Coordinating recurring social dinners is unnecessarily hard. Group chats fall apart, people drop out, and no one wants to be the one always organising. The result is that people with genuine intent to connect end up not connecting.

## Solution

Luma is a conversational dinner-circle app. Users join small, recurring groups called **circles** — a trusted set of people who commit to dining together regularly. A built-in AI agent (also called Luma) handles the coordination: inviting members, pairing them for one-on-one or small-group dinners, managing confirmations, and following up after the fact. The user never has to navigate a traditional interface — everything happens through natural conversation with Luma.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile | Flutter |
| Backend | Supabase (PostgreSQL, Auth, Realtime, Storage) |
| AI Agent | Anthropic Claude |
| Push Notifications | Firebase Cloud Messaging |
| SMS | Twilio |

---

## Project Structure

```
lib/
├── agent/          # Luma AI agent — tool definitions, conversation state, message handling
├── models/         # Data models (User, Circle, DinnerEvent, Match, etc.)
├── screens/        # UI screens organised by feature
├── services/       # Supabase client, FCM, Twilio, Anthropic API wrappers
├── widgets/        # Shared UI components
├── styles/         # app_colors.dart, dimensions.dart, text_styles.dart
├── strings.dart    # All user-facing text strings — never write strings inline
└── main.dart

supabase/
└── migrations/     # PostgreSQL migrations in chronological order

docs/
├── database/       # Database schema documentation and design decisions
├── features/       # agents.md, prompt.md, feature_list.md
└── progress.txt    # Running log of agent and engineer activity
```

---

## Coding Rules

### Styles
- Always reference `app_colors.dart`, `dimensions.dart`, and `text_styles.dart` for all colors, spacing, and typography.
- Never write inline colors, hardcoded dimensions, or inline text styles. Create or extend the style files first, then reference them.

### Strings
- All user-facing text lives in `strings.dart`. Never write text strings inline in widgets.

### Logging
- Never use `debugPrint`. Always use the project logging system.

### Tests
- We do not write widget or unit tests for this project.

### Database — CRITICAL

Production and development share the same Supabase instance. There is no backup.

**Never run:**
- `supabase db reset`
- `supabase db push --reset`
- Any SQL that drops tables, truncates data, or bulk-deletes records without explicit user confirmation

**Safe operations:**
- `supabase db push --include-all`
- `supabase db diff`
- `supabase migration new`
- Additive migrations only (new tables, columns, indexes)

**Before any database operation:**
1. Confirm with the user before running any database command
2. Double-check the command does not include `reset` or destructive flags
3. Always prefer `--include-all` when pushing migrations

**Migrations:**
- New migrations go in `supabase/migrations/`
- Meaningful schema changes must be documented in `docs/database/`
- Think about future bugs, tech debt, and subtle design decisions when documenting

---

## Git Workflow

We use **git flow**. Always create a feature branch before starting work.

### Branch Model
- `main` — production releases only
- `develop` — integration branch; features merge here
- `feature/*` — individual feature work, branched from `develop`
- `release/*` — release candidates branched from `develop`, merged into `main` and back into `develop`

### Commit Convention
Use [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/#summary):
```
feat(circles): add invite code entry flow
fix(pairing): resolve match status stuck on pending
chore(deps): upgrade supabase_flutter to 2.x
```

### Pull Requests
When a feature is complete, push the branch and open a PR against `develop`. Do not merge your own PR.

---

## Feature Completion Protocol

1. **Confirm first** — wait for explicit user confirmation before marking a feature complete.
2. **Update feature_list.md** — set `is_complete: true` for the relevant feature(s).
3. **Update progress.txt** — append a log entry describing what was done.
4. **Commit and push** — commit all changes including doc updates, then push the feature branch.

---

## UI References

Mockups are in `mockups/` organised by feature area. Always refer to these when implementing screens. Do not deviate from the design system without checking first.

```
mockups/
├── onboarding/
├── auth/
├── home/
├── circles/
├── dinner/
├── pairing/
├── profile/
└── notifications/
```

---
## UI Architecture — Conversation Shell Model

Luma does not use a traditional screen-per-route navigation model. There is one root shell — the Luma conversation screen — and almost all user interactions happen within it by swapping contextual widgets into the conversation feed based on state.

Do not create new screens for pairing flow states, dinner flow states, or any interaction that is a response to a Luma agent message. Build a new widget and inject it into the feed.

**True separate screens** (have their own routes):
- Circle Detail
- Profile
- Settings
- Notification tray

**Everything else** is a widget rendered inside the conversation shell:
- Dinner invite card
- Pair reveal card
- Waiting for partner state
- Confirmed dinner detail card
- Check-in widget
- Attendance report prompt
- Feedback form
- Circle found card
- Create circle preview card

When in doubt: if Luma would "say" something and show it, it's a widget in the feed. If the user navigates to it independently, it's a screen.

---

## Architecture

Refer to `architecture.md` before making structural changes. When working on a new feature, read the architecture guide first. When editing existing code, follow the established patterns — do not introduce new patterns without discussion.

---

## progress.txt

`docs/progress.txt` is a running log of what agents and engineers have done. Always append — never overwrite. Be specific at a high level so the next agent or engineer can get up to speed quickly.

Example entry format:
```
[2026-03-06] Implemented confirm_match_guest RPC and wired up Screen 03 (Pair Reveal) in Flutter.
- Created supabase/migrations/20260306_confirm_match_guest.sql
- Updated lib/services/pairing_service.dart with confirmMatchGuest() method
- Updated lib/screens/pairing/pair_reveal_screen.dart to call service and handle both branches
- Marked PAIR-03 as complete in feature_list.md
```

---

## Coding Conventions — Examples

### Styles — Colors, Dimensions, Text

Never write inline colors, sizes, or text styles. Always reference the style files.

**❌ Wrong**
```dart
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: const Color(0xFFB8976A),
    borderRadius: BorderRadius.circular(20),
  ),
  child: Text(
    'Confirm',
    style: TextStyle(fontSize: 14, color: Colors.white),
  ),
)
```

**✅ Correct** — add to style files first, then reference
```dart
Container(
  padding: Dimensions.cardPadding,
  decoration: BoxDecoration(
    color: AppColors.gold,
    borderRadius: BorderRadius.circular(Dimensions.radiusLg),
  ),
  child: Text(
    Strings.confirmCta,
    style: AppTextStyles.buttonPrimary,
  ),
)
```

---

### Strings

Never write user-facing text inline in a widget. Add to `strings.dart` first.

**❌ Wrong**
```dart
Text("Your dinner partner can't make it this time.")
LumaMessage(text: "You're both confirmed! See you Thursday.")
```

**✅ Correct**
```dart
// 1. Add to strings.dart first
static const String partnerDeclined = "Your dinner partner can't make it this time.";
static const String bothConfirmedMessage = "You're both confirmed! See you Thursday.";

// 2. Reference in the widget
Text(Strings.partnerDeclined)
LumaMessage(text: Strings.bothConfirmedMessage)
```

---

### Logging

**❌ Wrong**
```dart
debugPrint('confirm match failed: $e');
print('matchId: $matchId');
```

**✅ Correct**
```dart
AppLogger.info('Match confirmed', data: {'matchId': matchId});
AppLogger.error('Failed to confirm match', error: e, stackTrace: st);
```

---

### Conventional Commits

Use the format: `type(scope): description`

| Type | When to use |
|------|-------------|
| `feat` | New feature or new UI |
| `fix` | Bug fix |
| `chore` | Dependency updates, config, tooling |
| `refactor` | Code change with no behaviour change |
| `docs` | Documentation only |
| `style` | Formatting, whitespace — no logic change |

**Examples**
```
feat(pairing): implement pair reveal card and confirm match flow
feat(circles): add create circle conversational wizard
fix(pairing): resolve match status stuck on pending after both confirm
fix(notifications): correct routing for match_cancelled notification type
refactor(shell): extract widget resolver into standalone method
chore(deps): upgrade supabase_flutter to 2.8.0
docs(architecture): add realtime subscription conventions
```

---

### progress.txt entries

Append one entry per meaningful task. Be specific enough that the next person can understand what was done without reading the diff.

**Format**
```
[YYYY-MM-DD] Short summary of what was done.
- Specific change 1
- Specific change 2
- Specific change 3
```

**Example**
```
[2026-03-10] Implemented full pair reveal and confirm match flow.
- Created supabase/migrations/20260310_confirm_match_guest_rpc.sql
- Added DinnerMatch, MatchDetail, MatchGuest models to lib/models/
- Added MatchRepository with confirmMatchGuest() and getMatchDetail()
- Created ConfirmMatchTool in lib/agent/tools/ and registered in tool_registry.dart
- Built PairRevealCard widget in lib/widgets/conversation/
- Added ShellWidget.pairReveal to shell state and _resolveWidget()
- Wired up Realtime subscription for partner confirmation in realtime_service.dart
- Added all strings to strings.dart, no inline text
- Marked PAIR-02 and PAIR-03 complete in feature_list.md
```

---

## UI Architecture — Conversation Shell Model

Luma does not use a traditional screen-per-route navigation model. There is one root shell — the Luma conversation screen — and almost all user interactions happen within it by rendering contextual widgets into the conversation feed based on state.

Do not create new screens for pairing flow states, dinner flow states, or any interaction that is a response to a Luma agent message. Build a new widget and inject it into the feed.

**True separate screens** (have their own named routes):
- Circle Detail
- Profile
- Settings
- Notification tray

**Everything else is a widget rendered in the shell feed:**
- Dinner invite card
- Pair reveal card
- Waiting for partner state
- Confirmed dinner detail card
- Check-in widget
- Attendance report prompt
- Feedback form
- Circle found card
- Create circle preview card

When in doubt: if Luma would surface it in response to something, it's a widget in the feed. If the user navigates to it independently at any time, it's a screen.

Refer to `architecture.md` for the full shell structure, widget resolver pattern, and how agent tool responses trigger widget transitions.