Project Instructions & Guardrails

# (place in ~/.claude/)
This project utilizes the following tools for interactions with external systems:
-**acli** — All Atlassian (Confluence & Jira) interactions go through the `acli` command-line interface. **Do not use MCP for any Jira or Confluence operations.**
- **GitHub MCP** — GitHub interactions continue to use MCP.

There are specific project variables that are parsed from the project specific file:
./.bmad.secrets.env

Variables referenced:
# Project Tracking Target Details
JIRA_USER_ID
JIRA_SPACE_KEY
JIRA_ISSUE_KEY_PREFIX
JIRA_STORY_KEY_PREFIX
JIRA_DEFECT_KEY_PREFIX
CONFLUENCE_SPACE_KEY

# Github Repository Details
GITHUB_REPO_OWNER
GITHUB_REPO


These variables will be reference throughout this instruction as a variable reference ie:


## Tech Stack

| Category | Technology |
|----------|-----------|
| Framework | Flutter >= 3.16.0 (Dart SDK >= 3.2.0 < 4.0.0) |
| State Management | Riverpod (`flutter_riverpod` + `riverpod_annotation`) |
| Immutability | Freezed (`freezed_annotation` + `freezed`) |
| Serialization | JSON Serializable (`json_annotation` + `json_serializable`) |
| Local Storage | **Isar** (`isar` + `isar_generator`) — primary NoSQL store (Sprint 1+) |
| Local Storage | Hive (`hive` + `hive_flutter` + `hive_generator`) — key-value fallback only |
| Linting | `flutter_lints` (custom rules in `analysis_options.yaml`) |
| Testing | Flutter test framework (`flutter_test`) |

---

## Architecture: Clean Architecture Layers

The project follows strict **Clean Architecture** with four layers. Dependency direction is enforced at compile time via linter rules — **inner layers must never import outer layers**.

```
presentation/          ← UI, widgets, navigation, theme
    ↓ (imports only)
application/           ← Business logic, providers, use cases
    ↓ (imports only)
domain/                ← Entities, value objects, repositories interfaces
    ↓ (imports only)
infrastructure/        ← Storage implementations, external services
```

### Layer Responsibilities

- **`lib/domain/`** — Pure business entities (`Restaurant`, `Visit`, `UserPreferences`), value objects, and repository interfaces. No framework dependencies whatsoever.
- **`lib/application/`** — Riverpod providers, business logic orchestration. Imports domain only.
- **`lib/infrastructure/`** — Isar storage implementation, adapters. Imports domain as needed.
- **`lib/presentation/`** — Flutter widgets, routing (`AppRouter`), theming (`AppTheme`). Imports everything else.

### Layer Barrel Files

Each layer has a barrel export file:
- `lib/domain/domain.dart`
- `lib/application/application.dart`
- `lib/infrastructure/infrastructure.dart`

Use these barrel imports in production code to keep import chains short and maintainable.

---

## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Classes / Enums | PascalCase | `Restaurant`, `VisitStatus`, `AllergenSeverity` |
| Variables / Functions | camelCase | `createdAt`, `getVisitedRestaurants()` |
| Files / Directories | snake_case | `restaurant_provider.dart`, `allergen_severity.dart` |
| Constants | UPPER_SNAKE_CASE | `MAX_NAME_LENGTH` (if used) |
| Private members | leading underscore | `_boxName`, `_validate()` |

### Entity Field Naming

- Use `id` for primary keys (Isar auto-increment or fixed ID)
- Use `createdAt` and `updatedAt` for timestamps
- Nullable fields use `?` type annotation explicitly
- Default values via constructor parameters, not `copyWith` defaults where possible

---

## Code Generation Rules

All generated files live alongside their source with `.g.dart`, `.freezed.dart`, or `.hive_adapter.g.dart` extensions.

### Mandatory Practices

1. **Always run `build_runner`** after modifying:
   - Isar entities → generates `.g.dart` (schema + collection accessors)
   - Freezed classes → generates `.freezed.dart`
   - JSON-serializable classes → generates `.g.dart`
   - Hive adapters → generates `.hive_adapter.g.dart`
   - Riverpod providers with annotations → generates `.riverpod.dart`

2. **Never manually edit generated files** — they are overwritten by `build_runner`.

3. **Use `part 'file.dart';` and `part of` directives** correctly for partials.

4. **Freezed classes**:
   - Prefer `@freezed` over manual `copyWith`, `==`, `hashCode`
   - Use named constructors for different factory patterns
   - Annotate with `@JsonSerializable()` when serialization is needed

5. **Isar entities** (Sprint 1+):
   - All entity classes live in a single file: `lib/domain/entities/entities.dart`
   - Each class uses the `@collection` annotation (lowercase, Isar 3.x style)
   - Use `part 'entities.g.dart';` at the top of the entities file
   - Import `package:isar/isar.dart` for `Id`, `Isar.autoIncrement`, `Index`, etc.
   - **Never use `late` on entity fields** — Isar generates its own getters/setters
   - Sub-collections (one-to-many): use `@ignore` on List fields; query via Isar filters instead of embedding lists
   - Open database with `[RestaurantSchema, VisitSchema, ...]` in main.dart

12. **Hive adapters** (fallback only):
   - Register all adapters in `main.dart` before `runApp()`
   - Hive key format: `"entity_type:{uuid}"` (e.g., `"item:{uuid}"`)
   - Use `Hive.initFlutter()` in `main()` before any UI renders

---

## Riverpod Patterns

- Providers live in `lib/application/providers/`
- Use `@riverpod` annotation for auto-generated providers
- Prefer `AsyncNotifierProvider` for async state, `StateNotifierProvider` for sync
- Never hold `BuildContext` references in providers
- Use `ref.watch()` / `ref.read()` / `ref.listen()` per Riverpod conventions

---

## Linting & Analysis Rules (from `analysis_options.yaml`)

### Critical Rules (Never Violate)

