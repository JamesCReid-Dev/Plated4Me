# Plated4Me — Claude Code Instructions

## Jira Defect Creation Rules

When creating a defect in Jira, follow these rules:

1. **Use Story type** (not Task or Bug)
2. **Prefix the title with `[Defect]`** — e.g., `[Defect] Onboarding cuisine selection overflows when >6 cuisines selected`
3. **Apply the `Defect` label** to the story (if the CLI supports it; otherwise note in the description that it is a defect)

Example:
```bash
acli jira workitem create --project P4ME --type Story \
  --summary "[Defect] <title of issue>" \
  --labels Defect
```

If `--labels` is not supported by the CLI, add a comment to the story noting it is a defect and include the label in the body.

## Project Structure

- **lib/** — Application source code
  - `application/` — Providers, services, business logic
  - `domain/entities/` — Domain models (Visit, Restaurant, UserPreferences, etc.)
  - `infrastructure/storage/` — Isar database, repositories
  - `presentation/screens/` — UI screens
  - `presentation/widgets/` — Reusable widgets
  - `presentation/navigation/` — Router and navigation
- **test/** — Test files (mirrors lib/ structure)

## TDD Workflow

1. Write failing tests first (Red phase)
2. Implement minimal code to pass tests (Green phase)
3. Refactor with all tests passing (Refactor phase)
4. Run full suite before committing: `flutter test`
5. Check analyzer: `flutter analyze` — fix any new issues

### Story Implementation Gates

Gates MUST be followed in strict order. Each gate's prerequisites must be complete before proceeding. **NO code, test, or implementation changes are allowed until after Gate 1 completes.**

**Gate 0:** Create branch `<owner>-<phase>-STORY###`, push to remote
**Gate 1 (In Progress):** Transition Jira to `In Progress`, assign to self — **MUST complete before ANY test writing, code changes, or implementation work**
**Gate 1.5 (Defect Verification only):** For defect stories: reproduce the issue, confirm root cause, document findings — still NO code changes

> **🚫 VIOLATION CHECK:** Before writing any test or code, verify Jira status is `In Progress`. If it is not, transition it first. Working on a story while it remains in `To Do` is a process violation.

**Gate 2 (Red):** Write failing tests for every AC, verify all fail, post results to Jira
**Gate 3 (Green):** Implement ONLY enough code to make red tests pass
**Gate 4 (Refactor):** Clean up code + tests, run full suite, post final results to Jira

> **⚠️ CRITICAL — Gate 5 Status Transition:** After posting test results to Jira, the VERY FIRST step of Gate 5 is to transition the Jira issue to `In Review` BEFORE any git operations:
> ```bash
> acli jira workitem transition --key <KEY> --status "In Review"
> ```
> **Never skip this step.** The story must be in "In Review" before committing, pushing, or creating a PR.

**Gate 5:** Transition to `In Review` → commit/push → create PR
**Gate 5.5:** Rebase onto latest main (resolve conflicts locally)

## Flutter Commands

- **Run on device:** `flutter run -d <device-id>` or `flutter run` (auto-detect)
- **Clean build:** `flutter clean && flutter pub get`
- **Tests:** `flutter test`
- **Analyze:** `flutter analyze`
- **iOS simulator:** `xcrun simctl list devices available` then `xcrun simctl boot "<name>"`


## Android USB-C Deployment

1. Enable Developer Options → USB Debugging on phone
2. Connect via USB-C, allow debugging dialog
3. Verify: `adb devices` (should show device)
4. Run: `flutter run` (auto-detects connected device)
