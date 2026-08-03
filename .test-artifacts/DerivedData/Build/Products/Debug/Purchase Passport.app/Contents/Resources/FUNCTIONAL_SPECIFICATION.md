# Functional Specification: Purchase Passport

## 1. Product Purpose

Purchase Passport is a native macOS application for creating and maintaining complete long-term records of significant purchases.

The app should support purchases such as:

- vehicles
- computers, tablets and phones
- appliances and electronics
- furniture
- holidays and travel bookings
- home renovations
- professional services
- equipment
- insurance-backed purchases
- other high-value or important purchases

The app should act as a central record for the entire lifecycle of a purchase, from initial research and purchase through ownership, servicing, repairs, warranty claims, disputes, resale or disposal.

This specification defines functional requirements only. Application architecture, persistence technology, synchronisation, cloud services, navigation implementation and third-party frameworks will be defined separately.

---

## 2. Purchase Records

The user must be able to create a separate record for each major purchase.

Each purchase record should support:

- item or purchase name
- purchase category
- short description
- detailed notes
- purchase status
- purchase date
- order date
- delivery or commencement date
- purchase price
- currency
- tax, fees, delivery charges and other costs
- total cost
- payment method
- deposit amount
- balance paid
- finance or instalment details
- seller or supplier
- manufacturer, provider or brand
- model name
- model number
- serial number
- registration number
- booking or reservation number
- invoice number
- order number
- contract number
- account or customer number
- purchase location
- physical location where the item is kept
- ownership status
- expected useful life
- optional cover image or photograph
- searchable tags
- custom user-defined fields

All fields should be optional unless they are essential to identify the purchase, because different categories require different information.

---

## 3. Purchase Categories

The app should include common predefined categories while allowing users to create their own.

Suggested categories include:

- Vehicle
- Computer
- Phone
- Tablet
- Electronics
- Appliance
- Furniture
- Home Renovation
- Travel or Holiday
- Accommodation
- Equipment
- Subscription or Service
- Professional Service
- Jewellery
- Insurance
- Other

Different categories may present different suggested fields.

### 3.1 Vehicle

Suggested vehicle fields include:

- make
- model
- variant
- year
- vehicle identification number
- registration number
- odometer reading at purchase
- dealer
- finance details
- service schedule
- roadside assistance details

### 3.2 Electronics

Suggested electronics fields include:

- manufacturer
- model
- serial number
- operating system
- storage or configuration
- retailer
- extended warranty
- accessories

### 3.3 Furniture

Suggested furniture fields include:

- manufacturer
- product range
- dimensions
- materials
- fabric or colour
- care instructions
- delivery details
- assembly details

### 3.4 Holiday or Travel

Suggested travel fields include:

- destination
- traveller names
- booking references
- travel dates
- flights
- accommodation
- transport
- travel provider
- insurance
- cancellation conditions
- payment schedule

### 3.5 Renovation

Suggested renovation fields include:

- property
- contractor
- subcontractors
- project description
- quotations
- approvals
- permits
- commencement date
- completion date
- staged payments
- defects
- variations
- warranties

---

## 4. Parties and Contacts

Each purchase record should allow the user to associate relevant people and organisations.

These may include:

- seller
- retailer
- dealer
- manufacturer
- supplier
- installer
- contractor
- service centre
- repairer
- insurer
- finance provider
- travel agent
- property manager
- customer support contact
- individual staff members

Each party should support:

- organisation name
- contact name
- role
- email address
- phone number
- website
- postal address
- physical address
- customer service number
- account number
- notes

A contact should be reusable across multiple purchase records where appropriate.

---

## 5. Documents and Attachments

The user must be able to attach and organise documents associated with a purchase.

Supported document types should include:

- receipt
- invoice
- quotation
- purchase order
- contract
- finance agreement
- warranty
- guarantee
- extended warranty
- insurance policy
- user manual
- installation instructions
- care instructions
- service schedule
- booking confirmation
- itinerary
- registration document
- inspection report
- repair report
- service report
- photograph
- screenshot
- email
- letter
- complaint
- refund record
- certificate
- permit
- other supporting document

For each document, store:

- document title
- document category
- associated purchase
- issue date
- expiry date
- issuing organisation
- reference number
- notes
- file attachment
- optional scan or photograph
- date added

The user should be able to:

- import files
- scan paper documents
- attach photographs
- rename documents
- categorise documents
- preview documents
- search documents
- share or export documents
- replace outdated versions
- retain previous versions where useful

---

## 6. Warranty and Guarantee Management

The app should provide dedicated warranty and guarantee tracking.

Each warranty record should support:

- warranty type
- provider
- start date
- end date
- duration
- coverage description
- exclusions
- claim procedure
- claim contact details
- warranty reference number
- proof-of-purchase requirement
- transferable status
- extended warranty details
- attached warranty documents
- notes

