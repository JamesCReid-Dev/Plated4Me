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

6. **Hive adapters** (fallback only):
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

### Gate 0: Story Identification & Context

Before touching any code, you MUST:
1. Use the `acli` interface for **all** Jira and Confluence interactions. **Never use MCP for Jira or Confluence operations.**
2. Use GitHub MCP for all GitHub interactions.
3. Identify the Jira issue key (e.g., ${JIRA_STORY_PREFIX}001 ) and the Story number (e.g., ${JIRA_STORY_PREFIX}003 ) from the user's request or by searching Jira. If there is no issue found, use `ISSUE-TBD` as default. If there is no story found, use `STORY-TBD` as default.
4. Retrieve the full story details including acceptance criteria from Jira.
5. If design documentation is referenced, fetch Confluence pages for review.

**GATE CHECK:** Confirm you have the correct Jira key, Story number, and acceptance criteria before proceeding. **DO NOT proceed to Gate 1 until this is complete.**

### Gate 1: Branch Creation & Remote Push

Before making ANY code changes, you MUST:
1. Create a new Git branch using the naming pattern `<owner>-<phase>-STORY###` where `STORY###` is the Story number (NOT the Jira issue key).
2. Push the branch to remote origin with `git push -u origin <branch-name>`.
3. Verify the branch exists on remote by running `git branch -r | grep <branch-name>`.

**GATE CHECK:** Confirm the branch is created locally AND pushed to remote before proceeding. **DO NOT proceed to Gate 2 until this is complete.**

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

**GATE CHECK:** Confirm all acceptance criteria are met and ALL tests (new + existing) pass before proceeding to Gate 4. **DO NOT proceed to Gate 4 until this is complete.**

### Gate 4: TDD Refactor Phase & Final Test Verification

Before transitioning the issue status, you MUST complete both the Refactor Phase and test verification:

1. **Refactor Phase (Rf):** With tests as a safety net, refactor production code to apply DRY, SRP, and Clean Architecture principles. Also clean up any duplicated test setup. Run full suite after every change — all tests must continue passing.
2. **Run `flutter test`** and ensure ALL tests pass (new + existing + refactored).
3. **Post the full test results as a comment on the Jira story** in the required format below.

> **Rule:** Refactoring is NOT adding features. If you discover new functionality needed, create a new story for it rather than expanding scope during refactor.

**GATE CHECK:** Confirm test results are posted as a Jira comment before proceeding. **DO NOT transition to In Review until this is complete.**

### Gate 5: Commit, Push & PR (Post-TDD)

After all TDD phases (Red → Green → Refactor) are complete and tests are posted:
1. **Transition the Jira issue status to `In Review`** — this MUST be done before committing/pushing/creating a PR.
   ```bash
   acli jira workitem transition --key <KEY> --status "In Review"
   ```
2. Stage and commit with message `<jira-id>-<status>`. Include a summary of which TDD phase each commit represents if multiple commits are made.
3. Push to remote origin.
4. Create a Pull Request linking to the Jira artifact, referencing:
   - The Red Phase test files created by QA
   - The Green Phase implementation
   - Any Refactor changes
   - The Jira comment with final test results

**GATE CHECK:** Confirm PR is created and linked before considering the story complete. **The issue must be in "In Review" status before this gate passes.**

### Gate 5.5: Rebase onto Latest Main (Pre-Merge)

Before merging the PR, you MUST ensure your branch is up-to-date with main to avoid merge conflicts:

1. **Fetch latest main:** `git fetch origin main`
2. **Rebase onto main:** `git rebase origin/main`
3. **Resolve any conflicts immediately** — do NOT defer conflict resolution to the PR merge step. Edit conflicted files, `git add` resolved files, then `git rebase --continue`.
4. **Force-push the rebased branch:** `git push --force-with-lease origin <branch-name>`
5. **Verify the PR is clean** — no merge conflicts should remain when viewing the PR on GitHub.

> **Why this matters:** While you work on a feature branch, other PRs may be merged to main. Rebasing before merge ensures your changes sit cleanly on top of the latest code, making the squash-merge conflict-free. Pulling latest *before* branch creation is not sufficient — main continues advancing during development.

**GATE CHECK:** Confirm branch is rebased onto latest main with no conflicts before proceeding to Gate 6. **DO NOT proceed until this is complete.**

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
6. **Never return `null` for `Future<T>` or `String`** — handle gracefully instead.
7. **Use `const` constructors where possible** — Flutter performance best practice.
8. **Keep widgets small and composable** — follow Flutter widget composition patterns.
9. **Document public APIs with doc comments (`///`)** — especially entities, providers, and repository interfaces.
10. **When in doubt, match existing code style** — refer to `lib/domain/entities/entities.dart` as a reference for entity conventions.
11. **Follow TDD discipline** — tests must fail before implementation (Red), pass after implementation (Green), then clean up (Refactor). Never write production code without a failing test driving it.

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

