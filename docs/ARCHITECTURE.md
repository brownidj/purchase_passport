# ARCHITECTURE.md

# Purchase Passport – High-Level Architecture

## 1. Purpose

This document defines the high-level architecture and implementation boundaries for
Purchase Passport, a native macOS application written in Swift.

It complements:

- `docs/FUNCTIONAL_SPECIFICATION.md`, which defines what the application must do
- `docs/IMPLEMENTATION_PLAN.md`, which defines the phased delivery sequence
- `docs/CURRENT_STATE.md`, which defines how Codex or another AI coding assistant must work on the project
- `docs/CODING_STANDARDS.md`, which defines coding conventions for Swift, SwiftUI and SwiftData
- `docs/TESTING_STRATEGY.md`, which defines test-layer selection and verification priorities

The architecture should remain stable unless a change is explicitly reviewed and approved.
Implementation work must preserve the separation of concerns and avoid introducing
functionality from later phases.

---

## 2. Target Platform and Technology

- Platform: macOS
- Language: Swift
- User interface: SwiftUI
- Persistence: SwiftData
- Concurrency: Swift Concurrency using `async` and `await`
- Testing: XCTest and Swift Testing where appropriate
- Project system: Xcode
- Source control: Git
- Apple frameworks should be preferred over third-party dependencies

Third-party packages should not be introduced unless they provide a clear, documented
benefit that cannot reasonably be achieved with native Apple frameworks.

---

## 3. Architectural Principles

The project should follow these principles:

- Provide a native macOS user experience.
- Keep the architecture straightforward and maintainable.
- Separate presentation, domain logic, persistence and external services.
- Keep Swift files small and focused on one primary responsibility.
- Keep business rules independent of specific views where practical.
- Prefer strongly typed models and enums over loosely structured dictionaries.
- Use dependency injection where it improves testability or isolates services.
- Avoid global mutable state.
- Keep long-running and file-system operations off the main actor.
- Use `@MainActor` for state and operations that directly update the interface.
- Use progressive disclosure so that simple purchase records remain easy to create.
- Preserve user data and require confirmation before destructive operations.
- Design features so that they can be implemented and verified one phase at a time.

---

## 4. Application Structure

A feature-oriented structure is preferred over placing every file of the same technical
type into a single large directory.

Suggested structure:

```text
Purchase Passport/
├── App/
│   ├── PurchasePassportApp.swift
│   ├── AppCommands.swift
│   └── AppEnvironment.swift
│
├── Features/
│   ├── Dashboard/
│   ├── Purchases/
│   ├── Contacts/
│   ├── Documents/
│   ├── Warranties/
│   ├── Interactions/
│   ├── Servicing/
│   ├── Repairs/
│   ├── Timeline/
│   ├── Search/
│   ├── Export/
│   └── Settings/
│
├── Domain/
│   ├── Models/
│   ├── Enums/
│   ├── ValueTypes/
│   └── Validation/
│
├── Persistence/
│   ├── ModelContainer/
│   ├── Repositories/
│   ├── Migrations/
│   └── SeedData/
│
├── Services/
│   ├── Documents/
│   ├── Reminders/
│   ├── ImportExport/
│   ├── Search/
│   └── Backup/
│
├── Shared/
│   ├── Components/
│   ├── Extensions/
│   ├── Utilities/
│   └── Resources/
│
└── PreviewContent/
```

The exact folders may evolve, but feature boundaries and responsibilities should remain
clear. Do not create empty folders or placeholder abstractions before they are needed.

---

## 5. Presentation Architecture

SwiftUI views should be responsible primarily for:

- presenting state
- collecting user input
- invoking clearly defined actions
- displaying validation and errors
- participating in macOS navigation and commands

Views should not contain substantial persistence, file-system, export or business logic.

Use feature-specific observable state only where it adds value. A view model or
`@Observable` feature model may be introduced when a view has substantial state,
coordination or asynchronous behaviour. Simple screens should not be wrapped in
unnecessary view-model layers.

Reusable views should be placed in the relevant feature unless they are genuinely shared
across several features.