| Rule | Reason |
|------|--------|
| `avoid_relative_lib_imports: true` | Always use `package:` imports |
| `always_use_package_imports: true` | Enforces package-style imports |
| `prefer_relative_imports: false` | Disables relative imports |

### Important Rules

- `avoid_print: true` — No `print()` in production code; use a logger
- `always_declare_return_types: true` — Explicit return types on all functions
- `type_annotate_public_apis: true` — Annotate public method/constructor signatures

### Disabled Rules (Intentional)

- `sort_constructors_first: false` — Constructor order flexibility
- `use_build_context_synchronously: false` — Allowed with caution in widgets
- `dangling_library_doc_comments: false` — Acceptable for barrel files and part files

---

## Testing Guidelines & TDD Process

### Test-Driven Development (TDD) — Mandatory Process

This project follows strict **Test-Driven Development** with the Red-Green-Refactor cycle. Every story MUST go through these three phases:

#### Phase R — Red (QA Agent / Test Engineer)

1. **Read the story** from Jira, including all acceptance criteria and design documentation.
2. **Create a test plan** mapping each acceptance criterion to one or more test cases.
3. **Write failing tests** for every acceptance criterion — tests must FAIL before any production code exists.
4. **Verify all new tests fail** — run `flutter test` on the new test files and confirm failures.
5. **Report results to Jira** with coverage matrix showing AC-to-test mapping.

> **Rule:** No production code may be written during the Red Phase. The sole output is a suite of failing tests that, if passed, would satisfy every acceptance criterion.

#### Phase G — Green (Developer)

1. **Read the failing tests** created in the Red Phase — these define what "done" means.
2. **Implement production code** solely to make the failing tests pass.
3. **Write minimal code** — only enough to turn red tests green; no extra features.
4. **Run all tests** — every new test must now pass, and no existing test may break.
5. **Verify acceptance criteria** — each passing test corresponds to an AC; confirm full coverage.

> **Rule:** The developer's job is to make tests pass, not to decide what tests should exist. If a test needs changing, discuss with QA first.

#### Phase Rf — Refactor (Developer + QA)

1. **Refactor production code** now that tests provide a safety net.
2. **Apply DRY, SRP, and Clean Architecture principles.**
3. **Remove duplication**, extract abstractions, improve naming.
4. **Run full test suite** after every refactor — all tests must continue to pass.
5. **Refactor tests too** if they have duplicated setup or unclear structure.

> **Rule:** Refactoring is NOT adding features. If you add functionality during refactor, go back to Green Phase for that new functionality.

### Test File Organization

- Test files go in `test/` alongside `lib/`, mirroring the layer structure:
  - `test/domain/` — domain entity and value object tests
  - `test/application/` — provider and use case tests
  - `test/presentation/` — widget and UI tests
  - `test/infrastructure/` — storage implementation tests
  - `test/integration/` — cross-layer integration tests
- Follow the existing naming pattern: `<subject>_test.dart` (e.g., `restaurant_test.dart`, `restaurant_provider_test.dart`).
- Use `flutter_test` package for widget and unit tests.
- Mock repositories/interfaces at layer boundaries.
- Test domain logic in isolation (no Flutter framework needed).

### Test Writing Conventions

- Group tests by entity/provider/widget using `group()`.
- Use descriptive test names that reference the acceptance criterion being tested: `test('AC1 — creates restaurant with required name only', () { ... })`.
- Use `package:` imports exclusively.
- Declare all return types explicitly.
- No `print()` statements; use proper assertions.
- Tests must be self-contained and deterministic — no flaky tests.
- For async code, use `await` and `expectLater(..., completes)` appropriately.
- For widget tests: `testWidgets('<description>', (WidgetTester tester) async { ... })`.

---

## Import Rules

### ✅ Correct

```dart
import 'package:plated4me/domain/entities/restaurant.dart';
import 'package:plated4me/application/providers/dashboard_provider.dart';
import 'package:plated4me/infrastructure/storage/isar_storage.dart';
```

### ❌ Incorrect

```dart
import '../domain/entities/item.dart';          // Relative import — forbidden
import '../../lib/domain/entities/item.dart';   // Absolute path — forbidden
```

---

## File Structure Reference

```
lib/
├── main.dart                          # Entry point, ProviderScope, Isar init
├── presentation/
│   ├── navigation/app_router.dart     # Navigation/routing
│   └── theme/app_theme.dart           # Light/dark themes
├── application/
│   ├── application.dart               # Barrel exports
│   └── providers/                     # Riverpod providers
├── domain/
│   ├── domain.dart                    # Barrel exports
│   ├── entities/
│   │   ├── entities.dart              # All Isar @collection classes + part directive
│   │   └── entities.g.dart            # Generated by isar_generator
│   ├── value_objects/
│   └── repositories/
│       └── repositories.dart          # Repository interface barrel
└── infrastructure/
    ├── infrastructure.dart            # Barrel exports
    └── storage/
        └── isar_storage.dart          # Isar implementation
```

---

## Mandatory Pre-Implementation Gates

These gates enforce strict ordering of operations. **NO code changes, file creation, or file edits are permitted until all preceding gates have been explicitly verified and passed.** Violating these gates is a process failure that must be corrected before proceeding.

**⚠️ NO EXCEPTIONS — This rule applies to every request without exception:**
- "Analyze this defect" → still requires Gates 0, 1, 2 (and 0.5 for defects) before any code changes
- "Fix this bug quickly" → still requires all gates in order
- "Review and resolve" → analysis is Gate 0/0.5; implementation cannot begin until Gates 0–2 are complete
- Any request that mentions a Jira key or implies work on the codebase triggers the full gate sequence

The only thing you may do before Gate 1 is **read existing code** for analysis purposes — but even then, Gate 2 (Jira initialization) must be completed before any file edits.

### Gate 0: Story Identification & Context