### Phase 3: TDD Red Phase — QA Test Creation (Gate 2 → Gate 2.5)

6. **Review design documentation** for impacted changes:
   - Check Confluence pages in the **"Plated4Me"** space if architecture, API specs, or user-facing docs are affected by this story
   - Check Figma designs if UI/UX changes are made
   - If NO design updates needed: note "No design changes required for this story" in Jira comments

7. **Act as (or invoke) the QA Agent** to read the full story from Jira, including all acceptance criteria and design context.

8. **Create a test plan** mapping each acceptance criterion to specific test cases across appropriate layers:
   - Domain tests for entity logic and value objects
   - Application tests for providers and use cases
   - Presentation tests for widgets and UI behavior
   - Infrastructure tests for storage implementations

9. **Write failing tests** for every acceptance criterion — these tests MUST fail when run because the production code does not yet exist:
   - One test file per logical feature area, following existing naming patterns
   - Use `group()` to organize tests by entity/provider/widget
   - Include at least one negative/edge-case test per AC
   - Follow all project conventions (package imports, explicit return types, no print)

10. **Verify ALL new tests FAIL** by running `flutter test` on the newly created files. Confirm each failure is genuine.

11. **Post Red Phase results to Jira** as a comment:
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

12. **Green Phase:** Read the failing tests created in the Red Phase — they define "done." Implement ONLY enough production code to make those tests pass. No extra features, no scope expansion.

13. **Verify each test turns green** as you implement. After each passing test, run the full suite to ensure no existing test breaks.

14. **Refactor Phase (Rf):** With tests as a safety net, refactor production code to apply DRY, SRP, and Clean Architecture principles. Also clean up duplicated test setup. Run full suite after every change — all tests must continue passing. Refactoring is NOT adding features; if new functionality is needed, create a new story.

15. **Execute final `flutter test`** and ensure ALL tests pass (new + existing + refactored).

16. **Post final test results to Jira** as a comment:
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

17. **Only after ALL tests pass and results are posted as a Jira comment, transition to In Review.**

### Phase 5: Code Review & Pull Request (Gate 4 → Gate 5)

18. **Update the Jira artifact status to `In Review`** — this is the FIRST step of Gate 5, done BEFORE commit/push/PR.
    ```bash
    acli jira workitem transition --key <KEY> --status "In Review"
    ```
    > **⚠️ CRITICAL:** This status transition MUST happen before any git operations (commit, push, PR). If you forget this step, the story will remain stuck in "In Progress" even after all code is complete. Always do this as your very first action when entering Gate 5.

19. **Stage and commit all changed files** with a commit message following this pattern:
    ```
    <jira-artifact-id>-<status>
    ```
    - `<jira-artifact-id>` — The Jira issue key (e.g., `P4ME-123`)
    - `<status>` — Current status of the change (e.g., `dev-complete`, `bugfix-resolved`, `docs-updated`)

    **Example:** `P4ME-15-dev-complete` or `P4ME-99-bugfix-resolved`

20. **Push all committed files to the remote origin repository:**
    ```bash
    git push origin <branch-name>
    ```

21. **Rebase onto latest main (Gate 5.5):** Before creating the PR, ensure your branch is up-to-date:
    ```bash
    git fetch origin main
    git rebase origin/main   # resolve conflicts if any, then: git add + git rebase --continue
    git push --force-with-lease origin <branch-name>
    ```

22. **Create a Pull Request (PR)** from the feature branch to the target branch (typically `main` or `develop`):
    - Link the PR to the Jira artifact in the PR description
    - Include a summary of TDD phases completed, test results, and any notes for reviewers
    - Reference impacted Confluence pages or Figma designs where applicable
    - Request reviews from appropriate team members

---

### Phase 6: Build & Deploy (Post-PR)

After the PR is created and merged (or if deploying directly from the feature branch), build and deploy the app to all supported platforms. **Run each platform sequentially — do not parallelize.** Wait for each build/deploy to complete before starting the next.

#### 5a. iOS — Build, Deploy & Run in Simulator

23. **Identify an available iPhone simulator** (prefer the latest model):
   ```bash
   xcrun simctl list devices available | grep -i iphone
   ```

24. **Boot the selected iPhone simulator:**
   ```bash
   xcrun simctl boot "<iPhone Model>"
   ```