### Root-composition boundary (mandatory)

`AppRootView` is a composition and wiring root. It may own high-level state and routing,
but it must not become the implementation location for feature behavior.

- `AppRootView` responsibilities:
  - top-level section selection and composition
  - passing bindings/actions to feature views
  - delegating workflows to extracted coordinators/services
- Feature responsibilities:
  - list/detail/editor rendering
  - feature-specific interaction handling
  - feature-specific formatting and helpers

`AppRootView` should delegate feature logic to focused collaborators (for example,
selection/workflow/editor-sheet coordinators) rather than expanding inline.

### Refactor trigger thresholds

To prevent large later refactors, extraction is required when any one of the following is
reached:

- Swift file exceeds ~400 lines
- single type exceeds ~12 stored properties for mixed concerns
- function exceeds ~50 lines or handles multiple concerns
- root-section switch logic grows without delegated feature composition

These are guardrails, not style preferences. Crossing a threshold requires an immediate
task-local extraction.

### Dependency direction rules

Feature dependencies must remain directional:

- `Features -> Domain, Services, Persistence boundaries`
- `Features` should not depend directly on other feature internals
- shared feature UI goes in explicit shared section-view files
- cross-feature behavior should be coordinated via root/coordinator or service boundaries

### Navigation testability rule

Primary navigation and row-selection surfaces must expose stable accessibility identifiers
for UI tests. Labels alone are insufficient for long-term UI test stability.

---

## 6. Navigation

The principal interface should use a native macOS three-column layout based on
`NavigationSplitView`:

1. Sidebar
2. Content list
3. Detail view

The sidebar may contain sections such as:

- Dashboard
- All Purchases
- Categories
- Warranties
- Reminders
- Repairs and Servicing
- Documents
- Complaints and Disputes
- Search
- Archived Records

Navigation state should be explicit and restorable where practical.

The application should also make appropriate use of:

- macOS menus and commands
- keyboard shortcuts
- toolbars
- context menus
- sheets for focused editing
- inspectors where supplementary details are better separated from primary content

The interface should not behave like an enlarged iPhone application.

---

## 7. Domain Model

The initial domain is expected to include the following principal entities:

- `Purchase`
- `PurchaseCategory`
- `Contact`
- `Organisation`
- `StoredDocument`
- `Warranty`
- `Interaction`
- `ComplaintCase`
- `ServiceRecord`
- `RepairRecord`
- `FaultRecord`
- `Reminder`
- `TimelineEvent`
- `FinancialTransaction`
- `Tag`
- `PurchaseTemplate`
- `CustomFieldDefinition`
- `CustomFieldValue`

Names may be refined during detailed model design, but entity responsibilities should
remain distinct.

### Relationship principles

- A purchase is the aggregate root for most lifecycle information.
- Contacts and organisations may be reused across purchases.
- Documents may be associated with a purchase and optionally with a warranty, repair,
  interaction, complaint or service event.
- Complaints should link to related interactions, documents, faults, repairs and timeline
  entries through stable identifiers.
- Timeline entries should be derived from or linked to source records where possible,
  rather than duplicating authoritative data.
- Deleting a purchase must not silently delete externally stored files without clear
  confirmation and a defined deletion policy.
- Relationship delete rules must be explicitly defined and tested.

### Value types and enums

Use enums and value types for stable concepts such as:

- purchase status
- purchase category
- document category
- interaction type
- warranty status
- repair status
- reminder priority
- payment type
- timeline event type
- money amount/currency pairs

Enums persisted by SwiftData should use stable raw values so that display labels can be
changed or localised without corrupting stored data.

---

## 8. Persistence

SwiftData should provide the primary structured-data store.

Persistence responsibilities should include:

- model container configuration
- schema evolution and migration planning
- relationship and delete-rule management
- validation before persistence
- predictable fetch and sort behaviour
- test-specific in-memory containers
- recovery or reporting when stored data cannot be loaded