Before touching any code, you MUST:
1. Use the `acli` interface for **all** Jira and Confluence interactions. **Never use MCP for Jira or Confluence operations.**
2. Use GitHub MCP for all GitHub interactions.
3. Identify the Jira issue key (e.g., ${JIRA_STORY_PREFIX}001 ) and the Story number (e.g., ${JIRA_STORY_PREFIX}003 ) from the user's request or by searching Jira. If there is no issue found, use `ISSUE-TBD` as default. If there is no story found, use `STORY-TBD` as default.
4. Retrieve the full story details including acceptance criteria from Jira.
5. If design documentation is referenced, fetch Confluence pages for review.

**GATE CHECK:** Confirm you have the correct Jira key, Story number, and acceptance criteria before proceeding. **DO NOT proceed to Gate 1 until this is complete.**

### Gate 0.5: Defect Analysis (Defect Stories Only)

This gate applies ONLY when the Jira story is marked as a defect — identified by either:
- A `[Defect]` prefix in the summary/title, OR
- A label of `Defect` on the issue

Before any implementation work begins, you MUST perform a thorough root-cause analysis:

1. **Reproduce the issue** — verify it exists in the current codebase by examining the relevant UI screens, providers, or storage logic.
2. **Identify the root cause** — trace the bug to its origin (e.g., nested Scaffold collision, missing null check, incorrect provider state, stale data).
3. **Determine validity** — confirm whether this is a genuine defect or if the behavior is intentional / out of scope.
4. **Post analysis results as a Jira comment** in the required format:

   ```
   ## Defect Analysis — <JIRA_KEY>: <Summary>
   - Valid Defect: ✅ Yes / ❌ No (not an issue)
   - Root Cause: <brief description of what causes the bug>
   - Impact: <user-facing impact assessment>
   - Files Involved: lib/.../file1.dart, lib/.../file2.dart

   ### Analysis Details
   <detailed explanation of how the defect was identified and why it occurs>

   **Status:** Ready for implementation (if valid) / Close as Not a Defect (if invalid).
   ```

5. **If NOT a valid defect**, post the analysis comment and recommend closing the issue. Do not proceed to Gate 1.
12. **If VALID**, post the analysis comment and proceed through Gates 1 and 2 normally — create branch, push to remote, transition Jira to `In Progress`, assign artifact. Only then may implementation begin.

> **Critical Rule:** Never begin implementation on a defect story without first posting a validated analysis comment AND completing all preceding gates (0 → 1 → 2). The analysis is Gate 0.5; it does NOT replace Gates 1 and 2. This ensures full traceability from Jira initialization through code changes to PR creation.

**GATE CHECK:** Confirm defect analysis is posted as a Jira comment before proceeding. **DO NOT proceed to Gate 1 until this is complete.** (Skip for non-defect stories.)

### Gate 1: Branch Creation & Remote Push

Before making ANY code changes, you MUST:
1. Create a new Git branch using the naming pattern `<owner>-<phase>-STORY###` where `STORY###` is the Story number (NOT the Jira issue key).
2. Push the branch to remote origin with `git push -u origin <branch-name>`.
3. Verify the branch exists on remote by running `git branch -r | grep <branch-name>`.

**GATE CHECK:** Confirm the branch is created locally AND pushed to remote before proceeding. Post a brief Jira comment with the branch name and remote verification status. **DO NOT proceed to Gate 2 until this is complete.**

### Gate 2: Jira Initialization

Before making ANY code changes, you MUST:
1. Transition the Jira issue to `In Progress` using a proper workflow transition (not raw status).
   ```bash
   acli jira workitem transition --key <KEY> --status "In Progress"
   ```
2. Assign the Jira artifact to the correct person.
   ```bash
   acli jira workitem assign --key <KEY> --assignee "@me"
   ```
3. Verify the issue appears in the active column on the sprint board.

**⚠️ If Jira operations fail with "Not authenticated":**
- Run `acli jira auth login` to re-authenticate via OAuth
- Follow the browser-based authentication flow

**GATE CHECK:** Confirm Jira is initialized and the issue is in `In Progress` before proceeding. **DO NOT proceed to Gate 2.5 until this is complete.**

### Gate 2.5: TDD Red Phase — QA Test Creation

Before ANY production code may be written, you MUST complete the TDD Red Phase:

1. **Invoke or act as the QA Agent** (`.claude/agents`) to read the story from Jira.
2. **Create a test plan** mapping each acceptance criterion to specific test cases across appropriate layers (domain, application, presentation, infrastructure).
3. **Write failing tests** for every acceptance criterion — these tests MUST fail when run because the production code does not yet exist.
4. **Verify all new tests FAIL** by running `flutter test` on the newly created test files. Confirm each failure is genuine (not a false positive from skipped tests or incorrect setup).
5. **Post Red Phase results to Jira** as a comment with:
   - List of test files created
   - Acceptance criteria coverage matrix (which AC maps to which test)
   - Full `flutter test` output showing all new tests FAILING

