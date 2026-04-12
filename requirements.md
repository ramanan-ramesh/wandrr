# Wandrr — Product Requirements Specification

> **Version:** 1.1  
> **Last Updated:** 2026-03-31
> **Status:** Active

---

## Table of Contents

1. [Overview](#1-overview)
2. [Glossary](#2-glossary)
3. [Platform & Layout Modes](#3-platform--layout-modes)
4. [Module: Onboarding & Language Selection](#4-module-onboarding--language-selection)
5. [Module: Authentication](#5-module-authentication)
6. [Module: App-Level Settings](#6-module-app-level-settings)
7. [Module: Trip List (Home Page)](#7-module-trip-list-home-page)
8. [Module: Create Trip](#8-module-create-trip)
9. [Module: Copy Trip](#9-module-copy-trip)
10. [Module: Delete Trip](#10-module-delete-trip)
11. [Module: Trip Editor — Overview & Navigation](#11-module-trip-editor--overview--navigation)
12. [Module: Trip Details Editor](#12-module-trip-details-editor)
13. [Module: Itinerary Timeline (Per-Day View)](#13-module-itinerary-timeline-per-day-view)
14. [Module: Stay (Lodging) Editor](#14-module-stay-lodging-editor)
15. [Module: Transit Editor (Single Leg)](#15-module-transit-editor-single-leg)
16. [Module: Multi-Leg Journey Editor](#16-module-multi-leg-journey-editor)
17. [Module: Itinerary Plan Data Editor (Sights / Notes / Checklists)](#17-module-itinerary-plan-data-editor-sights--notes--checklists)
18. [Module: Standalone Expense Editor](#18-module-standalone-expense-editor)
19. [Module: Expense Split & Payment Details (Shared Component)](#19-module-expense-split--payment-details-shared-component)
20. [Module: Budgeting — Expenses List, Debt Summary, Breakdown](#20-module-budgeting--expenses-list-debt-summary-breakdown)
21. [Module: Conflict Detection & Resolution](#21-module-conflict-detection--resolution)
22. [Module: Saving Changes (Batch Commit)](#22-module-saving-changes-batch-commit)
23. [Validation Rules Reference](#23-validation-rules-reference)
24. [Mobile vs Tablet/Web Layout Differences](#24-mobile-vs-tabletweb-layout-differences)
25. [Internationalization](#25-internationalization)
26. [Real-Time Collaboration & Sync](#26-real-time-collaboration--sync)
27. [App Update Mechanism](#27-app-update-mechanism)
28. [Test Traceability](#28-test-traceability)
29. [Performance & User Experience](#29-performance--user-experience)
30. [Module: Print Trip](#30-module-print-trip)

---

## 1. Overview

Wandrr is a cross-platform travel planning app (Android, iOS, Web) that lets users:

- Create and manage multi-day trips.
- Build per-day itineraries with stays, transit legs, sights, notes, and checklists.
- Track expenses with multi-contributor split and debt settlement.
- Collaborate on trips with multiple contributors.
- Detect and resolve timeline conflicts when dates, times, or contributors change.
- Print or save trip summaries as PDF documents.

**Supported Languages:** English, Hindi, Tamil.

---

## 2. Glossary

| Term                   | Definition                                                                                     |
|------------------------|------------------------------------------------------------------------------------------------|
| **Trip**               | The top-level entity: has a name, date range, contributors, budget, and thumbnail.             |
| **Stay (Lodging)**     | A lodging entry with check-in/out dates, location, confirmation ID, expense, and notes.        |
| **Transit**            | A single movement leg: travel mode, departure/arrival location + date-time, operator, expense. |
| **Journey**            | A group of connected transit legs displayed as connected segments (e.g., multi-stop flights).  |
| **Itinerary**          | The per-day view of a trip, containing linked stays, transits, and plan data.                  |
| **Plan Data**          | User-editable content for a day: sights, notes, and checklists.                                |
| **Sight**              | A named attraction/visit with optional location, visit time, description, and expense.         |
| **Checklist**          | A titled list of checkable items for a day.                                                    |
| **Standalone Expense** | An expense not linked to a stay/transit/sight; has title, category, date, and split data.      |
| **Expense**            | Shared expense data: currency, who paid what, who splits the cost, and computed total.         |
| **Contributor**        | A user (identified by username/email) who participates in a trip.                              |
| **Conflict**           | A temporal overlap or out-of-bounds condition detected when a user edits dates/times.          |
| **Clamping**           | Auto-adjusting an entity's times to fit within a new boundary (e.g., trip dates shrink).       |
| **Mobile Layout**      | Narrow single-column layout (screen width ≤ 1000 pixels).                                      |
| **Tablet/Web Layout**  | Wide layout (screen width > 1000 pixels) with split panes.                                     |

---

## 3. Platform & Layout Modes

### REQ-LAYOUT-001 — Layout Breakpoint

- The app uses a wide (tablet/web) layout when the screen width exceeds 1000 pixels, and a narrow (
  mobile) layout otherwise.

### REQ-LAYOUT-002 — Adaptive Rendering

- Every screen must render correctly in both layout modes. Layout mode is recalculated whenever the
  screen is resized.

### REQ-LAYOUT-003 — Startup Page Layout

- **Mobile:** Shows either the Onboarding page or the Login page one at a time.
- **Tablet/Web:** Shows Onboarding on the left half and Login on the right half side-by-side.

---

## 4. Module: Onboarding & Language Selection

### REQ-ONB-001 — Onboarding Page Content

- Displays a full-bleed background image.
- Overlays a language selector on the right side.
- On **mobile**, a large "Next" button is shown to navigate to the Login page.
- On **tablet/web**, the "Next" button is hidden (Login page is already visible alongside).

### REQ-ONB-002 — Language Selector (Onboarding)

- Shows a translate icon button that toggles an expandable list of available languages.
- Each language entry displays its flag and name.
- Tapping a language immediately re-renders the entire app in the selected language.

### REQ-ONB-003 — Supported Languages

- English, Hindi, Tamil.
- Each language entry shows a flag icon and a display name.

---

## 5. Module: Authentication

### REQ-AUTH-001 — Login / Register Tabs

- The Login page shows two tabs: **Login** and **Register**.
- Switching tabs does not clear the form fields.

### REQ-AUTH-002 — Email/Password Form

- **Username field:** Must be a valid non-empty email address.
- **Password field:** Obscured text; must be non-empty.
- Pressing submit performs either login or registration based on the active tab.

### REQ-AUTH-003 — Submit Button State

- The submit button is disabled while an authentication request is in progress.
- Re-enabled once the request completes (success or failure).

### REQ-AUTH-004 — Third-Party Authentication

- A Google sign-in button is displayed below the form.
- Disabled while another authentication request is in progress.

### REQ-AUTH-005 — Authentication Outcomes

| Outcome                    | What the User Sees                                                  |
|----------------------------|---------------------------------------------------------------------|
| Successful login           | Navigated to the trips list page.                                   |
| Email verification pending | Inline message: email verification required. "Resend" option shown. |
| Verification email re-sent | Inline confirmation that a verification email was re-sent.          |
| Wrong password             | Error shown inline or as a notification.                            |
| Account not found          | Error shown inline.                                                 |
| Username already taken     | Error shown inline (Register tab).                                  |
| Weak password              | Error shown inline (Register tab).                                  |
| Invalid email format       | Error shown inline.                                                 |

### REQ-AUTH-006 — Resend Verification Email

- Visible only when email verification is pending.
- Sends a new verification email using the entered credentials.

### REQ-AUTH-007 — Session Persistence

- If a user is already signed in when the app starts, they are taken directly to the trips list
  without seeing the login screen.

### REQ-AUTH-008 — Route Protection

- Users who are not signed in cannot access any trip pages; they are redirected to the login screen.
- Users who are already signed in cannot access the login or onboarding screens; they are redirected
  to the trips list.

---

## 6. Module: App-Level Settings

### REQ-SET-001 — Settings Access

- On the Home page toolbar, a **settings gear icon** opens a popup menu.

### REQ-SET-002 — Theme Switcher

- Shows a toggle switch labelled "Dark Theme" (localized).
- Toggling switches the app between dark and light theme.
- The chosen theme is remembered across app restarts.

### REQ-SET-003 — Language Switcher (Home Toolbar)

- Shows a submenu of supported languages (same set as onboarding).
- Selecting a language immediately re-renders the entire app.
- The chosen language is remembered across app restarts.

### REQ-SET-004 — Logout

- Logs the user out and returns them to the login/onboarding screen.

---

## 7. Module: Trip List (Home Page)

### REQ-TL-001 — Trip List Display

- Shows all trips belonging to or shared with the current user.
- Trips are grouped into two sections: **Upcoming Trips** (end date ≥ today) and **Past Trips** (end
  date < today).
- Each section has year filter chips derived from trip start dates.
- Only trips matching the selected year chip are shown in each section.

### REQ-TL-002 — Trip Card Content

- Each trip is shown as a card containing:
    - Trip thumbnail image.
    - Trip name.
    - Date range (formatted with month and day).
    - Contributor count badge.
    - Budget display (formatted currency amount).

### REQ-TL-003 — Trip Card Grid

- Cards are displayed in a responsive grid: more columns on wider screens, fewer on narrow screens.

### REQ-TL-004 — Trip Card Actions

- Each card has a popup menu with:
    - **Copy Trip** — opens the Copy Trip dialog.
    - **Delete Trip** — opens the Delete Trip confirmation dialog.

### REQ-TL-005 — Opening a Trip

- Tapping a trip card opens the trip editor.
- The page appears immediately using any cached data; a progress indicator shows background loading
  status.
- Recently opened trips are kept in memory for instant switching.

### REQ-TL-006 — Empty State

- When no trips exist, a localized "No trips created" message is shown centered.

### REQ-TL-007 — Rebuild Efficiency

- The trip list only refreshes when a trip is created or deleted, not when trip details are updated.

### REQ-TL-008 — FAB: Create Trip

- A centred button labelled "Plan a Trip" with a location icon is shown.
- Hidden when the soft keyboard is open.
- Tapping opens the Create Trip dialog.

---

## 8. Module: Create Trip

### REQ-CT-001 — Create Trip Dialog Content

- Shows (in order):
    1. **Thumbnail picker:** Horizontal carousel of predefined trip images. User selects one.
    2. **Date range picker:** Selects start and end date. Earliest selectable date is today.
    3. **Trip name text field:** Free text. Required.
    4. **Budget editor:** Amount field + currency dropdown. Defaults to INR.

### REQ-CT-002 — Validation (Create)

- The submit button is enabled only when:
    - Trip name is non-empty.
    - Both start and end dates are set.
    - End date is on or after start date.

### REQ-CT-003 — Submit Behaviour

- The current user is automatically added as the sole contributor.
- The trip is created and the dialog closes.

### REQ-CT-004 — Default Values

- Currency: INR.
- Thumbnail: Road Trip image.
- Budget amount: 0.
- Contributors: current user only.

---

## 9. Module: Copy Trip

### REQ-CP-001 — Copy Trip Dialog Content

- Shows:
    1. **Trip name field:** Pre-filled with "Copy of \<original name\>". Must be non-empty.
    2. **Start date picker:** Defaults to today. Selecting a new start date automatically calculates
       the end date to preserve the original trip's duration.
    3. **Date shift info:** Read-only text showing original date range → new date range.
    4. **Contributors editor:** Pre-filled from the source trip. Users can add or remove
       contributors.
    5. **Budget editor:** Pre-filled from the source trip. Both amount and currency are editable.

### REQ-CP-002 — Validation (Copy)

- Trip name must be non-empty (trimmed).
- Start date must be selectable from today up to 10 years ahead.

### REQ-CP-003 — Submit Behaviour

- A new trip is created, copying all entities from the original trip with dates shifted to match the
  new start date.
- On success, the new trip appears in the trip list.
- On failure, an error message is shown.

---

## 10. Module: Delete Trip

### REQ-DT-001 — Delete Trip Dialog Content

- Shows a warning icon and localized confirmation text.
- Two buttons: **No** (dismisses dialog) and **Yes** (proceeds with deletion, styled as
  destructive).

### REQ-DT-002 — Delete Behaviour

- The trip and all its data (stays, transits, expenses, itineraries) are permanently removed.
- The dialog closes and the trip disappears from the list.

---

## 11. Module: Trip Editor — Overview & Navigation

### REQ-TE-001 — Trip Editor Sections

- **Mobile:** Two sections accessible via a bottom navigation bar:
    1. **Itinerary** (timeline per day).
    2. **Budgeting** (expenses, debt, breakdown).
- **Tablet/Web:** Both sections displayed side-by-side. No bottom navigation bar.

### REQ-TE-002 — App Bar

- Shows the trip name (or a loading indicator) and action buttons.
- Contains a settings/edit button to open the Trip Details editor.

### REQ-TE-003 — FAB: Add Entity

- A centred add (+) button.
- Tapping opens a bottom sheet (mobile) or dialog showing creation options:
    - **Expense** — Opens expense editor.
    - **Travel** — Opens transit/journey editor (with travel mode sub-selection).
    - **Stay** — Opens lodging editor.
    - **Itinerary Item** — Shows three sub-action buttons inline:
        - **Sight** — Creates a new sight for the day currently displayed in the itinerary viewer.
        - **Note** — Creates a new note for the current itinerary day.
        - **Checklist** — Creates a new checklist for the current itinerary day.
    - Tapping any itinerary sub-action closes the bottom sheet and opens the plan data editor with
      the corresponding tab and the new item ready to edit.

### REQ-TE-003a — Itinerary Date Selection in Creator

- The creator bottom sheet allows the user to choose which itinerary date the new
  sight/note/checklist belongs to.
- Defaults to the date currently displayed in the itinerary viewer.

### REQ-TE-004 — Entity Editor Presentation

- **Mobile:** Entity editors open as a draggable bottom sheet (can expand to full-height).
- **Tablet/Web:** Same bottom sheet, but the editor may use wider internal layouts.

### REQ-TE-005 — Entity Editor Modes

- **Create:** A blank form is shown for creating a new entity.
- **Edit:** The form is pre-populated with existing values for editing.

### REQ-TE-007 — Confirm Action (Save / Submit)

- A confirm (✓) floating action button is shown in the entity editor.
- The button is **disabled** (greyed) when the form is invalid or has unresolved conflicts.
- Tapping the confirm button when enabled saves the entity and **fully dismisses** the Creator
  bottom-sheet (the entire sheet closes, not just the editor within it).
- On save, the itinerary timeline and expense list are updated to reflect the new or modified
  entity.

### REQ-TE-006 — Editor View Switching

- Editors that support conflict detection show two views:
    - **Editor form** — the fields for the entity.
    - **Conflict resolution view** — displays detected conflicts and resolution options.
- The user navigates between views via buttons (not by swiping).

---

## 12. Module: Trip Details Editor

### REQ-TD-001 — Displayed Fields

- **Trip title:** Editable text field. Bold, large typography.
- **Date range:** Start and end date pickers.
- **Budget:** Amount + currency dropdown.
- **Contributors ("Trip Mates"):** List of contributor username chips with add/remove capability.

### REQ-TD-002 — Title Validation

- Name must be non-empty after trimming.

### REQ-TD-003 — Date Range Change → Conflict Detection

- Changing the trip's date range triggers a scan of all existing stays, transits, and sights for
  items that would fall outside the new date range.
- If conflicts are found, a conflict banner appears and the save button is disabled until conflicts
  are resolved or acknowledged.

### REQ-TD-004 — Contributor Changes → Expense Split Detection

- Adding or removing a contributor triggers detection of all expense-bearing items.
- These are shown as expense split change entries in the resolution view.
- The user can opt-in/opt-out each expense from including the new contributor in its split.
- A tri-state checkbox indicates: all selected / none selected / mixed.

### REQ-TD-005 — Contributor Add Flow

- An "Add" button reveals a text field.
- The user types a username. The system checks whether that username exists.
- If the username does not exist, an error is shown.
- If valid, the contributor is added to the local list immediately.
- The current user cannot be removed from the contributors list.

### REQ-TD-006 — Submit

- Saves the updated trip details.
- If a conflict plan exists and has been confirmed, all related changes (date adjustments,
  deletions, expense splits) are saved together.

### REQ-TD-007 — Removed Contributor Notification

- After a successful update that removed contributors, a message is shown:  
  *"Past expenses with removed tripmates are preserved for historical accuracy."*

---

## 13. Module: Itinerary Timeline (Per-Day View)

### REQ-IT-001 — Day Navigation

- The itinerary shows the current day with left/right arrow buttons to move between trip days.
- A calendar icon opens a date picker allowing direct jump to any trip day.
- Day transitions animate with fade + slide.
- The currently viewed day is preserved when switching between app tabs and returning to the
  itinerary.

### REQ-IT-002 — Day View Tabs

- Each day view has **4 tabs**:
    1. **Timeline** — Chronological list of all events for the day.
    2. **Notes** — Viewer for day notes.
    3. **Checklists** — Viewer for day checklists.
    4. **Sights** — Viewer for day sights.

### REQ-IT-003 — Timeline Events

- For each day, the timeline aggregates:
    - **Check-in:** A stay whose check-in date falls on this day.
    - **Check-out:** A stay whose check-out date falls on this day.
    - **Full-day lodging:** A stay that spans across this day.
    - **Transits:** All transit legs whose departure date falls on this day.
    - **Sights:** All sights for this day (from plan data).
- Events are sorted chronologically by their time.

### REQ-IT-004 — Timeline Event Card Content

- Each event card shows:
    - Type-specific icon and colour.
    - Time (formatted).
    - Title (descriptive, e.g., "Stay at Hotel X from Jan 5 to Jan 7").
    - Subtitle (contextual detail, e.g., location name).
    - Notes preview (if any).
    - Confirmation ID badge (if any).
- Tapping an event opens its editor.
- Swiping an event offers a delete option.

### REQ-IT-005 — Connected Journey Display

- Transit legs belonging to the same journey are rendered as connected segments.
- Each leg shows its position: start / middle / end / standalone.
- Layover duration is displayed between connected legs.
- Tapping any leg in a journey opens the full journey editor for that journey.

### REQ-IT-006 — Timeline Rebuild

- The timeline refreshes when any entity (transit, stay, expense, plan data) relevant to the
  displayed day is created, updated, or deleted.

---

## 14. Module: Stay (Lodging) Editor

### REQ-ST-001 — Displayed Fields

1. **Location:** Location search with autocomplete. Required.
2. **Check-in / Check-out date-times:** Date-time pickers constrained within trip date range.
   Required. Check-out must be after check-in.
3. **Confirmation ID:** Optional text field.
4. **Notes:** Optional expandable text area.
5. **Payment Details (Expense):** Shared expense editing component (
   see [Module 19](#19-module-expense-split--payment-details-shared-component)).

### REQ-ST-002 — Validation

- Location must be set.
- Check-in date-time must be set.
- Check-out date-time must be set.
- Check-out must be on or after check-in.
- Expense details must be valid (at least one payer and one person in the split).

### REQ-ST-003 — Conflict Detection on Date Change

- Changing check-in or check-out triggers conflict scanning against other stays, transits, and
  sights.
- **Stay-specific rule:** Transits and sights that are *fully contained* within a stay's check-in to
  check-out period do NOT conflict — travellers can visit sights and take transits during their
  stay. Only overlaps at check-in/check-out boundaries or cases where the stay is contained within a
  transit are conflicts.

### REQ-ST-004 — Entity Display Name

- Format: "Stay at \<location\> from \<month day\> to \<month day\>".
- Falls back to "Unnamed Entry" if location or dates are incomplete.

---

## 15. Module: Transit Editor (Single Leg)

### REQ-TR-001 — Displayed Fields

1. **Travel type:** Dropdown showing all travel modes (bus, flight, rented vehicle, train, walk,
   ferry, cruise, vehicle, public transport, taxi), each with an icon.
2. **Operator section (conditional):** Shown only for modes that need prior booking (all except walk
   and vehicle).
    - For **flight:** A specialized airline + flight number editor.
    - For **other bookable types:** A simple text field for operator name.
3. **Departure:** Location search with autocomplete + date-time picker. For flights,
   airport-specific search.
4. **Arrival:** Location search with autocomplete + date-time picker. For flights, airport-specific
   search.
5. **Confirmation ID (conditional):** Shown only for bookable types. Optional.
6. **Notes:** Optional expandable text area.
7. **Payment Details (Expense):** Shared expense editing component.

### REQ-TR-002 — Validation

- Departure location must be set.
- Arrival location must be set.
- Departure date-time must be set.
- Arrival date-time must be set.
- Arrival must be strictly after departure.
- For flights: operator must contain at least 3 space-separated parts (e.g., "IndiGo 6E 2341").
- Expense details must be valid.

### REQ-TR-003 — Travel Type Change

- Changing the travel type may show or hide the operator/confirmation sections.
- Switching from flight to non-flight may reset the operator and location fields.

### REQ-TR-004 — Entity Display Name

- Format: "\<departure\> to \<arrival\> on \<month day\>".
- Falls back to "Unnamed Entry".

### REQ-TR-005 — Flight Operator Validation

- The operator field for flights must contain at least 3 space-separated non-empty parts.
- Example valid: "IndiGo 6E 2341".
- Example invalid: "IndiGo", "", "IndiGo ".

### REQ-TR-006 — Smart Timezone Display

- When both departure and arrival locations are set, timezone information is displayed.
- If both locations share the same timezone, only one timezone string is shown.
- If both locations are in different timezones but the same region (e.g., Europe/Berlin and
  Europe/Amsterdam), the region is shown once with both cities: "Europe: Berlin → Amsterdam".
- If the locations are in different regions, both full timezone strings are shown: "America/New
  York → Europe/London".

---

## 16. Module: Multi-Leg Journey Editor

### REQ-JE-001 — Journey Initialization

- If the transit being edited belongs to a journey, all legs of that journey are loaded for editing.
- If it does not belong to a journey, the editor starts with a single standalone leg.
- Legs are sorted by departure time.

### REQ-JE-002 — Journey Display

- Each leg is shown in a collapsible panel.
- The selected/initial leg is expanded by default.
- A journey overview header shows the overall departure → arrival with layover summary.

### REQ-JE-003 — Add / Remove Legs

- An "Add Connecting Leg" button appends a new empty leg.
- New legs inherit the travel type and use the previous leg's arrival location as their departure.
- Each leg except the first can be removed.
- Removing a leg only takes effect when the user saves (clicks the confirm button); it is not
  immediately committed.

### REQ-JE-004 — Leg Connectivity Constraint

- Each subsequent leg's earliest allowed departure time is the previous leg's arrival time.

### REQ-JE-005 — Journey-Level Validation

- All individual legs must be valid.
- Each leg's arrival must be at least 1 minute after its departure.
- Each connecting leg's departure must be on or after the previous leg's arrival.

### REQ-JE-006 — Journey-Level Conflict Detection

- When any leg's time changes, conflicts are scanned across all legs against existing trip entities,
  with duplicates removed.

### REQ-JE-007 — Save Behaviour

- On submit, all legs are saved: new legs are created, existing legs are updated.

### REQ-JE-008 — Layover Display

- Between consecutive legs, the layover duration is calculated and shown.

---

## 17. Module: Itinerary Plan Data Editor (Sights / Notes / Checklists)

### REQ-IPD-001 — Entry Modes

- **Create New Item:** Opens the editor with a new item already appended (sight, note, or
  checklist). The new item is created for the date currently displayed in the itinerary viewer (or
  the date chosen in the creator bottom sheet).
- **Edit Existing Item:** Opens the editor scrolled/focused to the item at the specified position.

### REQ-IPD-002 — Tabs

- Three tabs: **Sights**, **Notes**, **Checklists**.
- The initial tab is determined by which item type was selected.
- Switching tabs shows the selected tab's content directly; all content scrolls with the page's
  single scroll area (no nested scrolling within individual items).

### REQ-IPD-003 — Sights Tab

- List of sight entries, each with:
    - **Name:** Required, minimum 3 characters.
    - **Location:** Optional location search with autocomplete.
    - **Visit time:** Optional date-time picker.
    - **Description:** Optional text.
    - **Expense:** Optional payment details.
- Add button appends a new blank sight.
- Remove button deletes a sight.

### REQ-IPD-004 — Sight Overlap Detection

- Conflict detection for sights is triggered **only** when visit times actually change — when a time
  is set, cleared, or modified via the time picker, or when a sight with a time is added or deleted.
- Editing non-time fields (title, location, description, expense) does **not** trigger conflict
  detection.
- If two sights on the same day have the same visit time, an error is shown: "Sights cannot overlap
  on the same day".
- Standard conflict detection also runs against transits and stays.

### REQ-IPD-005 — Notes Tab

- List of text entries.
- Each note must be non-empty.
- Add button appends a blank note. Remove button deletes a note.

### REQ-IPD-006 — Checklists Tab

- List of checklists, each with:
    - **Title:** Required, minimum 3 characters.
    - **Items:** At least one item required. Each item text must be non-empty.
    - Each item has a checkbox for checked/unchecked state.
- Add checklist / add item / remove item buttons.

### REQ-IPD-007 — Validation

- Valid if:
    - There is no content at all (empty plan data is acceptable), OR
    - All sights have names of at least 3 characters.
    - All notes are non-empty.
    - All checklist titles are at least 3 characters and all items are non-empty.

### REQ-IPD-008 — Submit

- Changes to plan data are saved only when the user clicks the save/confirm button.
- Closing the editor without saving discards all changes.
- Reopening the editor shows the last saved state, not the unsaved edits.

---

## 18. Module: Standalone Expense Editor

### REQ-SE-001 — Displayed Fields

1. **Category badge:** Shows the expense category with icon and colour.
2. **Title:** Editable text field.
3. **Paid-On date:** Date picker. The date picker button updates to display the newly selected date
   immediately.
4. **Description:** Optional text field.
5. **Payment Details (Expense):** Shared expense editing component.

### REQ-SE-002 — Layout Adaptation

- **Mobile:** Fields stacked vertically.
- **Tablet/Web:** Date/description on the left column; payment details on the right column.

### REQ-SE-003 — Validation

- Expense details must be valid (at least one payer and one person in the split).

### REQ-SE-004 — Category List

- Other, Flights, Lodging, Car Rental, Public Transit, Food, Drinks, Sightseeing, Activities,
  Shopping, Fuel, Groceries, Taxi.

---

## 19. Module: Expense Split & Payment Details (Shared Component)

### REQ-EX-001 — Component Structure

- Two tabs: **Paid By** and **Split By**.
- A currency selector + total amount display at the top.

### REQ-EX-002 — Paid By Tab

- Shows all trip contributors.
- Each contributor has an amount field (how much they paid).
- Total expense is computed as the sum of all paid-by amounts.

### REQ-EX-003 — Split By Tab

- Shows all trip contributors with checkboxes.
- Checked contributors are included in the expense split.
- At least one contributor must be checked.

### REQ-EX-004 — Currency Selector

- Dropdown of all supported currencies.
- Each currency shows: code, name, symbol.
- Changing currency updates the expense's currency.

### REQ-EX-005 — Validation

- At least one payer must have a non-zero amount.
- At least one person must be included in the split.

### REQ-EX-006 — Live Updates

- Any change to payers, split members, or currency immediately updates the parent form.

---

## 20. Module: Budgeting — Expenses List, Debt Summary, Breakdown

The budgeting module is available throughout the trip editor, including in dialogs and bottom
sheets. When the trip's currency is updated, budgeting data reflects the change automatically.

### REQ-BU-001 — Budgeting Page Structure

- Three collapsible sections:
    1. **Expenses** (initially expanded).
    2. **Debt** (collapsed).
    3. **Breakdown** (collapsed).

### REQ-BU-002 — Expenses List

- Shows all expense-bearing items (stays, transits, sights, standalone expenses).
- **Budget tile:** At the top, shows total budget vs. total spent.
- **Sort toggles:** Three toggle buttons:
    - **Cost:** Toggles between low→high and high→low.
    - **Category:** Groups by expense category.
    - **Date:** Toggles between old→new and new→old.
- Default sort: newest first.

### REQ-BU-003 — Expense List Item Display

- Each item shows:
    - Category icon.
    - Title / display name.
    - Formatted total amount.
    - Payer initials/badges.
- Tapping opens the expense editor (for standalone) or the parent entity editor.
- Swipe to delete.

### REQ-BU-004 — Debt Summary

- Shows each debt as: "\[person\] needs to pay \[person\] \[amount\]".
- Contributors are shown as badges; the current user is labelled "You".
- If there are no expenses or total expenditure is 0, shows "No expenses to split".

### REQ-BU-005 — Budget Breakdown

- **By Category:** Interactive pie chart of total spending per expense category. Tapping a section
  highlights it without unnecessary re-renders.
- **By Day:** Breakdown of total spending per trip day.

### REQ-BU-006 — Expense List Rebuild

- The expense list, debt summary, and breakdown charts update when expenses are added, changed, or
  removed. Tab contents must refresh after any expense update.

---

## 21. Module: Conflict Detection & Resolution

### REQ-CD-001 — Conflict Triggers

- Conflicts are detected **only** when time-related data changes:
    - Trip date range changes.
    - Trip contributors change.
    - Stay check-in/out times change.
    - Transit departure/arrival times change (single or journey).
    - Sight visit times change (set, cleared, or modified via the time picker).
- Conflicts are **not** triggered when non-time properties change (e.g., sight title, location,
  description, expense, transit operator name, confirmation IDs, etc.).

### REQ-CD-002 — Conflict Types

| Conflict Type                 | What It Means                                                                         |
|-------------------------------|---------------------------------------------------------------------------------------|
| **Date out-of-bounds**        | An entity's time range falls partially or fully outside the new trip date range.      |
| **Temporal overlap**          | Two entities' time ranges overlap in a way that is not allowed by the conflict rules. |
| **Same-day sight overlap**    | Two sights on the same day have identical visit times.                                |
| **Contributor expense split** | Contributors were added/removed from the trip; expenses may need split updates.       |

### REQ-CD-003 — How Overlaps Are Classified

- **Adjacent events are not conflicts:** When one event ends at exactly the same time another
  starts (e.g., a transit arriving at 2:00 PM and a stay checking in at 2:00 PM), these are
  adjacent, not overlapping.
- **Boundary match:** The start times of both events are identical, or the end times are identical —
  this is a genuine temporal overlap.
- **Before/After:** An entity is entirely before or after the reference range (including adjacent
  events).
- **Contained within:** An entity is fully within the reference range.
- **Contains:** The reference range is fully within the entity.
- **Partial overlap:** An entity starts before and ends during, or starts during and ends after, the
  reference range.

### REQ-CD-004 — Conflict Rules by Entity Type

- **Trip date range change:** Conflicts with entities that are before, after, partially overlapping,
  or containing the new date range.
- **Stay vs Transit/Sight:** A transit or sight that is fully *contained within* a stay's check-in
  to check-out period is **not** a conflict. Travellers can visit sights and take transits during
  their stay. Only boundary matches (at exact check-in/out time), partial overlaps crossing the
  boundary, and other stays overlapping are conflicts.
- **Stay vs Stay:** All overlaps are conflicts.
- **Transit/Sight vs Stay:** A transit or sight happening during a stay (the stay *contains* it) is
  **not** a conflict. Only boundary matches and partial overlaps crossing the stay's boundary are
  conflicts.
- **Transit/Sight vs Transit/Sight:** All boundary matches, containments, and partial overlaps are
  conflicts.

### REQ-CD-005 — Clamping (Auto-Resolution)

- For partial overlaps, the system attempts to automatically adjust the conflicting entity's times:
    - **Transit:** Adjusts departure or arrival by ±1 minute from the conflict boundary.
    - **Stay:** Adjusts check-in or check-out to the nearest half-hour boundary.
    - **Sight:** Shifts visit time by ±1 minute for boundary matches only.
- For boundary matches:
    - **Transit:** When starts match, pushes departure after the other event ends. When ends match,
      pulls arrival before the other event starts.
    - **Stay:** When check-in times match, pushes check-in to next half-hour after the other event.
      When check-out times match, pulls check-out to previous half-hour before the other event.
    - **Sight:** Shifts visit time after or before the other event.
- When an entity is fully contained within another or vice versa and clamping is not possible, it is
  marked for deletion.
- Adjacent events never need clamping.

### REQ-CD-006 — Conflict Resolution UI

- When conflicts are detected:
    - A **sticky conflict banner** appears above the editor form showing the conflict count and a "
      View Conflicts" button.
    - The **save button is disabled** until conflicts are acknowledged.
- The conflict resolution view shows:
    - A header with a back button.
    - A status bar with conflict summary.
    - Sections for Stays, Transits, and Sights (each section refreshes independently).
    - Each conflicted entity shows:
        - Original vs. modified (clamped) times.
        - A **delete/restore toggle** button.
        - For clamped entities: editable time fields to manually adjust.
    - A **Confirm** button to acknowledge the plan.

### REQ-CD-007 — Conflict Confirmation

- Pressing Confirm marks the plan as acknowledged, hides the banner, and re-enables the save button.
- The actual changes are committed only when the user presses the save button.

### REQ-CD-008 — Editing Conflicted Entities

- When a user edits the time of a conflicted entity on the resolution page:
    1. If the new time conflicts with the entity being edited, the change is reverted with an error.
    2. If the new time conflicts with other existing entities, new conflicts are added to the plan.

### REQ-CD-009 — Expense Deletion Sync

- When a timeline entity is marked for deletion in the conflict plan, its associated expense
  change (if any) is also marked for deletion.
- When restored, the expense change is also restored.

### REQ-CD-010 — Efficient UI Updates

- Conflict UI updates are targeted: adding/removing entire conflict sections triggers a
  section-level refresh; updating a single conflict item triggers only that item's refresh.

### REQ-CD-011 — Self-Exclusion

- When scanning for conflicts, the entity currently being edited (or all legs of a journey, or all
  sights of an itinerary) is excluded to avoid detecting conflicts with itself.

---

## 22. Module: Saving Changes (Batch Commit)

### REQ-UP-001 — What Gets Saved

- When saving changes that involve conflicts, the save includes:
    - The updated entity itself.
    - All time/date adjustments to conflicted entities.
    - All deletions of conflicted entities.
    - All expense split changes.
    - Any new or removed itinerary days (when trip dates change).
    - Recalculated total expenditure.

### REQ-UP-002 — Atomic Save

- All related changes are saved together as a single operation to prevent partial updates.

### REQ-UP-003 — Expense Selection in Conflict Plan

- For contributor changes, the user can select which expenses include the new contributor in their
  split:
    - Select all expenses.
    - Deselect all expenses.
    - Toggle individual expenses.
    - Tri-state indicator shows: all selected / none selected / mixed.

---

## 23. Validation Rules Reference

| Entity                 | Rules                                                                                                                                              | Error Condition                                                    |
|------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------|
| **Trip**               | Name is non-empty; end date ≥ start date; both dates set.                                                                                          | Missing name or invalid date range.                                |
| **Stay**               | Location set; check-in set; check-out set; expense valid.                                                                                          | Missing location, dates, or invalid expense.                       |
| **Transit**            | Departure and arrival locations set; departure and arrival times set; arrival after departure; for flights: operator has ≥ 3 parts; expense valid. | Missing locations/times, arrival ≤ departure, bad flight operator. |
| **Journey**            | All legs valid; each leg's arrival ≥ departure + 1 min; each connecting departure ≥ previous arrival.                                              | Invalid leg or time sequence error.                                |
| **Sight**              | Name is non-empty and at least 3 characters.                                                                                                       | Name too short or empty.                                           |
| **Checklist**          | Title is non-empty and at least 3 characters; at least one item; all items non-empty.                                                              | Missing title or empty items.                                      |
| **Plan Data**          | Empty plan data is valid; otherwise all sights, notes, and checklists must individually be valid.                                                  | Any sub-item failing its validation.                               |
| **Expense**            | At least one payer; at least one person in the split.                                                                                              | No payers or no split members.                                     |
| **Standalone Expense** | Expense details valid.                                                                                                                             | Invalid expense data.                                              |

---

## 24. Mobile vs Tablet/Web Layout Differences

| Area                               | Mobile (≤ 1000px)                              | Tablet/Web (> 1000px)                                            |
|------------------------------------|------------------------------------------------|------------------------------------------------------------------|
| **Startup**                        | Onboarding → Login (sequential screens)        | Onboarding (left) + Login (right) side-by-side                   |
| **Home App Bar**                   | Full width                                     | Half width (centred)                                             |
| **Trip List Grid**                 | Fewer columns (1–2 cards per row)              | More columns (3+ cards per row)                                  |
| **Trip Editor**                    | Bottom nav bar to switch Itinerary / Budgeting | Side-by-side split (Itinerary left, Budgeting right), no nav bar |
| **Trip Editor FAB**                | Docked to bottom nav bar                       | Floating at bottom centre with padding                           |
| **Entity Editors**                 | Draggable bottom sheet (full-screen capable)   | Same bottom sheet; editor internals may use row layouts          |
| **Expense Editor**                 | Single column layout                           | Two-column layout (details left, payment right)                  |
| **Language Switcher (Onboarding)** | Shows "Next" button alongside language buttons | "Next" button hidden; login visible alongside                    |

---

## 25. Internationalization

### REQ-I18N-001 — Localized Strings

- All user-facing text is available in English, Hindi, and Tamil.

### REQ-I18N-002 — Runtime Language Switch

- Language can be switched at any time (onboarding or settings).
- The entire app immediately re-renders in the selected language.
- The selected language is remembered across app restarts.

### REQ-I18N-003 — Date/Time Formatting

- Dates and times use consistent formatting (e.g., month abbreviations, day-month format).

---

## 26. Real-Time Collaboration & Sync

### REQ-SYNC-001 — Live Updates

- When a trip is opened, the app listens for changes made by other contributors in real time.
- Changes to transits, stays, expenses, itinerary plan data, and trip details are received and
  reflected in the UI automatically.

### REQ-SYNC-002 — Change Classification

- Each incoming change is classified as a creation, update, or deletion, and the UI updates
  accordingly.

### REQ-SYNC-003 — Subscription Lifecycle

- Live listening begins when a trip is opened.
- It stops when the user navigates back to the home page or opens a different trip.
- If trip dates change, listening is refreshed to account for added/removed days.

---

## 27. App Update Mechanism

### REQ-UPD-001 — Update Check

- On startup and periodically, the app checks for the latest available version and release notes.

### REQ-UPD-002 — Update Notification

- If an update is available, a dialog shows the version and release notes.
- If the update is mandatory (the current version is below the minimum supported version), the
  dialog cannot be dismissed.

---

## 28. Test Traceability

Each requirement ID (e.g., REQ-AUTH-002) should be referenced in test names or descriptions to
enable traceability.

### Recommended Test Mapping

| Requirement Group       | Key Scenarios to Test                                                       | UI Elements to Verify                                                     |
|-------------------------|-----------------------------------------------------------------------------|---------------------------------------------------------------------------|
| AUTH                    | Login, register, third-party sign-in, logout                                | Login/register tabs, form validation, error messages, navigation          |
| SET                     | Theme toggle, language switch, logout                                       | Theme toggle, language submenu, logout behaviour                          |
| TL (Trip List)          | Trip list loading, create/delete trip                                       | Grid cards, year chips, empty state, popup actions                        |
| CT (Create Trip)        | Trip creation with valid/invalid fields                                     | Dialog fields, validation toggle, submit                                  |
| CP (Copy Trip)          | Copy with date shift, contributor changes                                   | Pre-filled fields, date shift display, submit                             |
| DT (Delete Trip)        | Trip deletion confirmation                                                  | Confirmation dialog, trip removal                                         |
| TD (Trip Details)       | Date range change with conflicts, contributor add/remove                    | Fields, conflict banner, contributor chips                                |
| IT (Itinerary)          | Day navigation, tab switching, day preservation                             | Timeline events, notes/checklists/sights viewers                          |
| ST (Stay)               | Stay creation/editing, date change with conflicts                           | Form fields, date pickers, conflict banner                                |
| TR (Transit)            | Transit creation/editing, travel type change, flight validation             | Travel type picker, operator field, flight validation                     |
| JE (Journey)            | Multi-leg creation, add/remove legs, layover, connectivity                  | Leg panels, add/remove, layover, connectivity constraint                  |
| IPD (Plan Data)         | Sight/note/checklist CRUD, time-based conflict detection, tab switching     | Sight/note/checklist forms, tab switching, validation errors              |
| SE (Standalone Expense) | Expense creation/editing with category, date, split                         | Category badge, title, date, expense split                                |
| EX (Expense Component)  | Payer/split changes, currency selection                                     | Paid By/Split By tabs, currency selector, total display                   |
| CD (Conflicts)          | All conflict types, clamping, resolution, confirmation                      | Conflict banner, resolution page sections, clamped values, confirm button |
| BU (Budgeting)          | Sort toggles, debt calculation, breakdown charts, refresh on expense change | Sort toggles, debt rows, breakdown charts, budget tile                    |
| SYNC                    | Real-time updates from other contributors                                   | Live UI updates on remote changes                                         |
| PRINT                   | Print dialog options, transit selection, PDF generation                     | Dialog fields, transit toggles, generated PDF content                     |

---

## 29. Performance & User Experience

### REQ-PERF-001 — Background Preloading

- On app launch, the most frequently visited trip is preloaded in the background so that data is
  ready before the user interacts.

### REQ-PERF-002 — Instant-On Trip Loading

- Opening a trip must never show a blocking "Loading" screen for the entire page.
- The trip editor structure appears first, with individual sections (timeline, budgeting) loading
  their data as it becomes available.

### REQ-PERF-003 — Smooth Interactions

- Heavy computations (such as conflict detection scanning) run in the background so the interface
  remains smooth and responsive.

### REQ-PERF-004 — Loading Indicators

- **Shimmers:** List views (transits, stays, sights) display shimmer animations while waiting for
  data.
- **Progress Bar:** A linear progress bar is visible at the top of the trip editor until all data
  sections have loaded.

### REQ-PERF-005 — Edit Accessibility

- Navigation to edit pages is blocked until the trip data is fully loaded, with a user-friendly
  message or loading indicator shown if the user tries to edit prematurely.

---

## 30. Module: Print Trip

### Overview

Users can generate a PDF document summarising their trip and print, share, or save it locally. The
PDF includes an overview header, a per-day timeline (with transits, stays, and sights), and an
expense table — all controlled by user-selectable options.

### Entry Points

| Location                 | Trigger                                                                                                                                                                                                  |
|--------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Trip Editor toolbar      | Print icon button (all layouts).                                                                                                                                                                         |
| Trips List overflow menu | "Print trip" menu item — works for any trip. If the trip is already open, the dialog opens directly. Otherwise, the trip is loaded in the background first, and the dialog opens once loading completes. |

### Loading State

- All form content (title field, section chips, transit filter toggles) is shown **immediately**
  when the dialog opens.
- If the trip data is not yet fully loaded, the transit selection area shows a progress bar.
- A **minimum visual delay of 1 second** is enforced: even if loading completes quickly, the
  progress indicator stays visible for the full duration to avoid a jarring flash.
- Once the trip data is ready and the minimum delay has passed, transit items appear.
- The Generate PDF button is disabled until transits are ready.

### Print Options Dialog

The dialog has a branded gradient header (matching other trip dialogs), a scrollable body, and a
fixed footer with action buttons.

- **Document Title** — Editable text field, defaults to trip name.
- **Section toggles** — Displayed as filter chips. Each chip has an icon and label. Sections:
  Checklists, Expenses, Sights/Places, Notes. All enabled by default; toggling a chip off excludes
  that section from the PDF. Selected and unselected states are clearly distinguishable in both
  light and dark modes.

#### Transit Section

- **Section title** — "Transit Options".
- **Inter-city travels** and **Intra-city travels** — Two compact switches displayed side-by-side.
  Both enabled by default. Toggling filters the visible transit list below.

#### Transit Selection List

Below the transit options, each transit is shown as a selectable item:

- **Standalone transits** — Single-leg transits shown with a checkbox, route summary (type, cities),
  and departure date.
- **Multi-leg journeys** — Grouped in a bordered card showing the overall route (first departure
  city → last arrival city), leg count, and date. Each journey card has:
    - A **merge/expand toggle** — an animated button that switches between "Merge legs" and "Show
      legs" states. When merged, the PDF prints a single timeline entry for the entire journey (
      first departure → last arrival). When expanded, individual legs are listed with checkboxes so
      the user can include/exclude specific legs.
    - The toggle animates the icon, label text, and styling on state change. The legs section uses
      an animated expand/collapse transition.
    - A journey-level checkbox toggles all legs at once.
- All transits are selected by default.
- Only selected transits appear in the generated PDF.

#### Inter-City / Intra-City Classification

- **Inter-city**: Departure city differs from arrival city.
- **Intra-city**: Departure city is the same as arrival city.
- If either city is unknown, the transit is treated as inter-city.

#### Actions

- Cancel (text button) and Generate PDF (filled button with print icon).
- While generating, the button shows a loading indicator and is disabled.

### PDF Layout

The generated PDF is entirely **black and white** — no colour is used. The design relies on
typography weight, letter-spacing, borders, and spatial hierarchy to remain visually clear when
printed.

- **Page header** — App logo and app name "Wandrr". The trip name is **not** shown in the header.
- **Page footer** — Page number ("Page X of Y").
- **Cover block** — Trip title (large bold), date range, and info pills (day count, travellers,
  budget) inside a bordered container.

| Section           | Content                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
|-------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Per-day itinerary | **Unified chronological timeline**: each day has a date badge, followed by timeline markers. All timed events — check-in, check-out, transits, and timed sight visits — are merged and sorted by time. Notes and checklists appear after timed events. Accommodations are represented through check-in/check-out events in the timeline (no separate section). Confirmation IDs and other unnecessary details are omitted. **Transits** show departure → arrival locations and both times on one line. If a transit's arrival falls on a different day, it appears as a separate "ARRIVE" event on that day. Merged journeys show a single entry with first departure and last arrival. Only selected transits are shown. |
| Sights / Places   | Sights that have **no visit time** are collected into a standalone section after the per-day timeline. Each shows name (bold), day date (muted), and description (if any).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| Expenses          | Table with header row, alternating data rows, and a bold total row.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |

- A4 format, 40pt margins.
- Empty sections are skipped automatically.
- Multi-page with automatic pagination.

### Validation & Edge Cases

- The dialog can be opened even if the trip data is still loading; all form content is shown
  immediately and the transit list shows a progress indicator until ready.
- If the trip is not the currently active trip (opened from the Trips List), it is loaded in the
  background without disrupting the current active trip.
- Empty sections (no stays, no transits, etc.) are omitted from the PDF.
- Large trips paginate automatically.
- If PDF generation fails, an error message is shown.