SwiftUI views may use `@Query` for straightforward read-only or list queries. More complex
fetching, cross-feature operations and business rules should be isolated behind repository
or service boundaries when that improves clarity and testability.

The project must not assume that schema changes are harmless. Any change to a persisted
model should consider migration consequences before implementation.

---

## 9. Document and Attachment Storage

Large documents, images, manuals and other attachments should not be stored directly in
SwiftData as large binary properties unless a later technical assessment demonstrates a
clear reason.

The preferred model is:

- SwiftData stores attachment metadata and stable identifiers.
- File data is stored in an application-managed location.
- Security-scoped access is used where the user retains files outside the application
  container.
- Imported files receive collision-resistant internal names.
- Original filenames and content types are retained as metadata.
- Replacement/versioning metadata is retained when a document is superseded.
- File writes use coordinated and atomic operations where practical.
- Orphan detection and cleanup are handled deliberately.
- Missing or inaccessible files produce recoverable errors rather than crashes.

The document-storage strategy must support backup, export, restore and future migration.

---

## 10. Services

Services should encapsulate operations that do not belong in views or persisted entities.

Likely services include:

### `DocumentService`

Responsible for:

- importing files
- copying files into managed storage
- resolving stored file locations
- preview support
- replacement and deletion
- orphan detection

### `ReminderService`

Responsible for:

- calculating due and overdue states
- recurrence rules
- notification scheduling if notifications are introduced
- reminder completion and rescheduling

### `SearchService`

Responsible for:

- cross-entity search
- tokenisation and filtering
- ranked results where appropriate
- indexing strategy if required by scale

### `ImportExportService`

Responsible for:

- exporting purchase records
- generating reports
- creating portable archives
- validating imported archives
- preserving entity relationships

### `ComplaintService`

Responsible for:

- complaint and dispute lifecycle management
- chronology assembly from linked source records
- deadline and follow-up tracking
- complaint-specific export preparation

### `BackupService`

Responsible for:

- creating complete backups
- validating backup contents
- restoring structured data and attachments
- reporting partial or failed restores

Service protocols may be introduced when they improve isolation and testing. Protocols
should not be added merely to satisfy a pattern.

---

## 11. Error Handling and Validation

Errors should be represented by meaningful Swift error types.

The application should:

- validate user input before saving
- distinguish validation errors from persistence and file-system failures
- present actionable, non-technical error messages
- retain user-entered data when an operation fails
- log diagnostic details without exposing private document contents
- avoid silent data loss
- allow retry where appropriate

Fatal errors should not be used for recoverable runtime conditions.

---

## 12. Concurrency

Swift concurrency should be used deliberately.

- User-interface state updates must occur on the main actor.
- File imports, exports, hashing, archive generation and similar work should execute away
  from the main actor.
- Long-running operations should support cancellation where practical.
- Shared mutable service state should be actor-isolated when needed.
- Avoid detached tasks unless their lifetime and ownership are explicit.
- Do not suppress concurrency warnings without documenting the reason.

The project should be compatible with strict Swift concurrency checking.

---

## 13. Accessibility and macOS Conventions

The application must support:

- VoiceOver
- keyboard-only navigation
- Dynamic Type where applicable on macOS
- sufficient contrast
- descriptive labels and help text
- visible focus states
- adequately sized controls
- alternatives to icon-only actions
- reduced-motion preferences where animation is used

Use standard macOS controls and behaviours unless a custom implementation provides a
clear usability benefit.

---

## 14. Testing Strategy

Testing should focus on high-value behaviour.

Detailed test-layer guidance is defined in `docs/TESTING_STRATEGY.md`.

### Unit tests

Prioritise:

- validation
- date and warranty calculations
- reminder recurrence
- financial calculations
- status transitions
- search and filtering
- import/export validation
- file naming and attachment metadata
- migration-related logic

### Persistence tests

Use an in-memory SwiftData model container where possible to test:

- inserts and updates
- relationships
- delete rules
- fetches and sorting
- migrations when introduced

### UI tests

Reserve UI tests for important user journeys such as:

