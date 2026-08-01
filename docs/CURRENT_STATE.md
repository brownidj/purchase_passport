# CURRENT_STATE.md

# Purchase Passport – Current State And Workflow

## 1. Purpose

This document is the operational entry point for both human developers and AI coding assistants.

Read this document first before planning or implementing any change.

It defines:

- what stage the project is in
- what documents govern implementation
- how work must be scoped and reported

---

## 2. Current Stage

The project has completed:

- Phase 1 (Project Foundation, also referred to as Task 001) on August 1, 2026
- Phase 2 (Purchase Domain Model, also referred to as Task 002) on August 1, 2026

The next implementation target is Phase 3 (Contacts), unless the user explicitly requests a different phase.

At this stage, the source of truth is documentation:

- [Functional Specification](FUNCTIONAL_SPECIFICATION.md)
- [Architecture](ARCHITECTURE.md)
- [Implementation Plan](IMPLEMENTATION_PLAN.md)
- [Coding Standards](CODING_STANDARDS.md)
- [Testing Strategy](TESTING_STRATEGY.md)

Until a phase is explicitly requested, no new feature should be implemented.

---

## 3. Required Reading Order

For any implementation task, read in this order:

1. [CURRENT_STATE.md](CURRENT_STATE.md)
2. [FUNCTIONAL_SPECIFICATION.md](FUNCTIONAL_SPECIFICATION.md)
3. [ARCHITECTURE.md](ARCHITECTURE.md)
4. [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md)
5. [CODING_STANDARDS.md](CODING_STANDARDS.md)
6. [TESTING_STRATEGY.md](TESTING_STRATEGY.md)

---

## 4. Execution Workflow

Every task must follow this sequence:

1. Restate the requested scope.
2. Confirm the implementation phase (or explicitly state docs-only work).
3. List files expected to be created or modified.
4. Implement only the requested task.
5. Avoid unrelated refactoring and architecture changes.
6. Summarise all files created and modified.
7. State whether any build/tests were run.
8. Provide the smallest relevant manual verification step.

---

## 5. Scope Control Rules

- Work on one task or one phase at a time.
- Do not implement future phases pre-emptively.
- Do not broaden the task to include unrequested cleanup.
- Do not alter architectural boundaries without explicit approval.
- Do not claim builds/tests/commits were run unless actually run.

---

## 6. Documentation Update Policy

When documentation changes:

- keep links valid
- keep naming consistent across files
- preserve clear separation between product requirements, architecture, and implementation sequencing
- reflect new documents in [README.md](../README.md)

---

## 7. Next Expected Development Flow

When implementation resumes, work should start with Phase 3 in [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) unless the user explicitly requests a different phase.