The app should clearly show:

- active warranties
- warranties nearing expiry
- expired warranties
- warranty claims already made
- remaining coverage periods

Users should be able to create reminders before warranty expiry.

---

## 7. Manuals and Instructions

The app should allow the user to store and quickly retrieve:

- user manuals
- setup instructions
- maintenance instructions
- care instructions
- troubleshooting guides
- safety instructions
- installation instructions
- operating procedures
- links to online documentation
- instructional videos or web resources

Instructions should be associated with the relevant purchase and be easy to access without searching through unrelated documents.

---

## 8. Interaction History

Each purchase should include a chronological interaction log.

The user must be able to record interactions with:

- sellers
- manufacturers
- support departments
- service centres
- repairers
- contractors
- insurers
- finance providers
- travel providers
- other relevant parties

Interaction types should include:

- phone call
- email
- letter
- in-person visit
- online chat
- service appointment
- repair booking
- complaint
- warranty claim
- refund request
- replacement request
- inspection
- quotation
- follow-up
- other

Each interaction record should support:

- date and time
- party contacted
- individual contact person
- contact method
- subject
- summary
- detailed notes
- promises or commitments made
- reference or case number
- next action
- follow-up date
- status
- attached documents
- attached photographs
- related service, repair, complaint or warranty claim

The app should present interactions as a clear chronological history.

---

## 9. Servicing and Maintenance

The app should support scheduled and completed servicing or maintenance.

Each service record should support:

- service type
- service provider
- booking date
- service date
- completion date
- cost
- odometer, usage or operating-hours reading where relevant
- work requested
- work completed
- parts replaced
- technician notes
- next service date
- next service interval
- service reference number
- attached invoice
- attached service report
- photographs
- notes

The app should support recurring maintenance schedules such as:

- vehicle servicing
- equipment inspections
- appliance filter replacement
- furniture care
- software renewal
- home maintenance
- renovation defect inspections

---

## 10. Repairs and Faults

Users should be able to record faults, damage and repairs.

A fault record should support:

- date first noticed
- fault title
- detailed description
- severity
- current status
- photographs or videos
- diagnostic information
- effect on use
- safety concerns
- seller or manufacturer notified
- related warranty
- related repair
- related interaction history

A repair record should support:

- repair provider
- booking date
- repair date
- fault addressed
- diagnosis
- work performed
- parts replaced
- labour cost
- parts cost
- total cost
- warranty coverage
- payment status
- repair warranty
- outcome
- unresolved issues
- attached reports
- attached invoices
- photographs
- follow-up required

The app should retain the full history of repeated faults and repairs.

---

## 11. Complaints, Claims and Disputes

The app should allow the user to create a formal complaint, claim or dispute record.

Each case should support:

- case title
- issue type
- party responsible
- date opened
- current status
- desired resolution
- relevant consumer guarantee or warranty
- case or reference number
- chronology
- key evidence
- correspondence
- deadlines
- commitments made
- outcome
- compensation, replacement, refund or repair details
- date closed

The app should help the user assemble a clear chronological record of:

- what happened
- when it happened
- who was contacted
- what evidence exists
- what was promised
- what remains unresolved

The app should allow the user to export a complaint chronology and supporting document list.

---

## 12. Costs and Financial History

The app should track the full financial history of a purchase.

This may include:

- purchase price
- deposits
- instalments
- finance payments
- fees
- delivery costs
- installation costs
- service costs
- repair costs
- insurance costs
- upgrades
- accessories
- refunds
- rebates
- compensation
- resale value

The app should calculate:

- original purchase cost
- additional ownership costs
- total cost to date
- refunds or reimbursements
- net cost
- optional annualised cost
- optional cost by category

---

## 13. Reminders and Important Dates

Users should be able to create reminders associated with purchases.

Suggested reminder types include:

- warranty expiry
- guarantee expiry
- return-period expiry
- payment due
- finance payment
- service due
- maintenance due
- registration renewal
- insurance renewal
- subscription renewal
- travel payment deadline
- cancellation deadline
- contractor follow-up
- defect inspection
- complaint response deadline
- repair follow-up
- document expiry

Each reminder should support:

- title
- due date
- optional time
- advance warning period
- recurrence
- priority
- notes
- related purchase
- completion status

---

## 14. Purchase Timeline

Each purchase record should include a unified timeline showing significant events in date order.

The timeline may include:

- quotation received
- order placed
- deposit paid
- purchase completed
- delivery
- installation
- warranty commencement
- interaction
- complaint
- fault
- service
- repair
- payment
- refund
- document added
- reminder
- warranty claim
- resale or disposal

Users should be able to filter the timeline by event type.

---

## 15. Search, Filter and Organisation

The app should allow users to search across:

- purchase names
- categories
- sellers
- manufacturers
- model numbers
- serial numbers
- registration numbers
- invoice numbers
- notes
- contacts
- documents
- interactions
- repair records
- warranty records
- tags

