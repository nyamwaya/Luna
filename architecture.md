# Architecture Guide (Portable)

This document describes the **architecture patterns we use and expect** across projects. It is written to be **portable**: it should not assume any specific product domain, and it should be usable as the “follow this architecture” guide when starting a new Flutter app.

## 1. High-Level Overview

**Goal:** A robust, offline-first, real-time mobile application.
**Key Characteristics:**
*   **Feature-First Structure:** Code is organized by product features (e.g., `auth`, `profile`, `home`, `settings`) rather than technical layers.
*   **Clean Architecture:** Strict separation between Data, Domain, and Presentation layers.
*   **Reactive State:** State is modeled as streams / async state and propagated via Riverpod so UIs are predictable and testable.
*   **Mobile-Only:** Optimized for iOS/Android (permissions, deep links, push, background execution where needed).

---

## 2. Tech Stack & Core Packages

This architecture is compatible with many backends; the key requirement is that **backend SDKs are kept behind the data layer**.

### Core packages (expected)

- **Framework**: Flutter
- **Language**: Dart 3+
- **State management / DI**: `flutter_riverpod`
- **Navigation**: `go_router`
- **Logging**: `logger` (wrapped behind our `Log` facade)
- **Configuration**: `flutter_dotenv` (plus a typed constants facade)

### Common integrations (optional; keep behind services)

- **Backend SDK**: e.g. `supabase_flutter` (or Firebase, REST, GraphQL, etc.)
- **Crash reporting**: e.g. Crashlytics (errors should flow through `Log.e`)
- **Local persistence**: e.g. `shared_preferences`, `sqflite`
- **Push notifications**: e.g. FCM + local notifications
- **Media & files**: image picker, file picker, caching

---

## 3. Project Structure (Feature-First)

We avoid organizing by "controllers" or "screens". Instead, we group by **Feature**.

```text
lib/
├── app.dart                   # Root widget, GoRouter config, Theme setup
├── main.dart                  # Entry point, Service initialization
├── styles.dart                # Design System Source of Truth (Colors, Type)
├── core/                      # Global/Shared components
│   ├── providers/             # Global providers (Backend client, SharedPreferences)
│   ├── services/              # Core services (Session, Logger, Integrations)
│   ├── utils/                 # Helpers (Formatters, Validators)
│   └── widgets/               # Reusable atomic widgets (Buttons, TextFields)
└── features/
    ├── auth/                  # Feature Module (example)
    ├── profile/               # Feature Module (example)
    ├── home/                  # Feature Module (example)
    ├── settings/              # Feature Module (example)
    └── ...
```

### Standard feature module layout

Each feature follows Clean Architecture boundaries:

```text
features/<feature_name>/
├── data/
│   ├── models/                # DTOs / serialization
│   └── repositories/          # Implementations (call backend SDK)
├── domain/
│   ├── entities/              # Pure Dart types
│   ├── repositories/          # Repository interfaces (contracts)
│   └── usecases/              # Single-purpose business actions
└── presentation/
    └── providers/             # Riverpod providers/notifiers for UI state
```

---

## 4. Architectural Patterns

### A. Clean Architecture & The Resource Pattern
We use a **unidirectional data flow** with strict boundary checks.

1.  **Domain Layer (The "What"):**
    *   **Entities:** Pure Dart classes (e.g., `UserEntity`). Immutable.
    *   **Repositories (Interfaces):** Contracts defining what data operations exist (e.g., `AuthRepository`).
    *   **Use Cases:** Single-responsibility classes that encapsulate business logic (e.g., `SignInUseCase`).
    *   **No external dependencies:** This layer knows nothing about Supabase or Flutter UI.

2.  **Data Layer (The "How"):**
    *   **DTOs (Data Transfer Objects):** Serialization logic (`fromJson`/`toJson`). Maps Supabase JSON to Domain Entities.
    *   **Repository Implementations:** Concrete classes (e.g., `SupaAuthRepository`) that call external APIs (Supabase) and handle exceptions.
    *   **Return Type:** Data operations return a small, explicit result type (e.g. a sealed `Resource<T>` with `Success` / `Error`). Loading is typically modeled in presentation using Riverpod’s async state.

