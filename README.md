# Luma

Luma is a social dinner app that pairs people for intimate dinners through small, recurring groups called circles. Instead of a traditional interface, Luma is built around a conversational AI agent — everything from joining a circle to confirming a dinner match happens through natural conversation.

---

## What it does

- **Circles** — Join or create small recurring dinner groups with people you know or want to meet. Each circle has its own vibe, cadence, and invite code.
- **Pairing** — When a dinner cycle opens, Luma pairs members together. Pairs are revealed on a schedule, and both people confirm before the dinner is locked in.
- **Dinner management** — View venue details, add the dinner to your calendar, and check in on the day. After the dinner, report attendance and leave feedback.
- **Discovery** — Browse public circles in your city or join a private one with an invite code.

---

## Tech stack

| Layer | Technology |
|-------|-----------|
| Mobile | Flutter |
| Backend | Supabase (PostgreSQL, Auth, Realtime, Storage) |
| AI agent | Anthropic Claude |
| Notifications | Firebase Cloud Messaging |

---

## Getting started

### Prerequisites

- Flutter SDK `>=3.0.0`
- A Supabase project
- A Firebase project (for push notifications)
- An Anthropic API key

### Setup

1. Clone the repo

```bash
git clone https://github.com/your-org/luma.git
cd luma
```

2. Install dependencies

```bash
flutter pub get
```

3. Copy the environment config and fill in your keys

```bash
cp .env.example .env
```

4. Apply the database migrations

```bash
supabase db push
```

5. Run the app

```bash
flutter run
```

---

## Project structure

```
lib/
├── agent/          # Luma AI agent — tools, conversation state
├── models/         # Data models
├── screens/        # UI screens
├── services/       # Supabase, FCM, and API clients
├── widgets/        # Shared UI components
└── main.dart

supabase/
└── migrations/     # PostgreSQL migrations in chronological order
```

---

## Contributing

1. Fork the repo and create a branch from `main`
2. Make your changes
3. Open a pull request with a clear description of what changed and why

---

## License

MIT