> **Critical Rule:** If any newly written test passes during the Red Phase, investigate why. A passing test means either:
> - The functionality already exists (remove from this story's scope)
> - The test has a bug in its assertion (fix the test)
> - The test is testing something outside this story's scope (move to appropriate story)

**GATE CHECK:** Confirm all acceptance criteria have corresponding failing tests and results are posted to Jira. **DO NOT proceed to Gate 3 until this is complete.**

### Gate 3: TDD Green Phase — Implementation (Code Changes Allowed)

Only after Gates 0, 1, 2, and 2.5 are passed may you begin implementing production code. All implementation must follow Clean Architecture boundaries, naming conventions, and the **Green Phase** discipline defined elsewhere in this document.

**Green Phase Rules:**
- Read and understand the failing tests created by QA — they define "done."
- Write ONLY enough production code to make the red tests pass. No extra features.
- After each test passes, run the full suite to ensure no existing tests break.
- Verify every acceptance criterion has at least one passing test.

**GATE CHECK:** Confirm all acceptance criteria are met and ALL tests (new + existing) pass before proceeding to Gate 4. Post a brief Jira comment summarizing the Green Phase implementation (what was done to turn red tests green). **DO NOT proceed to Gate 4 until this is complete.**

### Gate 4: TDD Refactor Phase & Final Test Verification

Before transitioning the issue status, you MUST complete both the Refactor Phase and test verification:

1. **Refactor Phase (Rf):** With tests as a safety net, refactor production code to apply DRY, SRP, and Clean Architecture principles. Also clean up any duplicated test setup. Run full suite after every change — all tests must continue passing.
2. **Run `flutter test`** and ensure ALL tests pass (new + existing + refactored).
3. **Post the full test results as a comment on the Jira story** in the required format below.

> **Rule:** Refactoring is NOT adding features. If you discover new functionality needed, create a new story for it rather than expanding scope during refactor.

**GATE CHECK:** Confirm test results are posted as a Jira comment before proceeding. **DO NOT transition to In Review until this is complete.**

### Gate 5: Commit, Push & PR (Post-TDD)

After all TDD phases (Red → Green → Refactor) are complete and tests are posted:
1. Transition the Jira issue status (e.g., to `In Review`).
2. Stage and commit with message `<jira-id>-<status>`. Include a summary of which TDD phase each commit represents if multiple commits are made.
3. Push to remote origin.
4. Create a Pull Request linking to the Jira artifact, referencing:
   - The Red Phase test files created by QA
   - The Green Phase implementation
   - Any Refactor changes
   - The Jira comment with final test results

**GATE CHECK:** Confirm PR is created and linked before considering the story complete. Post a Jira comment with the PR link and review request info. **DO NOT proceed to Gate 5.5 until this is complete.**

### Gate 5.5: Rebase onto Latest Main (Pre-Merge)

Before merging the PR, you MUST ensure your branch is up-to-date with main to avoid merge conflicts:

1. **Fetch latest main:** `git fetch origin main`
2. **Rebase onto main:** `git rebase origin/main`
3. **Resolve any conflicts immediately** — do NOT defer conflict resolution to the PR merge step. Edit conflicted files, `git add` resolved files, then `git rebase --continue`.
4. **Force-push the rebased branch:** `git push --force-with-lease origin <branch-name>`
5. **Verify the PR is clean** — no merge conflicts should remain when viewing the PR on GitHub.

> **Why this matters:** While you work on a feature branch, other PRs may be merged to main. Rebasing before merge ensures your changes sit cleanly on top of the latest code, making the squash-merge conflict-free. Pulling latest *before* branch creation is not sufficient — main continues advancing during development.

**GATE CHECK:** Confirm branch is rebased onto latest main with no conflicts before proceeding. Post a Jira comment confirming clean rebase and force-push. **DO NOT proceed until this is complete.**

---

## Sprint Management — Critical Procedures

### ⚠️ Pre-Sprint Checklist (Run Before First Commit of Any Sprint)

Every sprint must have these three things configured in Jira BEFORE any code changes:

1. **Sprint Started** — The sprint must be active (not "future" or "closed")
2. **Stories Assigned** — All stories for the sprint must be linked to it via the Sprint field
3. **Board Status Reflected** — Story statuses on the scrum board must match actual work state

```bash
# Verify sprint is active and has stories
acli jira sprint view --id <SPRINT_ID>
acli jira sprint list-workitems --sprint <SPRINT_ID> --board 34

# If no stories are in the sprint, link them manually (see Known Limitations below)
```

### Post-Sprint Sync

After completing work in a sprint, always update Jira:
```bash
# Transition completed stories to Done
acli jira workitem transition --key <KEY> --status "Done"

# Add completion comments
acli jira workitem comment create --key <KEY> --body "Completed in Sprint N. See commit <hash>."
```

### Known Limitations — Story Association via CLI

**The `acli` tool cannot add issues to sprints.** This is a limitation of the available CLI tools:

- `acli jira sprint create/update/view/list-workitems` — works for managing sprint metadata
- `acli jira workitem edit` — does NOT support setting the Sprint field or custom fields

**Workaround: Associate stories manually in Jira UI:**
1. Go to https://jamescreiddev-tbs.atlassian.net/browse/P4ME
2. For each story, click the Sprint field and select the active sprint
3. Or use bulk edit: Select multiple issues → More → Edit Issues → set Sprint field

**Stories for Sprint 1 — Foundation:**
- P4ME-7: Set up development environment, project structure, and build tooling
- P4ME-9: Set up database schema and migrations system
- P4ME-23: S01 — Isar Schema & Entity Models
- P4ME-24: S02 — Data Layer — Repository Implementation
- P4ME-25: S03 — Navigation Shell (Bottom Nav + IndexedStack)

### Jira Troubleshooting Quick Reference

| Symptom | Cause | Fix |
|---------|-------|-----|
| "Not authenticated" from acli | OAuth token expired or not configured | Run `acli jira auth login` to re-authenticate |
| No stories in sprint | Stories not linked to Sprint field | Link manually in Jira UI (see Known Limitations above) |
| Board shows wrong status | Status not transitioned after coding | Run `acli jira workitem transition --key <KEY> --status "Done"` |

### Fallback: GitHub Issues as Sprint Tracker

If Jira is unavailable, use GitHub Projects/Issues as a temporary fallback:
- Create milestones matching sprint numbers (e.g., "Sprint 1 — Foundation")
- Label issues with `sprint-1`, `story`, `bug` etc.
- Use project boards for Kanban-style tracking

---

## General Guardrails for Cline

1. **Always respect Clean Architecture boundaries** — never let domain code depend on presentation or infrastructure.
2. **Use `package:` imports exclusively** — the linter enforces this.
3. **Declare all return types explicitly** — required by analysis options.
4. **Run `build_runner` after changes to annotated classes** — Isar, Freezed, Hive, JSON, Riverpod generators must be re-run.
5. **No `print()` statements** — use proper logging if needed.
12. **Never return `null` for `Future<T>` or `String`** — handle gracefully instead.
13. **Use `const` constructors where possible** — Flutter performance best practice.
14. **Keep widgets small and composable** — follow Flutter widget composition patterns.
15. **Document public APIs with doc comments (`///`)** — especially entities, providers, and repository interfaces.
16. **When in doubt, match existing code style** — refer to `lib/domain/entities/entities.dart` as a reference for entity conventions.
17. **Follow TDD discipline** — tests must fail before implementation (Red), pass after implementation (Green), then clean up (Refactor). Never write production code without a failing test driving it.

---

## Jira Comment Protocol — Phase-by-Phase Updates

Every story (regular feature, defect fix, or task) MUST have its progress documented on the Jira issue via comments at each major phase transition. This ensures that if work is interrupted or handed off to another developer, they can read the comment history and immediately understand where things stand without re-reading the entire codebase.

### Required Comment Points

Every gate and phase MUST post a Jira comment upon completion. This ensures that if the process is interrupted (session terminated, connection lost, etc.), any subsequent agent or developer can read the Jira comments and immediately determine where work left off — no need to re-read code or guess state.

**Rule:** At every Gate CHECK, before proceeding to the next gate, post a Jira comment summarizing what was just completed. Use `acli jira workitem comment create --key <KEY> --body "..."`. The comment should be brief but specific enough that another agent can pick up from here.

| Phase | Action | Comment Content |
|-------|--------|-----------------|
| **Gate 0** | Story identified & context retrieved | `## Gate 0 — Story Identified` with Jira key, story number, summary, and acceptance criteria summary |
| **Gate 1** | Branch created locally | Brief status: `Branch <branch-name> created locally` |
| **Gate 1** | Branch pushed to remote | Brief status: `Branch <branch-name> pushed to remote origin — verified` |
| **Gate 2** | Jira initialized (transitioned + assigned) | `## Gate 2 — Jira Initialized` with transition name used and assignee confirmation |
| **Gate 0.5** | Defect analysis (defects only) | `## Gate 0.5 — Defect Analysis` with validity verdict, root cause, impact, files involved, and details |
| **Gate 2.5** | Red Phase complete (all tests written & failing) | `## TDD Red Phase — Test Creation Complete` with test files, coverage matrix, failure output |
| **Gate 3** | Green Phase complete (implementation done, all tests passing) | `## TDD Green Phase — Implementation Complete` with what was implemented to pass each red test |
| **Gate 4** | Refactor + final test verification complete | `## Test Results — TDD Complete (Red → Green → Refactor)` with full output, AC matrix, phase summary |
| **Gate 5** | PR created & linked | `## Gate 5 — PR Created` with PR link and review request info |
| **Gate 5.5** | Rebase onto latest main complete | `## Gate 5.5 — Rebase onto Main` with confirmation of clean rebase and force-push |
| **Phase 6a** | iOS build & deploy complete | `## Phase 6a — iOS Build & Deploy` with simulator model, build result, launch verification |
| **Phase 6b** | Android build & deploy complete | `## Phase 6b — Android Build & Deploy` with emulator ID, build result, launch verification |

### Defect-Specific Resolution Comment

After resolving a defect (post-Gate 4, pre-Gate 5), post an additional resolution comment:

```
## Defect Resolution — <JIRA_KEY>: <Summary>
- Root Cause: <what caused the bug>
- Fix Applied: <which files changed and what was done>
- Impact: <user-facing impact of the fix>
- Test Results: X passed, Y failed (all passing)

### Files Changed
- lib/.../file1.dart — <brief description of change>
- lib/.../file2.dart — <brief description of change>
- test/.../test_file.dart — <brief description of test changes>

**Status:** Resolution verified. Ready for In Review.
```

### Comment Format Guidelines

- Use `##` headings with the gate number and phase name for easy scanning.
- Include a **Status** line at the end indicating readiness for the next step.
- Keep comments concise but informative — enough that another developer can pick up work without reading code.
- Paste relevant test output snippets (not full logs unless under 20 lines).
- Link to PRs, Confluence pages, or Figma designs where applicable.

---

## Commands Reference

```bash
# Run app
flutter run

# Run tests
flutter test

# Generate code (Isar, Freezed, Hive, JSON, Riverpod)
dart run build_runner build --delete-conflicting-outputs

# Analyze code
flutter analyze

# Format code
dart format .

# Get dependencies
flutter pub get

# Jira — search work items
acli jira workitem search --jql "project = P4ME AND status != Closed" --paginate

# Jira — view a work item
acli jira workitem view P4ME-15

# Jira — transition a work item
acli jira workitem transition --key P4ME-15 --status "In Review"

# Jira — comment on a work item
acli jira workitem comment create --key P4ME-15 --body "Comment body here"

# Jira — assign a work item
acli jira workitem assign --key P4ME-15 --assignee "@me"

# Jira — check auth
acli jira auth status
```

---

## Documentation & Agile Practices

### Confluence — Technical Documentation

All technical documentation updates must be created and maintained in the **Confluence space "Plated4Me"**. This includes:

- Architecture decision records (ADRs)
- API documentation
- Design specifications and wireframes
- Release notes and changelogs
- Onboarding guides and runbooks
- Technical deep-dives and research findings
- Meeting notes for technical discussions

**Rules:**
- Place new pages under the appropriate space tree section that matches their topic (e.g., architecture docs under an "Architecture" folder, release notes under a "Releases" folder).
- Link to Confluence pages from code comments using full URLs when referencing external design or spec documents.
- Keep code-level documentation in `///` doc comments within the Dart source; use Confluence for higher-level, human-readable documentation that benefits from formatting, images, and collaboration.

### Jira — Agile & Project Tracking

All agile and project management documentation must be created and maintained in the **Jira space `P4ME`** (key prefix `IS-`). This includes:

- Epics, stories, tasks, sub-tasks, and bugs
- Sprint planning and backlog grooming records
- Velocity reports and burndown charts
- Dependencies between issues (blocking, relates-to, duplicates)
- Acceptance criteria and definition of done per story
- Cross-team or cross-project tracking links

**Rules:**
- Every code change that implements user-facing functionality must be linked to a Jira story or task via the issue key in commit messages (e.g., `PROJ-123: implement item status filtering`).
- Epics should represent major features or architectural changes; stories should be small enough to complete within a single sprint.
- Update issue statuses promptly — code merged implies "Done," testing completed implies "Ready for QA," etc.
- Use Jira labels consistently (e.g., `frontend`, `backend`, `bug`, `enhancement`) for filtering and reporting.

---

## Software Development Lifecycle — Story Implementation Workflow

This process defines the step-by-step workflow to follow when a story or task has been requested to begin implementation in Jira.

> **⚠️ CRITICAL: The Mandatory Pre-Implementation Gates section above takes precedence over this workflow.** You MUST pass all gates before proceeding. This section provides additional context for each phase but does NOT override the gate requirements.

### Phase 1: Branch Creation & Setup (Gate 0 → Gate 1)

1. **Create a new Git branch locally** using the naming pattern:
   ```
   <assigned-to-owner>-<phase>-<story-number>
   ```
   - `<assigned-to-owner>` — The developer's initials or username (e.g., `jc`, `jsmith`)
   - `<phase>` — The development phase, such as:
     - `dev` for standard feature development
     - `bugfix` for bug fixes
     - `hotfix` for urgent production fixes
     - `refactor` for code refactoring
     - `test` for test-only changes
   - `<story-number>` — The **Story number** from the Jira artifact (e.g., `STORY037`, `STORY-036`). This is NOT the Jira issue key.

   > **Important:** Use the Story number, not the Jira issue ID/key. The story number follows the pattern `STORY###` and can be found in the story's summary or description field.
   >
   > **Example:** `jc-dev-STORY037` or `jsmith-bugfix-STORY025`

2. **Push the new branch to the remote origin repository:**
   ```bash
   git push -u origin <branch-name>
   ```

3. **Ensure the branch is checked out and set as the active working branch.**

### Phase 2: Jira Artifact Initialization (Gate 1 → Gate 2)

4. **Transition the Jira issue to `In Progress`** using the proper workflow transition (not just changing status). This ensures the issue moves to the correct swimlane/column on the Jira board.
    - Use a transition name like `"Start Progress"` or `"In Progress"` — not a raw status value.
    - Verify the issue now appears in the active/in-progress column of the sprint board.

5. **Assign the Jira artifact** to the requestor/assignee unless a specific assignee was called out in the story description or comments. Use the same person for both the Jira assignment and the branch ownership.

### Phase 2.5: Defect Analysis (Gate 2 → Gate 2.5 — Defects Only)

This phase applies ONLY to stories marked as defects (`[Defect]` prefix in title or `Defect` label). Skip entirely for regular feature stories.

12. **Reproduce the issue** — verify it exists by examining the relevant UI screens, providers, storage logic, or business rules described in the story.
13. **Identify the root cause** — trace the bug to its origin (e.g., nested Scaffold collision, missing null check, incorrect provider state, stale data, race condition).
14. **Determine validity** — confirm whether this is a genuine defect or if the behavior is intentional / out of scope / already fixed.
15. **Post analysis results as a Jira comment** in the required format:

   ```
   ## Defect Analysis — <JIRA_KEY>: <Summary>
   - Valid Defect: ✅ Yes / ❌ No (not an issue)
   - Root Cause: <brief description of what causes the bug>
   - Impact: <user-facing impact assessment>
   - Files Involved: lib/.../file1.dart, lib/.../file2.dart

   ### Analysis Details
   <detailed explanation of how the defect was identified and why it occurs>

   **Status:** Ready for implementation (if valid) / Close as Not a Defect (if invalid).
   ```

16. **If NOT a valid defect**, post the analysis comment and recommend closing the issue. Do not proceed to Phase 3.
17. **If VALID**, complete Gates 1 (branch creation & push) and Gate 2 (Jira initialization: transition to `In Progress`, assign artifact), then proceed to Phase 3 (TDD Red Phase).

> **Critical Rule:** Never begin implementation on a defect story without first posting a validated analysis comment AND completing all preceding gates (0 → 1 → 2 → 0.5). The analysis is Gate 0.5; it does NOT replace Gates 1 and 2. This ensures full traceability from Jira initialization through code changes to PR creation.

### Phase 3: TDD Red Phase — QA Test Creation (Gate 2 → Gate 2.5)

12. **Review design documentation** for impacted changes:
   - Check Confluence pages in the **"Plated4Me"** space if architecture, API specs, or user-facing docs are affected by this story
   - Check Figma designs if UI/UX changes are made
   - If NO design updates needed: note "No design changes required for this story" in Jira comments

13. **Act as (or invoke) the QA Agent** to read the full story from Jira, including all acceptance criteria and design context.

14. **Create a test plan** mapping each acceptance criterion to specific test cases across appropriate layers:
   - Domain tests for entity logic and value objects
   - Application tests for providers and use cases
   - Presentation tests for widgets and UI behavior
   - Infrastructure tests for storage implementations

15. **Write failing tests** for every acceptance criterion — these tests MUST fail when run because the production code does not yet exist:
   - One test file per logical feature area, following existing naming patterns
   - Use `group()` to organize tests by entity/provider/widget
   - Include at least one negative/edge-case test per AC
   - Follow all project conventions (package imports, explicit return types, no print)

16. **Verify ALL new tests FAIL** by running `flutter test` on the newly created files. Confirm each failure is genuine.

17. **Post Red Phase results to Jira** as a comment:
    ```
    ## TDD Red Phase — Test Creation Complete
    - Story: <JIRA_KEY>: <Summary>
    - Tests Written: X test(s) across Y file(s)
    - All Tests Failing: ✅ Confirmed

    ### Files Created
    - test/<path>/<test_file>.dart — covers AC 1, AC 2, ...
    - test/<path>/<test_file>.dart — covers AC 3, AC 4, ...

    ### Test Failures Verified
    [paste flutter test output showing all new tests FAIL]

    ### Acceptance Criteria Coverage
    | AC # | Description | Test File | Test Count |
    |------|-------------|-----------|------------|
    | 1    | ...         | ...       | X          |
    | 2    | ...         | ...       | X          |

    **Status:** Ready for Green Phase (developer implementation).
    ```

> **Critical Rule:** No production code may be written during the Red Phase. The sole output is a suite of failing tests that, if passed, would satisfy every acceptance criterion. If any new test passes unexpectedly, investigate and adjust — all newly written tests must fail.

### Phase 4: TDD Green & Refactor Phases — Implementation (Gate 2.5 → Gate 3 → Gate 4)

18. **Green Phase:** Read the failing tests created in the Red Phase — they define "done." Implement ONLY enough production code to make those tests pass. No extra features, no scope expansion.

19. **Verify each test turns green** as you implement. After each passing test, run the full suite to ensure no existing test breaks.

20. **Refactor Phase (Rf):** With tests as a safety net, refactor production code to apply DRY, SRP, and Clean Architecture principles. Also clean up duplicated test setup. Run full suite after every change — all tests must continue passing. Refactoring is NOT adding features; if new functionality is needed, create a new story.

21. **Execute final `flutter test`** and ensure ALL tests pass (new + existing + refactored).

22. **Post final test results to Jira** as a comment:
    ```
    ## Test Results — TDD Complete (Red → Green → Refactor)
    - Total tests: X
    - Passed: X
    - Failed: 0
    - Errors: 0

    ### Test Output
    [paste full flutter test output here]

    ### Files Tested
    - test/path/to/file_test.dart
    - test/another_file_test.dart

    ### TDD Phases Completed
    - Red Phase: X test(s) written across Y file(s), all initially failing ✅
    - Green Phase: All red tests now passing ✅
    - Refactor Phase: Code cleaned, no behavior changes, all tests still passing ✅

    ### Acceptance Criteria Met
    | AC # | Status | Verified By |
    |------|--------|-------------|
    | 1    | ✅ Met | test_<name>.dart |
    | 2    | ✅ Met | test_<name>.dart |
    ```

17. **Defect Resolution Comment (defects only):** If this is a defect story, post a resolution comment before transitioning:

   ```
   ## Defect Resolution — <JIRA_KEY>: <Summary>
   - Root Cause: <what caused the bug>
   - Fix Applied: <which files changed and what was done>
   - Impact: <user-facing impact of the fix>
   - Test Results: X passed, Y failed (all passing)

   ### Files Changed
   - lib/.../file1.dart — <brief description of change>
   - lib/.../file2.dart — <brief description of change>
   - test/.../test_file.dart — <brief description of test changes>

   **Status:** Resolution verified. Ready for In Review.
   ```

18. **Only after ALL tests pass and results are posted as a Jira comment, transition to In Review.**

### Phase 5: Code Review & Pull Request (Gate 4 → Gate 5)

19. **Update the Jira artifact status to `In Review`** once implementation is complete and all acceptance criteria are met.
    ```bash
    acli jira workitem transition --key <KEY> --status "In Review"
    ```

20. **Stage and commit all changed files** with a commit message following this pattern:
    ```
    <jira-artifact-id>-<status>
    ```
    - `<jira-artifact-id>` — The Jira issue key (e.g., `P4ME-123`)
    - `<status>` — Current status of the change (e.g., `dev-complete`, `bugfix-resolved`, `docs-updated`)

    **Example:** `P4ME-15-dev-complete` or `P4ME-99-bugfix-resolved`

21. **Push all committed files to the remote origin repository:**
    ```bash
    git push origin <branch-name>
    ```

22. **Rebase onto latest main (Gate 5.5):** Before creating the PR, ensure your branch is up-to-date:
    ```bash
    git fetch origin main
    git rebase origin/main   # resolve conflicts if any, then: git add + git rebase --continue
    git push --force-with-lease origin <branch-name>
    ```

23. **Create a Pull Request (PR)** from the feature branch to the target branch (typically `main` or `develop`):
    - Link the PR to the Jira artifact in the PR description
    - Include a summary of TDD phases completed, test results, and any notes for reviewers
    - Reference impacted Confluence pages or Figma designs where applicable
    - Request reviews from appropriate team members

---

### Phase 6: Build & Deploy (Post-PR)

After the PR is created and merged (or if deploying directly from the feature branch), build and deploy the app to all supported platforms. **Run each platform sequentially — do not parallelize.** Wait for each build/deploy to complete before starting the next.

#### 5a. iOS — Build, Deploy & Run in Simulator

24. **Identify an available iPhone simulator** (prefer the latest model):
   ```bash
   xcrun simctl list devices available | grep -i iphone
   ```

25. **Boot the selected iPhone simulator:**
   ```bash
   xcrun simctl boot "<iPhone Model>"
   ```

26. **Ensure dependencies are up to date:**
   ```bash
   flutter pub get
   ```

27. **Build and deploy to the iOS simulator (debug mode):**
   ```bash
   flutter run -d "<iPhone Model>"
   ```

28. **Bring the Simulator window to the foreground** so the app is visible:
   ```bash
   open -a "Simulator" 2>/dev/null || osascript -e 'tell application "Simulator" to activate' 2>/dev/null
   ```
   If the above fails (newer Xcode versions may not have a standalone Simulator.app), try:
   ```bash
   # Check for any simulator UI process and activate it
   ps aux | grep -i "[S]imulator" | head -5
   ```

29. **Verify the app launches** in the simulator — check for errors in the console output.

30. **Stop the flutter run process** cleanly:
   ```bash
   pkill -f "flutter run" 2>/dev/null; sleep 1
   ```

#### 6b. Android — Build, Deploy & Run in Emulator

31. **List available Android virtual devices (AVDs):**
   ```bash
   avdmanager list avd
   # or: flutter emulators --launch <emulator-id>
   ```

32. **Launch the Android emulator:**
   ```bash
   flutter emulators --launch <emulator-id>
   # Wait for it to boot (check with: adb devices)
   sleep 30
   ```

33. **Ensure dependencies are up to date:**
   ```bash
   flutter pub get
   ```

34. **Build and deploy to the Android emulator:**
   ```bash
   flutter run -d <emulator-id>
   ```

35. **Verify the app launches** in the emulator — check for errors in the console output.

36. **Stop the flutter run process** cleanly:
   ```bash
   pkill -f "flutter run" 2>/dev/null; sleep 1
   ```


---

## Quick Reference Checklist

| Step | Action | Done? | Gate |
|------|--------|-------|------|
| 0 | Identify Jira key, Story number, and acceptance criteria | ☐ | Gate 0 |
| 0b | Post Gate 0 comment to Jira (story identified) | ☐ | Gate 0 |
| 1 | Create branch: `<owner>-<phase>-STORY###` (use Story number, NOT Jira key) | ☐ | Gate 1 |
| 1a | Push branch to remote origin | ☐ | Gate 1 |
| 1b | Verify branch on remote (`git branch -r \| grep <branch-name>`) | ☐ | Gate 1 |
| 1c | Post Gate 1 comment to Jira (branch name + remote verified) | ☐ | Gate 1 |
| 2 | Checkout and set active branch | ☐ | Gate 1 |
| 3 | Transition Jira issue to In Progress: `acli jira workitem transition --key <KEY> --status "In Progress"` | ☐ | Gate 2 |
| 4 | Verify issue appears in correct swimlane/column on sprint board | ☐ | Gate 2 |
| 5 | Assign Jira artifact: `acli jira workitem assign --key <KEY> --assignee "@me"` | ☐ | Gate 2 |
| 6 | Post Gate 2 comment to Jira (transition + assignee confirmed) | ☐ | Gate 2 |
| **GATE 0.5** | Defect analysis (defects only): reproduce, root cause, validity verdict → post as Jira comment | ☐ | Gate 0.5 |
| **GATE 1 & 2 PASSED — Red Phase may begin** | | | |
| 7 | Review design docs (Confluence/Figma) — if no changes needed, note "No design changes required" in Jira | ☐ | Gate 2.5 |
| 8 | QA Agent reads story from Jira and creates test plan mapping AC → tests | ☐ | Gate 2.5 |
| 9 | Write failing tests for every acceptance criterion (Red Phase) | ☐ | Gate 2.5 |
| 10 | Verify ALL new tests FAIL with `flutter test` | ☐ | Gate 2.5 |
| 11 | Post Red Phase results to Jira comment (files, coverage matrix, failure output) | ☐ | Gate 2.5 |
| **GATE 2.5 PASSED — Green Phase may begin** | | | |
| 10 | Read failing tests from QA — they define "done" | ☐ | Gate 3 |
| 11 | Implement ONLY enough code to make red tests pass (Green Phase) | ☐ | Gate 3 |
| 12 | Post Green Phase comment to Jira (what was implemented) | ☐ | Gate 3 |
| 13 | Refactor production and test code with safety net of passing tests (Refactor Phase) | ☐ | Gate 4 |
| 14 | Run `flutter test` — ensure ALL tests (new + existing) pass | ☐ | Gate 4 |
| 15 | Post final TDD results to Jira comment (Red/Green/Refactor summary, full output, AC matrix) | ☐ | Gate 4 |
| **GATE 4 PASSED — Status transition now permitted** | | | |
| 16 | Only after tests posted: Transition Jira status to In Review (`acli jira workitem transition --key <KEY> --status "In Review"`) | ☐ | Gate 5 |
| **GATE 0.5** | Defect resolution comment (defects only): root cause, fix applied, files changed → post as Jira comment | ☐ | Gate 4 |
| 17 | Commit with message: `<jira-id>-<status>` | ☐ | Gate 5 |
| 18 | Push changes to remote origin | ☐ | Gate 5 |
| 19 | Create Pull Request referencing TDD phases and Jira test results | ☐ | Gate 5 |
| 20 | Post PR comment to Jira (PR link + review request) | ☐ | Gate 5 |
| 21 | Rebase onto latest main (`git fetch origin main && git rebase origin/main`) | ☐ | Gate 5.5 |
| 22 | Force-push rebased branch (`git push --force-with-lease`) | ☐ | Gate 5.5 |
| 23 | Post rebase comment to Jira (clean rebase confirmed) | ☐ | Gate 5.5 |
| **GATE 5 PASSED — Build & Deploy now permitted** | | | |
| 15a | iOS: Boot iPhone simulator → `flutter pub get` → `flutter run -d "<iPhone>"` → verify launch → stop | ☐ | Phase 6 |
| 15b | Android: Launch AVD emulator → `flutter pub get` → `flutter run -d <emulator>` → verify launch → stop | ☐ | Phase 6 |
| 15c | macOS: `flutter pub get` → `flutter run -d macos` → verify launch → stop | ☐ | Phase 6 |
| 15d | Chrome Web: `flutter pub get` → `flutter run -d chrome` → verify launch → stop | ☐ | Phase 6 |

---

## TDD Quick Reference — Red → Green → Refactor

```
┌─────────────────────────────────────────────────────────────┐
│                    TDD CYCLE (per acceptance criterion)      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  RED    ← QA writes failing test(s) for one AC              │
│   │       flutter test → FAIL confirmed                     │
│   ▼                                                       │
│  GREEN  ← Dev writes MINIMAL code to make test pass         │
│   │       flutter test → PASS (all tests)                   │
│   ▼                                                       │
│  REFACT← Dev cleans up code + tests, all still pass         │
│   │       flutter test → PASS (all tests)                   │
│   ▼                                                       │
│  Next AC → repeat cycle                                     │
│                                                             │
└─────────────────────────────────────────────────────────────┘

Per Story Flow:
  Gate 2.5 (Red Phase):  ALL failing tests written first
  Gate 3   (Green Phase): ALL red tests turned green
  Gate 4   (Refactor):    Code cleaned, all still passing
```

