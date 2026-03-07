# prompt.md — Luma Agent Startup Instructions

You are either taking over from another agent or starting fresh. Either way you have no prior context. Follow these steps in order before writing a single line of code.

---

## 1. Orient yourself

Read the following files in this order:

1. `docs/features/agents.md` — problem statement, solution, tech stack, coding rules, git workflow, and architecture conventions.
2. `docs/features/feature_list.md` — all features across all modules, with `is_complete` flags.
3. `docs/progress.txt` — running log of what has been done so far by previous agents and engineers.

Do not skip any of these. They are your ground truth.

---

## 2. Understand the git state

```bash
# See all branches and which one you are on
git branch -a

# See recent commit history across all branches
git log --oneline --graph --decorate --all
```

Pay attention to:
- Which branch you are currently on
- What has been merged into `develop` recently
- Any open feature branches that may be relevant to the work you are about to do

---

## 3. Check existing implementations

Before starting any work, search the codebase for existing implementations related to the feature you are about to work on. Do not duplicate work or introduce patterns that conflict with what is already there.

```bash
# Example — search for existing pairing-related code
grep -r "confirmMatch\|declineMatch\|matchGuest" lib/ --include="*.dart" -l
```

Always check:
- Relevant service files in `lib/services/`
- Relevant screen files in `lib/screens/`
- Relevant models in `lib/models/`
- Existing migrations in `supabase/migrations/`

---

## 4. Pick the next feature

Look at `feature_list.md` and identify the highest-priority incomplete feature. This is not necessarily the first one in the list — use judgment based on:

- Dependencies (some features block others)
- What `progress.txt` says was being worked on
- What makes the most product sense to ship next

When in doubt, ask the user rather than guess.

---

## 5. Do the work

Follow the conventions in `agents.md` at all times:

- Branch from `develop` using `git checkout -b feature/your-feature-name`
- Reference `app_colors.dart`, `dimensions.dart`, and `text_styles.dart` — never inline styles
- Reference `strings.dart` — never inline text
- Never use `debugPrint` — use the project logging system
- Check mockups in `mockups/` before implementing any screen
- Read `architecture.md` before making structural changes
- For database changes, read the database safety rules in `agents.md` carefully. Confirm with the user before running any database command.

---

## 6. Update documentation as you go

As you complete meaningful work, append `docs/progress.txt` with a log entry. Be specific enough that the next agent or engineer can understand what was done without reading the diff.

Format:
```
[YYYY-MM-DD] Short description of what was done.
- Specific thing 1
- Specific thing 2
- Specific thing 3
```

---

## 7. Complete the feature

When the feature is implemented:

1. Wait for **explicit user confirmation** that the feature is working correctly.
2. Update `is_complete: true` in `feature_list.md` for the relevant feature IDs.
3. Append `docs/progress.txt`.
4. Commit everything with a conventional commit message:
   ```
   feat(pairing): implement decline match flow with requeue logic
   ```
5. Push the feature branch to remote:
   ```bash
   git push origin feature/your-feature-name
   ```

Do not open a PR yourself unless the user asks you to. Do not merge your own branch.

---

## If you are confused

Ask the user up to 5 clarifying questions before proceeding. Do not make assumptions on ambiguous requirements — a bad assumption costs more time than a short conversation.