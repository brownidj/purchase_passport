# TESTING_STRATEGY.md

# Purchase Passport – Testing Strategy

## 1. Purpose

This document defines how testing is applied in this repository.

The goal is balanced coverage: fast feedback for core logic, targeted persistence checks, and stable UI automation for critical journeys.

---

## 2. Test Layers

## 2.1 Unit Tests

Use unit tests for pure logic and deterministic behavior:

- validation rules
- status transitions
- date and warranty calculations
- reminder recurrence logic
- financial calculations
- mapping/parsing helpers

Frameworks:

- Swift Testing
- XCTest (where integration with existing test targets is clearer)

## 2.2 Persistence Tests

Use persistence-focused tests with in-memory SwiftData containers for:

- insert/update behavior
- relationship integrity
- delete rules
- fetch and sort expectations
- migration behavior when schema changes are introduced
- monetary precision and currency handling
- enum raw-value compatibility across schema evolution
- custom-field definition/value compatibility across schema evolution
- document replacement/version history behavior

These tests should avoid UI dependencies.

## 2.3 UI Tests

Use XCUI automation for a small set of high-value user journeys:

- create a purchase record
- edit and delete a purchase record
- import and view a document
- record servicing or repairs
- create and progress a complaint/dispute
- search and open a purchase
- export a purchase record

UI tests should prioritize reliability over exhaustive screen coverage.

---

## 3. Test Selection Guidance

Use this default rule:

- if behavior is pure logic, add unit tests first
- if behavior depends on model storage/relationships, add persistence tests
- if behavior is cross-screen user flow, add UI tests

Avoid duplicating the same assertion across multiple layers unless risk justifies it.

---

## 4. Quality Gates Per Change

For each implementation task:

1. Add or update tests relevant to the changed behavior when practical.
2. Prefer the smallest focused test execution for quick feedback.
3. Run broader suites only when changes affect shared infrastructure or multiple features.

If tests are not run by the coding assistant, this must be stated explicitly in the completion report.

---

## 5. Reliability Rules

- Keep tests deterministic and isolated.
- Avoid dependence on wall-clock timing unless the clock is controlled.
- Use stable fixtures and explicit setup/teardown.
- Avoid UI selectors that are likely to break from cosmetic layout changes.
- Keep each test focused on one behavior.

### 5.1 UI reliability baseline (mandatory)

- UI tests must launch into a deterministic state when possible (for example, `-ui-testing`).
- Prefer stable accessibility identifiers for navigation and list selection.
- Avoid assumptions about macOS window restoration; verify or create required window state.
- Keep UI assertions resilient to cosmetic layout differences.

### 5.2 Standard UI test execution path

Use the repository script for UI test runs:

```zsh
cd "Purchase Passport"
./scripts/run_ui_tests.zsh single
```

Script expectations:

- stable artifact/log locations
- progress heartbeat during long runs
- metadata cleanup for code-sign reliability
- explicit result bundle and log paths at completion

### 5.3 UI test failure triage checklist

For failed runs, capture:

1. first `error:` line
2. first `XCTAssert`/`XCTFail` line
3. final `** TEST ... **` summary block
4. newest run log path and result bundle path

Use attached debug artifacts (UI tree/screenshot) for selector or window-state diagnosis.

---

## 6. Manual Verification

Automated tests are necessary but not sufficient for release quality.

When UI or interaction behavior changes, include a short manual checklist, such as:

- create and save a new purchase
- reopen app and verify persistence
- attach and preview a document
- replace a document and verify prior-version metadata is retained
- verify reminder date behavior
- confirm deletion confirmation appears for destructive actions

---

## 7. Relationship To Other Documents

- Process and reporting workflow: [CURRENT_STATE.md](CURRENT_STATE.md)
- Architectural test boundaries: [ARCHITECTURE.md](ARCHITECTURE.md)
- Phase sequencing and scope constraints: [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md)
- Code quality standards: [CODING_STANDARDS.md](CODING_STANDARDS.md)