3.  **Presentation Layer (The "Show"):**
    *   **Providers:** Riverpod Notifiers that consume Use Cases.
    *   **Widgets:** UI components that `watch` providers and rebuild on state changes.

### B. AppSession Pattern (User State)
Instead of fetching the user profile in every widget, we use a centralized **Session Service**.

*   **`AppUser`:** A presentation-layer composite model that flattens domain entities into a UI-ready object.
*   **`AppSessionService`:** A Singleton service (BehaviorSubject) that broadcasts the current `AppUser`.
*   **Flow:**
    1.  Auth changes -> Repository updates.
    2.  `AppSessionService` listens to auth stream.
    3.  Service emits new `AppUser`.
    4.  Entire app updates by watching session providers (e.g., a `currentUserStreamProvider`).

### C. Repository Pattern (Backend behind the data layer)
We abstract the backend SDK behind repositories to allow for future backend swaps and easier testing.

*   **Rule:** UI never imports backend SDKs directly. UI calls use cases / repositories via Riverpod providers.

---

## 5. Architecture Rules (Non-Negotiable)

### A. Dependency boundaries

- **Presentation** may depend on:
  - Domain
  - Core (widgets, utils, services facades)
- **Domain** may depend on:
  - Domain only (no Flutter, no backend SDK)
- **Data** may depend on:
  - Domain
  - Backend SDKs (Supabase/Firebase/HTTP)
  - Core utilities (e.g., `Log`)

### B. State management conventions

- **Riverpod is the DI mechanism**.
- Prefer keeping state changes inside notifiers/providers, not inside widgets.
- Keep providers small and focused; avoid “god providers”.

### C. Strings & localization conventions

- Do not hardcode user-facing strings directly in widgets.
- Route strings through a single source of truth.
  - In this codebase that is a centralized `AppStrings` class in `core/localization/`.
  - In other apps this may be an ARB + generated `S.of(context)` flow.

### D. Networking conventions

- Keep networking inside the data layer.
- If the app uses raw HTTP (REST/GraphQL), standardize on one client and do not call it from widgets.
- For backend SDKs (e.g., Supabase/Firebase), provide the client via `core/providers/` and consume it only from repositories/services.

### E. Error handling conventions

- Convert low-level exceptions into **typed results** (e.g., `Resource.error(message, stackTrace: ...)`).
- UI displays **user-friendly** error messages (never raw stack traces).
- Always propagate stack traces through logs for debugging.

### F. Code organization & reuse

- Prefer small, focused files and classes.
- Reuse components via `core/widgets/` instead of duplicating UI.
- Keep cross-cutting concerns (logging, analytics, crash reporting, session, push, messaging) behind `core/services/` facades.

### G. Documentation

- Every public class, method, and module should be documented.
- Treat this document as the “contract” for how new code should be structured.

### H. Animation & motion policy

- Prefer **subtle motion** that supports comprehension (state change confirmation, navigation continuity, loading feedback), not decoration.
- Standardize on a single animation approach for common UI polish:
  - Use `flutter_animate` for simple, composable micro-interactions (fade/slide/scale).
  - Use implicit animations (`AnimatedContainer`, `AnimatedOpacity`, etc.) when they are sufficient.
- Keep animations **fast and consistent**:
  - Default durations: 150–250ms for micro-interactions.
  - Use easing curves consistently (avoid random curves per screen).
- Respect accessibility:
  - Avoid motion that could be disorienting.
  - Provide a way to reduce/disable non-essential animations if the platform/user setting requires it.
- Performance rules:
  - Avoid animating large, expensive widgets when possible.
  - Prefer animating opacity/transform over layout-affecting properties.
  - Do not start long-running animations inside hot rebuild paths.

---

## 6. Key Systems

### A. Navigation (GoRouter)
*   **Routing:** Centralized in `lib/app.dart`.
*   **Deep linking:** Use path parameters for inbound links (e.g., `/invite/:code` becomes `/referral/:code` in another app).
*   **Auth gating:** Gate access by observing session/auth state and redirecting to the appropriate entry route.

### B. Logging System
*   **No prints:** prefer `Log` (the app-wide logging facade).
*   **`Log` facade:** wraps `logger` and centralizes formatting + crash reporting integration.
*   **Riverpod observer:** a global `ProviderObserver` logs provider lifecycle + failures.

