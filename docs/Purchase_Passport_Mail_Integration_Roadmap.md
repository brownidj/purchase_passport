# Purchase Passport -- Apple Mail Integration Roadmap

## Overview

This roadmap introduces outgoing email actions plus imported-message
support in progressive phases. Each phase delivers useful functionality
while avoiding unnecessary complexity or unsupported APIs.

------------------------------------------------------------------------

# Phase 1 -- Launch Mail with Pre-filled Messages

## Objectives

-   Add **Email Provider**, **Email Manufacturer**, and **Email
    Contact** actions.
-   Open the user's default mail client (typically Apple Mail) using a
    `mailto:` URL.
-   Pre-populate:
    -   Recipient
    -   Subject
    -   Message body

## Typical Use Cases

-   Warranty enquiry
-   Service booking
-   Product support
-   General correspondence

## User Interface

Add buttons in appropriate places, for example:

-   Purchase Detail
-   Provider Detail
-   Contact Detail
-   Complaint Case

## Notes

-   No special permissions required.
-   Works with the user's preferred mail application.

------------------------------------------------------------------------

# Phase 2 -- Smart Email Templates

## Objectives

Automatically generate professional email drafts from Purchase Passport
data.

## Built-in Templates

-   Warranty claim
-   Fault report
-   Service request
-   Repair quotation request
-   Complaint
-   Follow-up
-   Refund request
-   Return request
-   Thank-you
-   General enquiry

## Automatically Include

-   Purchase name
-   Purchase date
-   Provider
-   Manufacturer
-   Model
-   Serial number
-   Invoice number
-   Order number
-   Warranty details

------------------------------------------------------------------------

# Phase 3 -- Attachment Support

## Objectives

Generate Apple Mail drafts with supporting documentation attached.

## Attachments

-   Invoice
-   Receipt
-   Warranty
-   Guarantee
-   Photographs
-   Service reports
-   Fault reports
-   Repair invoices

## Implementation

Use AppleScript to create a draft message and attach files before
presenting it to the user.

------------------------------------------------------------------------

# Phase 4 -- Correspondence Management

## Objectives

Treat email as a first-class purchase document.

## Features

-   Import exported sent emails
-   Import exported received emails
-   Store `.eml` and `.emlx` files
-   Support drag-and-drop and manual file selection for imported messages
-   Link correspondence to purchases
-   Show emails in the purchase timeline

## Timeline Integration

Imported emails appear alongside:

-   Purchases
-   Warranties
-   Reminders
-   Service records
-   Faults
-   Repairs
-   Complaint events

------------------------------------------------------------------------

# Phase 5 -- AI-Assisted Correspondence

## Objectives

Use AI to assist with professional communication.

## Capabilities

-   Draft responses
-   Summarise long threads
-   Suggest next actions
-   Produce escalation letters
-   Produce formal complaint letters
-   Generate consumer-law style correspondence
-   Adjust tone (friendly, professional, firm, legal)

------------------------------------------------------------------------

# Phase 6 -- Advanced Communication Centre

## Objectives

Provide a unified communications hub.

## Dashboard

Display:

-   Outstanding replies
-   Recent correspondence
-   Draft emails
-   Upcoming follow-ups
-   Complaint deadlines
-   Warranty expiries

## Automation

-   Schedule follow-up reminders
-   Detect unanswered emails
-   Recommend escalation
-   Track communication history

------------------------------------------------------------------------

# Phase 7 -- Communication Intelligence

## Objectives

Turn correspondence into structured purchase history intelligence.

## Capabilities

-   Automatically link incoming and sent emails to the correct purchase.
-   Use AI extraction for:
    -   order numbers
    -   tracking numbers
    -   RMA (return authorisation) numbers
-   Detect and propose warranty expiry details from correspondence.
-   Build a complete communication timeline across:
    -   emails
    -   phone calls
    -   repairs
    -   complaints

## Linking Strategy

-   High-confidence links are auto-applied.
-   Lower-confidence links are placed in a review queue for user confirmation.
-   All linking decisions should remain editable and auditable.

## Data and UX Notes

-   Preserve message metadata and extraction provenance.
-   Show confidence indicators for auto-linking and extracted fields.
-   Allow users to accept, reject, or edit extracted values before save.

------------------------------------------------------------------------

# Out of Scope

The application should **not** attempt to directly access or modify
Apple Mail's internal message database, or rely on live mailbox scanning
through unsupported automation. Apple does not provide a stable public
API for this purpose and such an approach would be fragile and require
additional permissions.

------------------------------------------------------------------------

# Recommended Implementation Order

1.  Launch Mail with pre-filled drafts.
2.  Add intelligent email templates.
3.  Support automatic document attachments.
4.  Store correspondence within Purchase Passport.
5.  Introduce AI-assisted drafting.
6.  Build the Communication Centre dashboard.
7.  Add Communication Intelligence for linking, extraction and timeline synthesis.

This staged approach delivers immediate value while creating a scalable
architecture for future communication features.
