# IMPLEMENTATION_PLAN.md

# Purchase Passport – Implementation Plan

Development should proceed in small, reviewable phases.

Before implementing any phase, read:

- [CURRENT_STATE.md](CURRENT_STATE.md)
- [ARCHITECTURE.md](ARCHITECTURE.md)
- [CODING_STANDARDS.md](CODING_STANDARDS.md)
- [TESTING_STRATEGY.md](TESTING_STRATEGY.md)

## Phase Status

- Phase 1 (Project Foundation): completed on August 1, 2026
- Phase 2 (Purchase Model): completed on August 1, 2026
- Phase 3 (Contacts): completed on August 1, 2026
- Task 004 (Navigation, Purchase List, Purchase Detail View and Editor): completed on August 1, 2026
- Phase 4 onward: not started

## Phase 1 – Project Foundation

Alias: Task 001 – Project Foundation.

- Configure project
- Folder structure
- Basic navigation
- SwiftData container

## Phase 2 – Purchase Model

- `Purchase` entity and supporting enums
- Financial value modeling (`Decimal` + currency)
- Categories
- Basic purchase editor
- Purchase list
- Purchase lifecycle status transitions

## Phase 3 – Contacts

- Contact and organisation models
- Reusable contact management
- Link contacts to purchases

## Phase 4 – Documents

- Import
- Storage
- Preview
- Organisation
- Attachment metadata modelling

## Phase 5 – Warranties and Reminders

- Warranty records
- Expiry tracking
- Reminder support
- Recurrence basics

## Phase 6 – Interactions and Timeline

- Communication log
- Unified timeline integration
- Timeline filtering basics

## Phase 7 – Servicing, Faults and Repairs

- Service history
- Fault tracking
- Repairs
- Cost and outcome tracking

## Phase 8 – Complaints, Claims and Disputes

- Complaint/dispute record model
- Complaint chronology
- Linked evidence and correspondence
- Status and deadline tracking
- Integrations with fault, repair and interaction records

## Phase 9 – Dashboard

- Upcoming reminders
- Warranty status
- Recent activity
- Actionable unresolved items

## Phase 10 – Search and Filtering

- Global search
- Advanced filters
- Saved searches

## Phase 11 – Export and Backup

- PDF/report export
- Archive export
- Backup and restore
- Record portability checks

## Phase 12 – Security, Privacy and Settings

- Sharing safeguards
- Deletion confirmation and recovery policy
- Optional app lock and privacy controls
- Settings for workflow customization

## Phase 13 – Templates and Customization

- Purchase templates
- Custom fields
- Custom categories/types
- Summary field preferences

## Phase 14 – Stabilization and Release Readiness

- Schema migration validation
- Performance and reliability hardening
- Accessibility and UX polish
- End-to-end regression pass

## Working Rules

For every phase:

1. Explain the implementation plan first.
2. List files to be changed.
3. Implement only the requested phase.
4. Do not refactor unrelated code.
5. Do not create Git commits.
6. Recommend manual testing steps.
7. Summarise all modified files.