### C. Design System
*   **Source of Truth:** `lib/styles.dart`.
*   **Usage:** We do not hardcode colors/fonts. We use `AppColors.primary`, `AppTextStyles.header1`, etc.
*   **Theme:** Custom `ThemeData` is built from these constants and applied at the root `MaterialApp`.

### D. Configuration & secrets

*   Load environment variables via `flutter_dotenv`.
*   Access env values through a typed facade (e.g., `AppConstants`) rather than sprinkling `dotenv.env[...]` across the app.
*   Never hardcode secrets in source.

### E. Session lifecycle (sign-in / sign-out)

*   Keep “session cleanup” centralized in a single service.
*   On sign-out:
    - disconnect external SDK sessions
    - clear in-memory session (`AppSessionService.clearSession()`)
    - clear persisted caches when appropriate

---

## 7. Development Workflow (Porting Guide)

## Conversation Shell

The core UI pattern in Luma is a single persistent conversation shell. It is not a chat app — it is an agent-driven interface where Luma injects contextual widgets into a scrollable feed in response to user actions and backend state changes.

### Structure
```
ConversationShell
├── TopBar (avatar, city selector, notification bell)
├── ScrollableFeed
│   ├── ContextStrip (breadcrumb of recent action)
│   ├── LumaMessage (agent text bubble)
│   ├── ContextualWidget (state-driven — see below)
│   ├── LumaMessage
│   └── QuickReplyChips (optional)
└── InputBar (text input + send button)
```

### Contextual Widgets

Each widget maps to a specific state in the dinner or pairing lifecycle. The shell does not navigate — it rebuilds the feed with the appropriate widget when state changes.

| Widget | State that triggers it |
|--------|----------------------|
| `DinnerInviteCard` | `dinner_invite` notification received |
| `WaitingForPairsCard` | Invite accepted, no match yet |
| `PairRevealCard` | `now() >= reveal_at` and match status is `revealed` |
| `WaitingForPartnerCard` | Current user confirmed, partner has not |
| `PartnerDeclinedCard` | Partner's `declined_at` is set |
| `ConfirmedDinnerCard` | Match status is `confirmed` |
| `CheckInWidget` | Within check-in window on dinner day |
| `AttendanceReportCard` | After `scheduled_date`, within `reporting_deadline` |
| `FeedbackWidget` | After `attended = true` is reported |
| `CircleFoundCard` | Invite code resolved successfully |
| `CirclePreviewCard` | Circle creation wizard complete, awaiting confirm |

### State Management

Each contextual widget is driven by its own state class. The shell observes:
- Supabase Realtime subscriptions (match confirmation, partner check-in, notifications)
- Local app state (current flow, last action taken)
- Notification routing (deep links from FCM push taps resolve to a widget state, not a route)

### Adding a New Contextual Widget

1. Create the widget in `lib/widgets/conversation/`
2. Define the state that triggers it
3. Register it in the shell's state resolver
4. Wire up any Realtime subscription or notification type that should trigger it
5. Do not create a new route — the shell handles display

### Navigation

Only route to a new screen when the user is navigating somewhere independently of agent flow. Use the shell for everything Luma initiates or responds to.

To port this architecture to a new project:

1.  **Create the skeleton:** `main.dart`, `app.dart`, `styles.dart`, `core/`, `features/`.
2.  **Wire Riverpod:** Wrap `runApp` with `ProviderScope` and register the global `ProviderObserver`.
3.  **Add config:** `.env` + a typed constants facade.
4.  **Add session:** `AppUser` + `AppSessionService` + session providers.
5.  **Build one feature end-to-end:** e.g., `auth` or `profile` (domain contracts -> data impl -> presentation providers -> screens).
6.  **Add integrations behind services:** crash reporting, backend SDK, messaging, push, etc.

---

## 8. Self-critique (of this document)

- This guide is intentionally **prescriptive** and may be stricter than some parts of the current codebase.
- Some existing files may still contain legacy patterns (e.g., occasional `print()` usage). Treat the rules above as the target standard when porting.
- If the new app does not use Supabase, the same boundaries still apply: keep the backend client in `core/providers/` and all external calls inside the data layer.
- The animation section specifies policy and preferred tooling (`flutter_animate`) but does not define a full motion system (tokens/curves) for every component; that should be defined per product design system.