- creating a purchase
- editing and deleting a record
- importing a document
- recording a repair
- creating and progressing a complaint or dispute
- finding a purchase
- exporting a record

Avoid fragile UI tests that merely reproduce unit-test coverage.

---

## 15. AI Coding Assistant Workflow

Codex must read `docs/CURRENT_STATE.md` before undertaking implementation work.

The operating instructions in that document are mandatory. In particular, Codex should:

1. Implement one clearly defined task or numbered phase at a time.
2. Inspect only the documents and Swift files directly relevant to that task.
3. Preserve this architecture and avoid unrelated refactoring.
   - If thresholds in Section 5 are exceeded by the requested work, perform a scoped
     extraction in the same task rather than deferring to a future cleanup.
4. Explain the proposed implementation before editing.
5. List the files it expects to create or modify.
6. Stop after completing the requested phase.
7. Report all files created and modified.
8. State truthfully whether any builds or tests were run.
9. Provide the exact Xcode or command-line verification David should run manually.
10. Suggest a Git commit message but not create a commit unless explicitly instructed.

Codex must not independently broaden the task, redesign the architecture or implement
future phases.

### Swift-specific verification policy

Unless explicitly instructed otherwise, Codex should not run broad or time-consuming
verification commands such as:

```zsh
xcodebuild build
xcodebuild test
swift test
```

Instead, it should recommend the smallest appropriate manual verification step.

Examples include:

```zsh
xcodebuild   -project "Purchase Passport.xcodeproj"   -scheme "Purchase Passport"   -configuration Debug   -destination 'platform=macOS'   build
```

Or, where a specific test target or test class is affected:

```zsh
xcodebuild   -project "Purchase Passport.xcodeproj"   -scheme "Purchase Passport"   -destination 'platform=macOS'   -only-testing:"Purchase PassportTests/RelevantTestType"   test
```

Where Xcode provides the clearest workflow, Codex should tell David to:

1. build with **Product → Build**
2. run the app with **Product → Run**
3. run the relevant tests in the Test navigator
4. report only the relevant compiler or test output

Codex must not claim that a build, test or Git action was completed unless it actually
performed that action.

---

## 16. Required Completion Report

At the end of each implementation task, Codex should provide:

1. Summary of work completed
2. Files created
3. Files modified
4. Tests created or modified
5. Tests or builds run by Codex
6. Manual verification commands or Xcode actions
7. Manual verification checklist
8. Outstanding issues or risks
9. Current implementation phase status
10. Suggested Git commit message

When Codex has not run tests or builds, it should state:

```text
None — manual verification requested.
```

---

## 17. Security and Privacy

Purchase Passport may store receipts, financial information, correspondence and other
sensitive records.

The architecture should therefore:

- store data locally by default
- avoid unnecessary network access
- avoid embedding credentials in source code
- use application sandboxing
- minimise logging of personal data
- require explicit user action before sharing or exporting
- preserve security-scoped access correctly
- support safe deletion and backup
- avoid analytics or telemetry unless explicitly introduced and disclosed

No OpenAI API key or other secret should be stored in the application project merely
because Codex is used as a development tool.

---

## 18. Extensibility

The architecture should allow later addition of:

- iCloud synchronisation
- optional AI-assisted document extraction or summarisation
- system notifications
- richer reporting
- additional export formats
- integration with Contacts or Calendar
- iOS or iPadOS companion applications

These possibilities must not complicate the initial implementation prematurely.

---

## 19. Current Scope Exclusions

Unless added through an approved implementation phase, the following are outside the
initial scope:

- cloud synchronisation
- multi-user collaboration
- web or Android clients
- external account systems
- embedded generative-AI features
- third-party analytics
- automatic legal or consumer-rights advice
- background network integrations

---

## 20. Architectural Change Control

Before changing this architecture, Codex should:

1. identify the requirement that cannot be satisfied by the current design
2. explain the proposed change
3. list benefits, costs and migration implications
4. identify affected files and implementation phases
5. wait for approval before making the architectural change

Minor implementation details that remain within the documented boundaries do not require
a formal architecture amendment.
