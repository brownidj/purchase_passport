# Purchase Passport

Purchase Passport is a native macOS app for recording and managing the full lifecycle of significant purchases, including documents, warranties, servicing, repairs, interactions, reminders, and export-ready history.

## Read This First

Both developers and AI coding assistants should read [docs/CURRENT_STATE.md](docs/CURRENT_STATE.md) first.

That document defines:

- current project stage
- required reading order
- scope control rules
- execution and reporting workflow

## Core Project Documents

1. [docs/CURRENT_STATE.md](docs/CURRENT_STATE.md)
2. [docs/FUNCTIONAL_SPECIFICATION.md](docs/FUNCTIONAL_SPECIFICATION.md)
3. [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
4. [docs/IMPLEMENTATION_PLAN.md](docs/IMPLEMENTATION_PLAN.md)
5. [docs/CODING_STANDARDS.md](docs/CODING_STANDARDS.md)
6. [docs/TESTING_STRATEGY.md](docs/TESTING_STRATEGY.md)

## Repository Note

This repository includes documentation plus implementation through Phase 5 (Warranties and Reminders, completed on August 2, 2026). Ongoing implementation should follow the phased plan and architecture boundaries unless explicitly changed by approved documentation updates.

## Development Workflow

Development is performed in small, self-contained tasks.

Before starting work:

1. Read `docs/CURRENT_STATE.md`.
2. Review `docs/IMPLEMENTATION_PLAN.md`.
3. Read `docs/ARCHITECTURE.md` if structural changes are involved.
4. Implement only the approved task.

After implementation:

1. Review the changes.
2. Perform manual verification in Xcode.
3. Update `docs/CURRENT_STATE.md`.
4. Commit and push to GitHub.
5. Proceed to the next approved task.
