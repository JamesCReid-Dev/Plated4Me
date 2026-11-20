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

**Every gate that produces a result MUST have a Jira comment posted.** Never combine multiple gates into a single comment — each gate gets its own distinct update on the story. This ensures a clear audit trail of the TDD process.

**Gate 0:** Create branch `<owner>-defect-p4me-###` (or `<owner>-feat-p4me-###`), push to remote
- No Jira comment needed (branching is mechanical).

**Gate 1 (In Progress):** Transition Jira to `In Progress`, assign to self — **MUST complete before ANY test writing, code changes, or implementation work**
- Post a Jira comment confirming the story is now in progress and assigned.

**Gate 1.5 (Defect Verification only):** For defect stories: reproduce the issue, confirm root cause, document findings — still NO code changes
- Post a Jira comment documenting: reproduction steps, confirmed root cause, fix scope assessment.
- **No code changes at this stage.**

> **🚫 VIOLATION CHECK:** Before writing any test or code, verify Jira status is `In Progress`. If it is not, transition it first. Working on a story while it remains in `To Do` is a process violation.

**Gate 2 (Red):** Write failing tests for every AC, verify all fail
- Post a Jira comment with: test file path(s), which tests failed, the actual vs. expected output showing each failure.
- **Do not proceed to implementation until all tests are confirmed failing and results are posted.**

**Gate 3 (Green):** Implement ONLY enough code to make red tests pass, then re-run tests
- Post a Jira comment with: what was changed (file + line diff), test result showing each previously-red test now passing.
- **This is a separate comment from Gate 2 and Gate 4 — never combine them.**

**Gate 4 (Refactor):** Clean up code + tests, run full suite (`flutter test`), check analyzer (`flutter analyze`)
- Post a Jira comment with: refactoring summary, full test suite results (pass/fail count), analyzer results (any new issues).
- **This is the final gate before transitioning to In Review.**

> **⚠️ CRITICAL — Gate 5 Status Transition:** After posting Gate 4 results to Jira, the VERY FIRST step of Gate 5 is to transition the Jira issue to `In Review` BEFORE any git operations:
> ```bash
> acli jira workitem transition --key <KEY> --status "In Review"
> ```
> **Never skip this step.** The story must be in "In Review" before committing, pushing, or creating a PR.

**Gate 5:** Transition to `In Review` → commit/push → create PR (via `gh pr create`)
- No Jira comment needed — the PR link is created as part of the gate execution.

**Gate 5.5:** Rebase onto latest main (resolve conflicts locally)
- No Jira comment needed — rebase is a mechanical operation.

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

### Samsung Galaxy Troubleshooting

Samsung's aggressive battery manager (`FreecessController`) may kill debug processes when the screen is off — the app launches but `flutter run` reports "Lost connection to device."

**Workaround:**
```bash
# Build APK first
flutter build apk --debug

# Install manually
adb -s <device-id> install -r -t build/app/outputs/flutter-apk/app-debug.apk

# Launch on device (stays alive)
adb -s <device-id> shell am start -n com.plated4me.plated4me/.MainActivity
```
