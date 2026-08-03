# CODING_STANDARDS.md

# Purchase Passport – Swift, SwiftUI, and SwiftData Coding Standards

## 1. Purpose

These standards define the default coding style and engineering rules for this project.

They apply to all production code and tests unless an exception is explicitly approved.

---

## 2. General Swift Standards

- Use `PascalCase` for types and `camelCase` for properties, methods, and local variables.
- Prefer `struct` unless reference semantics are required.
- Prefer `let` over `var` whenever mutability is not required.
- Avoid force-unwrapping (`!`) and forced casting (`as!`) in production code.
- Keep functions focused and short; extract helpers when one function handles multiple concerns.
- Prefer explicit domain types and enums over primitive strings for business concepts.
- Keep files focused on one primary responsibility.
- Use `private` and `fileprivate` to limit visibility by default.
- Prefer `async`/`await` over callback-based APIs and avoid Combine unless there is a specific justified need.

---

## 3. SwiftUI Standards

- Keep views declarative and focused on rendering and user interaction.
- Keep persistence, file operations, and heavy business logic out of view bodies.
- Use `@State` for local view state and `@Bindable`/`@Observable` models when shared mutable state is required.
- Use `@MainActor` for state mutations that update UI.
- Break large views into smaller feature-focused subviews.
- Use `NavigationSplitView` patterns consistent with the architecture document.
- Prefer system controls and platform-consistent macOS behavior.
- Provide accessibility labels/hints for controls that are not self-explanatory.
- Avoid long-running work on the main actor; use async tasks and cancellation where appropriate.

---

## 4. SwiftData Standards

- Model entities with clear ownership and explicit relationship delete rules.
- Persist stable raw values for enums used in stored models.
- Keep schema evolution deliberate and migration-aware.
- Use `Decimal` for monetary amounts and store currency separately (for example, ISO code) rather than using `Double` for financial values.
- Define stable custom-field identity keys so user-defined fields can be renamed without data loss.
- Use `@Query` for straightforward list/read concerns in UI.
- Move complex fetch, filtering, or cross-entity coordination into repository/service boundaries.
- Use in-memory containers for unit/persistence tests where practical.
- Validate data before persistence and surface recoverable errors to the UI.
- Do not store large binary attachments directly in SwiftData unless explicitly justified.
- Prefer reusable entity references over duplicated free-text fields when the same party or concept appears across multiple records.
- Store enough metadata to support document version history where a file is replaced.

---

## 5. Error Handling and Logging

- Use typed errors with meaningful cases.
- Separate validation errors from persistence and file-system errors.
- Show actionable user-facing errors and retain in-progress user input after failure.
- Avoid `fatalError` for recoverable runtime conditions.
- Do not log sensitive document content or personal information.

---

## 6. Concurrency

- Prefer structured concurrency.
- Keep UI mutations on the main actor.
- Run long-running import/export and file operations off the main actor.
- Support cancellation in long-running tasks.
- Do not suppress concurrency warnings without explicit justification.

---

## 7. Testing Standards

- Use Swift Testing and XCTest as appropriate for the target.
- Add or update tests for behavior changes when practical.
- Prioritise tests for validation rules, calculations, persistence relationships, and critical user flows.
- Keep tests deterministic and isolated.
- Use clear naming that describes the behavior under test.
- Follow [TESTING_STRATEGY.md](TESTING_STRATEGY.md) for test-layer selection.

---

## 8. Documentation and Change Discipline

- Update docs when behavior, architecture, or standards change.
- Keep Markdown links valid and use repository-relative links inside `docs/`.
- Limit changes to requested scope; avoid opportunistic refactoring.
- Summarise all created/modified files at task completion.

---

## 9. Source Control

- One logical task per commit.
- Use Conventional Commit messages.
- Push only after successful manual verification.
- Do not rewrite published history.
- Do not create commits unless explicitly requested.
