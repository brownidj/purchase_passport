# IMPLEMENTATION_PLAN.md

# Purchase Passport – Implementation Plan

Development should proceed in small, reviewable phases.

Before implementing any phase, read:

- [CURRENT_STATE.md](CURRENT_STATE.md)
- [ARCHITECTURE.md](ARCHITECTURE.md)
- [CODING_STANDARDS.md](CODING_STANDARDS.md)
- [TESTING_STRATEGY.md](TESTING_STRATEGY.md)

## Phase Status

- Phase 1 (Task 001 – Project Foundation): completed on August 1, 2026
- Phase 2 (Task 002 – Purchase Model): completed on August 1, 2026
- Phase 3 (Task 003 – Contacts): completed on August 1, 2026
- Phase 4 (Task 004 – Navigation, Purchase List, Purchase Detail View and Editor): completed on August 1, 2026
- Phase 5 (Task 005 – Documents): completed on August 2, 2026
- Phase 6 (Task 006 – Warranties and Reminders): completed on August 2, 2026
- Phase 7 (Task 007 – Interactions and Timeline): completed on August 2, 2026
- Phase 8 (Task 008 – Servicing, Faults and Repairs): completed on August 2, 2026
- Phase 9 (Task 009 – Complaints, Claims and Disputes): completed on August 2, 2026
- Phase 10 (Task 010 – Dashboard): completed on August 2, 2026
- Phase 11 onward: not started

## Phase 1 – Project Foundation

Task 001.

- Configure project
- Folder structure
- Basic navigation
- SwiftData container

## Phase 2 – Purchase Model

Task 002.

- `Purchase` entity and supporting enums
- Financial value modeling (`Decimal` + currency)
- Categories
- Basic purchase editor
- Purchase list
- Purchase lifecycle status transitions

## Phase 3 – Contacts

Task 003.

- Contact and organisation models
- Reusable contact management
- Link contacts to purchases

## Phase 4 – Navigation, Purchase List, Purchase Detail View and Editor

Task 004.

- Navigation structure for current sections
- Purchase list
- Purchase detail view
- Purchase create/edit flow

## Phase 5 – Documents

Task 005.

- Import
- Storage
- Preview
- Organisation
- Attachment metadata modelling

## Phase 6 – Warranties and Reminders

Task 006.

- Warranty records
- Expiry tracking
- Reminder support
- Recurrence basics

## Phase 7 – Interactions and Timeline

Task 007.

- Communication log
- Unified timeline integration
- Timeline filtering basics

## Phase 8 – Servicing, Faults and Repairs

Task 008.

- Service history
- Fault tracking
- Repairs
- Cost and outcome tracking

## Phase 9 – Complaints, Claims and Disputes

Task 009.

- Complaint/dispute record model
- Complaint chronology
- Linked evidence and correspondence
- Status and deadline tracking
- Integrations with fault, repair and interaction records

## Phase 10 – Dashboard

Task 010.

- Upcoming reminders
- Warranty status
- Recent activity
- Actionable unresolved items

## Phase 11 – Search and Filtering

Task 011.

- Global search
- Advanced filters
- Saved searches

## Phase 12 – Export and Backup

Task 012.

- PDF/report export
- Archive export
- Backup and restore
- Record portability checks

## Phase 13 – Security, Privacy and Settings

Task 013.

- Sharing safeguards
- Deletion confirmation and recovery policy
- Optional app lock and privacy controls
- Settings for workflow customization

## Phase 14 – Templates and Customization

Task 014.

- Purchase templates
- Custom fields
- Custom categories/types
- Summary field preferences

## Phase 15 – Stabilization and Release Readiness

Task 015.

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