25. **Ensure dependencies are up to date:**
   ```bash
   flutter pub get
   ```

26. **Build and deploy to the iOS simulator (debug mode):**
   ```bash
   flutter run -d "<iPhone Model>"
   ```

27. **Bring the Simulator window to the foreground** so the app is visible:
   ```bash
   open -a "Simulator" 2>/dev/null || osascript -e 'tell application "Simulator" to activate' 2>/dev/null
   ```
   If the above fails (newer Xcode versions may not have a standalone Simulator.app), try:
   ```bash
   # Check for any simulator UI process and activate it
   ps aux | grep -i "[S]imulator" | head -5
   ```

28. **Verify the app launches** in the simulator — check for errors in the console output.

29. **Stop the flutter run process** cleanly:
   ```bash
   pkill -f "flutter run" 2>/dev/null; sleep 1
   ```

#### 5b. Android — Build, Deploy & Run in Emulator

30. **List available Android virtual devices (AVDs):**
   ```bash
   avdmanager list avd
   # or: flutter emulators --launch <emulator-id>
   ```

31. **Launch the Android emulator:**
   ```bash
   flutter emulators --launch <emulator-id>
   # Wait for it to boot (check with: adb devices)
   sleep 30
   ```

32. **Ensure dependencies are up to date:**
   ```bash
   flutter pub get
   ```

33. **Build and deploy to the Android emulator:**
   ```bash
   flutter run -d <emulator-id>
   ```

34. **Verify the app launches** in the emulator — check for errors in the console output.

35. **Stop the flutter run process** cleanly:
   ```bash
   pkill -f "flutter run" 2>/dev/null; sleep 1
   ```


---

## Quick Reference Checklist

| Step | Action | Done? | Gate |
|------|--------|-------|------|
| 0 | Identify Jira key, Story number, and acceptance criteria | ☐ | Gate 0 |
| 1 | Create branch: `<owner>-<phase>-STORY###` (use Story number, NOT Jira key) | ☐ | Gate 1 |
| 2 | Push branch to remote origin | ☐ | Gate 1 |
| 3 | Checkout and set active branch | ☐ | Gate 1 |
| 4 | Transition Jira issue to In Progress: `acli jira workitem transition --key <KEY> --status "In Progress"` | ☐ | Gate 2 |
| 5 | Verify issue appears in correct swimlane/column on sprint board | ☐ | Gate 2 |
| 6 | Assign Jira artifact: `acli jira workitem assign --key <KEY> --assignee "@me"` | ☐ | Gate 2 |
| **GATE 1 & 2 PASSED — Red Phase may begin** | | | |
| 7 | Review design docs (Confluence/Figma) — if no changes needed, note "No design changes required" in Jira | ☐ | Gate 2.5 |
| 8 | QA Agent reads story from Jira and creates test plan mapping AC → tests | ☐ | Gate 2.5 |
| 9 | Write failing tests for every acceptance criterion (Red Phase) | ☐ | Gate 2.5 |
| 10 | Verify ALL new tests FAIL with `flutter test` | ☐ | Gate 2.5 |
| 11 | Post Red Phase results to Jira comment (files, coverage matrix, failure output) | ☐ | Gate 2.5 |
| **GATE 2.5 PASSED — Green Phase may begin** | | | |
| 12 | Read failing tests from QA — they define "done" | ☐ | Gate 3 |
| 13 | Implement ONLY enough code to make red tests pass (Green Phase) | ☐ | Gate 3 |
| 14 | Refactor production and test code with safety net of passing tests (Refactor Phase) | ☐ | Gate 4 |
| 15 | Run `flutter test` — ensure ALL tests (new + existing) pass | ☐ | Gate 4 |
| 16 | Post final TDD results to Jira comment (Red/Green/Refactor summary, full output, AC matrix) | ☐ | Gate 4 |
| **GATE 4 PASSED — Status transition now permitted** | | | |
| 17 | ⚠️ FIRST STEP: Transition Jira status to In Review (`acli jira workitem transition --key <KEY> --status "In Review"`) — MUST happen before commit/push/PR | ☐ | Gate 5 |
| 18 | Commit with message: `<jira-id>-<status>` | ☐ | Gate 5 |
| 19 | Push changes to remote origin | ☐ | Gate 5 |
| 20 | Rebase onto latest main (`git fetch origin main && git rebase origin/main`) | ☐ | Gate 5.5 |
| 21 | Force-push rebased branch (`git push --force-with-lease`) | ☐ | Gate 5.5 |
| 22 | Create Pull Request referencing TDD phases and Jira test results | ☐ | Gate 5 |
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