Filters should include:

- category
- status
- purchase date
- seller
- manufacturer
- warranty status
- unresolved issue
- upcoming reminder
- active complaint
- service due
- archived purchase

Sorting options should include:

- most recent
- oldest
- name
- purchase value
- warranty expiry
- next reminder
- category

---

## 16. Purchase Status and Lifecycle

A purchase may move through lifecycle states such as:

- researching
- quotation received
- ordered
- deposit paid
- awaiting delivery
- active
- under warranty
- undergoing repair
- subject to complaint
- returned
- refunded
- replaced
- sold
- donated
- disposed of
- cancelled
- archived

The app should preserve historical information when the status changes.

---

## 17. Dashboard

The app should provide a useful overview of the user’s purchase records.

The dashboard should highlight:

- recent purchases
- upcoming reminders
- warranties nearing expiry
- overdue follow-ups
- service due dates
- unresolved faults
- active repairs
- active complaints
- recent interactions
- recently added documents

The dashboard should prioritise actionable information rather than merely displaying totals.

---

## 18. Templates

The app should provide optional templates for common purchase types.

Templates may include:

- vehicle
- computer
- mobile phone
- appliance
- furniture
- holiday
- renovation
- professional service
- general purchase

A template should preconfigure relevant fields, document categories, reminders and lifecycle events without preventing users from modifying them.

---

## 19. Export and Reporting

Users should be able to export information from an individual purchase or from the complete app.

Export options should include:

- purchase summary
- full purchase record
- chronological interaction history
- service and repair history
- warranty summary
- complaint chronology
- cost summary
- document index
- selected attachments
- complete archive

Exports should be suitable for:

- personal records
- insurance claims
- warranty claims
- consumer complaints
- legal advice
- resale
- tax or accounting records
- sharing with a repairer or contractor

Possible export formats may include PDF, printable report, structured data and a portable archive, but implementation formats should be decided later.

---

## 20. Privacy and Security

Because purchase records may contain sensitive personal and financial information, the app should support:

- secure storage
- device authentication
- optional app lock
- protection of attached documents
- clear control over sharing
- deletion of records
- backup and restore
- export before deletion
- privacy-preserving defaults

The app should avoid collecting information that is not required for its core purpose.

---

## 21. Backup, Restore and Portability

The user should be able to:

- back up all purchase records
- restore from a backup
- move records to another device
- export an individual purchase
- import a previously exported purchase
- preserve attachments and relationships
- verify that a backup is complete

The exact backup and synchronisation architecture will be determined later.

---

## 22. Accessibility and Ease of Use

The app should be suitable for users with varying levels of technical confidence.

It should provide:

- clear terminology
- readable text
- support for Dynamic Type
- VoiceOver compatibility
- strong contrast
- large interaction targets
- meaningful icons with labels
- simple data entry
- sensible defaults
- clear confirmation before destructive actions
- helpful empty states
- minimal reliance on hidden gestures

The app should make it easy to enter a basic purchase quickly while allowing detailed records to be added progressively.

---

## 23. Data Entry Principles

The app should not require every detail at the time a purchase is created.

A user should be able to:

1. create a basic purchase record
2. add documents immediately or later
3. add missing details over time
4. record interactions as they occur
5. create reminders
6. maintain the record throughout the purchase lifecycle

Use progressive disclosure so that advanced fields do not overwhelm users creating a simple record.

---

## 24. Customisation

Users should be able to:

- create custom purchase categories
- create custom document types
- create custom interaction types
- create custom reminder types
- create custom fields
- reorder important fields
- choose which information appears in summaries
- archive unused templates

---

## 25. Example User Workflow

A user purchases a new laptop.

They create a purchase record and enter:

- retailer
- manufacturer
- model
- serial number
- purchase date
- price
- payment method

They attach:

- receipt
- invoice
- warranty
- user manual
- photographs

They create a reminder one month before the warranty expires.

Six months later, the laptop develops a fault. The user:

- creates a fault record
- adds photographs
- records a phone call with the retailer
- stores the case number
- records the promised response date
- creates a follow-up reminder
- adds the repair booking
- attaches the repair report
- records whether the repair was covered by warranty

The complete sequence remains available in the purchase timeline and can be exported as a chronological report.

---

## 26. Initial Product Goal

The initial product should provide a reliable personal record system for major purchases.

Its primary value is not merely storing receipts. It should help users preserve evidence, understand their rights and obligations, monitor important dates, document problems, and maintain an accurate history of ownership, servicing, repairs and communications.

The initial version should prioritise:

- purchase records
- contacts
- documents
- warranties
- reminders
- interactions
- servicing
- faults and repairs
- chronological history
- search
- export

Architecture, persistence, synchronisation, cloud integration, document storage strategy and implementation phases will be specified separately.
