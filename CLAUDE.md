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

## Testing Guidelines

- Test files go in `test/` alongside `lib/`
- Follow the existing naming pattern: `main_test.dart`, `widget_test.dart`
- Use `flutter_test` package for widget and unit tests
- Mock repositories/interfaces at layer boundaries
- Test domain logic in isolation (no Flutter framework needed)

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
2. Assign the Jira artifact to the correct person.
3. Verify the issue appears in the active column on the sprint board.

**⚠️ If Jira operations fail with "Client must be authenticated":**
- The API token in `.claude/.atlassian.env` has expired or been revoked
- Regenerate at https://id.atlassian.com/manage-profile/security/api-tokens
- Update `ATLASSIAN_API_TOKEN` in `.claude/.atlassian.env`
- Test with: `bash .claude/scripts/jira.sh me`

**GATE CHECK:** Confirm Jira is initialized and the issue is in `In Progress` before proceeding. **DO NOT proceed to Gate 3 until this is complete.**

### Gate 3: Implementation (Code Changes Allowed)

Only after Gates 0, 1, and 2 are passed may you begin implementing code changes. All implementation must follow Clean Architecture boundaries, naming conventions, and testing guidelines defined elsewhere in this document.

**GATE CHECK:** Confirm all acceptance criteria are met and tests pass before proceeding to Gate 4. **DO NOT proceed to Gate 4 until this is complete.**

### Gate 4: Test Results Posted to Jira

Before transitioning the issue status, you MUST:
1. Run `flutter test` and ensure ALL tests pass.
2. Post the full test results as a comment on the Jira story in the required format.

**GATE CHECK:** Confirm test results are posted as a Jira comment before proceeding. **DO NOT transition to In Review until this is complete.**

### Gate 5: Commit, Push & PR

After all previous gates are passed and tests are posted:
1. Transition the Jira issue status (e.g., to `In Review`).
2. Stage and commit with message `<jira-id>-<status>`.
3. Push to remote origin.
4. Create a Pull Request linking to the Jira artifact.

**GATE CHECK:** Confirm PR is created and linked before considering the story complete.

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
acli jira workitem transition <KEY> --transition "Done"

# Add completion comments
acli jira workitem comment <KEY> "Completed in Sprint N. See commit <hash>."
```

### Known Limitations — Story Association via CLI

**The `acli` tool and REST API (with basic auth) cannot add issues to sprints.** This is a limitation of the available CLI tools:

- `acli jira sprint create/update/view/list-workitems` — works for managing sprint metadata
- `acli jira workitem edit` — does NOT support setting the Sprint field or custom fields
- REST API v2/v3 PATCH — returns 400 Bad Request for sprint field updates with basic auth
- Agile API POST `/sprint/{id}/issues` — requires OAuth authentication (not available via curl)

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
| "Client must be authenticated" | API token expired/revoked | Regenerate at id.atlassian.com, update `.claude/.atlassian.env` |
| No stories in sprint | Stories not linked to Sprint field | Link manually in Jira UI (see Known Limitations above) |
| Board shows wrong status | Status not transitioned after coding | Run `acli jira workitem transition <KEY> --transition "Done"` |
| "Unknown command" from jira.sh | Script path issue | Use absolute: `bash .claude/scripts/jira.sh` |

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

# Jira — search stories for current sprint
bash .claude/scripts/jira.sh search "sprint = <NAME> AND status != Closed"

# Jira — check auth
bash .claude/scripts/jira.sh me
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

### Phase 3: Implementation & Testing (Gate 2 → Gate 3)

6. **Implement the story requirements** following Clean Architecture boundaries, naming conventions, and code generation rules defined elsewhere in this document.

7. **Ensure automated testing is part of the story acceptance criteria (A/C):**
   - Write unit tests for domain logic and business rules
   - Write widget/integration tests for UI changes
   - Ensure all existing tests continue to pass
   - Run `flutter test` locally before committing

8. **Review design documentation for impacted changes:**
   - Check Confluence pages in the **"Plated4Me"** space if architecture, API specs, or user-facing docs are affected by this story
   - Check Figma designs if UI/UX changes are made
   - If NO design updates needed: note "No design changes required for this story" in Jira comments
   - If design updates ARE needed: update Confluence/Figma first, then link to updated design in Jira before proceeding

9. **Execute all tests and add results to the Jira artifact:**
    - Run `flutter test` locally and ensure ALL tests pass (no failures, no errors)
    - Capture the full test output including: total tests run, passed/failed counts, any coverage metrics
    - Post the test results as a **comment on the Jira story** with the following format:
      ```
      ## Test Results
      - Total tests: X
      - Passed: X
      - Failed: 0
      - Errors: 0

      ### Test Output
      [paste full flutter test output here]

      ### Files Tested
      - test/path/to/file_test.dart
      - test/another_file_test.dart
      ```
    - Include any manual testing notes if applicable

10. **Only after ALL tests pass and results are posted as a Jira comment, transition to In Review.**

### Phase 4: Code Review & Pull Request (Gate 3 → Gate 5)

10. **Update the Jira artifact status to `In Review`** once implementation is complete and all acceptance criteria are met.

11. **Stage and commit all changed files** with a commit message following this pattern:
    ```
    <jira-artifact-id>-<status>
    ```
    - `<jira-artifact-id>` — The Jira issue key using prefix `IS-` (e.g., `IS-123`)
    - `<status>` — Current status of the change (e.g., `dev-complete`, `bugfix-resolved`, `docs-updated`)

    **Example:** `IS-123-dev-complete` or `IS-99-bugfix-resolved`

12. **Push all committed files to the remote origin repository:**
    ```bash
    git push origin <branch-name>
    ```

13. **Create a Pull Request (PR)** from the feature branch to the target branch (typically `main` or `develop`):
    - Link the PR to the Jira artifact in the PR description
    - Include a summary of changes, test results, and any notes for reviewers
    - Reference impacted Confluence pages or Figma designs where applicable
    - Request reviews from appropriate team members

---

## Quick Reference Checklist

| Step | Action | Done? | Gate |
|------|--------|-------|------|
| 0 | Identify Jira key, Story number, and acceptance criteria | ☐ | Gate 0 |
| 1 | Create branch: `<owner>-<phase>-STORY###` (use Story number, NOT Jira key) | ☐ | Gate 1 |
| 2 | Push branch to remote origin | ☐ | Gate 1 |
| 3 | Checkout and set active branch | ☐ | Gate 1 |
| 4 | Transition Jira issue to In Progress (proper workflow transition, not raw status) | ☐ | Gate 2 |
| 5 | Verify issue appears in correct swimlane/column on sprint board | ☐ | Gate 2 |
| 6 | Assign Jira artifact to correct person | ☐ | Gate 2 |
| **GATE 1 & 2 PASSED — Code changes now permitted** | | | |
| 7 | Implement story per acceptance criteria | ☐ | Gate 3 |
| 8 | Review design docs (Confluence/Figma) — if no changes needed, note "No design changes required" in Jira | ☐ | Gate 3 |
| 9 | Run `flutter test` — ensure ALL tests pass | ☐ | Gate 4 |
| 10 | Post test results as comment on Jira story (total, passed/failed, full output) | ☐ | Gate 4 |
| **GATE 4 PASSED — Status transition now permitted** | | | |
| 11 | Only after tests posted: Transition Jira status to In Review | ☐ | Gate 5 |
| 12 | Commit with message: `<jira-id>-<status>` | ☐ | Gate 5 |
| 13 | Push changes to remote origin | ☐ | Gate 5 |
| 14 | Create Pull Request and request reviews | ☐ | Gate 5 |

