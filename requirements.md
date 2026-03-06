# Wandrr — Product Requirements Specification

> **Version:** 1.0  
> **Last Updated:** 2026-03-06  
> **Status:** Active

---

## Table of Contents

1. [Overview](#1-overview)
2. [Glossary](#2-glossary)
3. [Platform & Layout Modes](#3-platform--layout-modes)
4. [Module: Onboarding & Language Selection](#4-module-onboarding--language-selection)
5. [Module: Authentication](#5-module-authentication)
6. [Module: App-Level Settings (Theme / Language / Logout)](#6-module-app-level-settings-theme--language--logout)
7. [Module: Trip List (Home Page)](#7-module-trip-list-home-page)
8. [Module: Create Trip](#8-module-create-trip)
9. [Module: Copy Trip](#9-module-copy-trip)
10. [Module: Delete Trip](#10-module-delete-trip)
11. [Module: Trip Editor — Overview & Navigation](#11-module-trip-editor--overview--navigation)
12. [Module: Trip Details Editor (TripMetadata)](#12-module-trip-details-editor-tripmetadata)
13. [Module: Itinerary Timeline (Per-Day View)](#13-module-itinerary-timeline-per-day-view)
14. [Module: Stay (Lodging) Editor](#14-module-stay-lodging-editor)
15. [Module: Transit Editor (Single Leg)](#15-module-transit-editor-single-leg)
16. [Module: Multi-Leg Journey Editor](#16-module-multi-leg-journey-editor)
17. [Module: Itinerary Plan Data Editor (Sights / Notes / Checklists)](#17-module-itinerary-plan-data-editor-sights--notes--checklists)
18. [Module: Standalone Expense Editor](#18-module-standalone-expense-editor)
19. [Module: Expense Split & Payment Details (Shared Component)](#19-module-expense-split--payment-details-shared-component)
20. [Module: Budgeting — Expenses List, Debt Summary, Breakdown](#20-module-budgeting--expenses-list-debt-summary-breakdown)
21. [Module: Conflict Detection & Resolution](#21-module-conflict-detection--resolution)
22. [Module: Trip Entity Update Plan (Batch Commit)](#22-module-trip-entity-update-plan-batch-commit)
23. [Validation Rules Reference](#23-validation-rules-reference)
24. [Mobile vs Tablet/Web Layout Differences](#24-mobile-vs-tabletweb-layout-differences)
25. [Internationalization (i18n)](#25-internationalization-i18n)
26. [Real-Time Sync & Data Subscriptions](#26-real-time-sync--data-subscriptions)
27. [App Update Mechanism](#27-app-update-mechanism)
28. [Test Traceability](#28-test-traceability)

---

## 1. Overview

Wandrr is a cross-platform travel planning app (Android, iOS, Web) that lets users:

- Create and manage multi-day trips.
- Build per-day itineraries with stays, transit legs, sights, notes, and checklists.
- Track expenses with multi-contributor split and debt settlement.
- Collaborate on trips with multiple contributors.
- Detect and resolve timeline conflicts when dates, times, or contributors change.

**Architecture:** Flutter + BLoC + Firebase (Firestore + Auth + Remote Config).  
**Supported Locales:** English (`en`), Hindi (`hi`), Tamil (`ta`).

---

## 2. Glossary

| Term                     | Definition                                                                                                            |
|--------------------------|-----------------------------------------------------------------------------------------------------------------------|
| **TripMetadata**         | Top-level entity: name, date range, contributors, budget, thumbnail.                                                  |
| **Stay (Lodging)**       | A lodging entry with check-in/out dates, location, confirmation ID, expense, and notes.                               |
| **Transit**              | A single movement leg: mode, departure/arrival location + datetime, operator, expense.                                |
| **Journey**              | A group of Transit legs sharing the same `journeyId`, displayed as connected segments.                                |
| **Itinerary**            | The per-day view of a trip, containing linked Stays, Transits, and ItineraryPlanData.                                 |
| **ItineraryPlanData**    | User-editable content for a day: sights, notes, and checklists.                                                       |
| **Sight**                | A named attraction/visit with optional location, visit time, description, and expense.                                |
| **CheckList**            | A titled list of checkable items for a day.                                                                           |
| **StandaloneExpense**    | An expense not linked to a Stay/Transit/Sight; has title, category, date, and split data.                             |
| **ExpenseFacade**        | Shared expense data: currency, paidBy map, splitBy list, total computed from paidBy.                                  |
| **Contributor**          | A user (identified by username/email) who participates in a trip.                                                     |
| **Conflict**             | A temporal overlap or out-of-bounds condition detected when a user edits dates/times.                                 |
| **Clamping**             | Auto-adjusting an entity's times to fit within a new boundary (e.g., trip dates shrink).                              |
| **TripEntityUpdatePlan** | A pre-computed batch of changes (stay/transit/sight/expense) produced by conflict detection and committed atomically. |
| **Mobile Layout**        | Narrow single-column layout (`width ≤ 1000px`).                                                                       |
| **Tablet/Web Layout**    | Wide layout (`width > 1000px`) with split panes.                                                                      |

---

## 3. Platform & Layout Modes

### REQ-LAYOUT-001 — Layout Breakpoint

- The app determines `isBigLayout = true` when the available width > 1000 logical pixels, `false`
  otherwise.

### REQ-LAYOUT-002 — Adaptive Rendering

- Every screen must render correctly in both layout modes.
- Layout mode is stored in `AppDataFacade.isBigLayout` and is updated on every resize/rebuild of the
  root startup page.

### REQ-LAYOUT-003 — Startup Page Layout

- **Mobile:** Shows either the Onboarding page or the Login page (never both simultaneously);
  navigated sequentially.
- **Tablet/Web:** Shows Onboarding on the left half and Login on the right half side-by-side.

---

## 4. Module: Onboarding & Language Selection

### REQ-ONB-001 — Onboarding Page Content

- Displays a full-bleed background image (onboarding image).
- Overlays a language selector on the right side.
- On **mobile**, also shows a large "Next" FAB to navigate to the Login page.
- On **tablet/web**, the "Next" FAB is hidden (Login page is already visible alongside).

### REQ-ONB-002 — Language Selector (Onboarding)

- Shows a translate icon FAB that toggles an expandable list of available languages.
- Each language entry displays its flag asset and name.
- Tapping a language dispatches `ChangeLanguage` and the entire app re-renders in the selected
  locale.

### REQ-ONB-003 — Supported Languages

- English (`en`), Hindi (`hi`), Tamil (`ta`).
- Each language has a `LanguageMetadata` with flag asset path, locale code, and display name.

---

## 5. Module: Authentication

### REQ-AUTH-001 — Login / Register Tabs

- The Login page shows two tabs: **Login** and **Register**.
- Switching tabs does not clear the form fields.

### REQ-AUTH-002 — Email/Password Form

- **Username field:** Validates as a non-empty valid email.
- **Password field:** Obscured text; validates as non-empty.
- Pressing submit dispatches `AuthenticateWithUsernamePassword` with the current tab determining
  `shouldRegister`.

### REQ-AUTH-003 — Submit Button State

- The submit FAB is disabled while an authentication request is in-flight (
  `AuthStatus.authenticating`).
- Re-enabled on any terminal auth state.

### REQ-AUTH-004 — Third-Party Authentication

- A Google sign-in button is displayed below the form.
- Tapping it dispatches `AuthenticateWithThirdParty(AuthenticationType.google)`.
- Disabled during in-flight authentication.

### REQ-AUTH-005 — Authentication Outcomes

| AuthStatus              | UI Behaviour                                                            |
|-------------------------|-------------------------------------------------------------------------|
| `loggedIn`              | Navigate to the trips list page.                                        |
| `verificationPending`   | Show inline message: email verification required. Show "Resend" option. |
| `verificationResent`    | Show inline confirmation that a verification email was re-sent.         |
| `wrongPassword`         | Show error inline or via snackbar.                                      |
| `noSuchUsernameExists`  | Show error inline.                                                      |
| `usernameAlreadyExists` | Show error inline (Register tab).                                       |
| `weakPassword`          | Show error inline (Register tab).                                       |
| `invalidEmail`          | Show error inline.                                                      |

### REQ-AUTH-006 — Resend Verification Email

- Visible only when status is `verificationPending` or `verificationResent`.
- Dispatches `ResendEmailVerification` with current username/password.

### REQ-AUTH-007 — Session Persistence

- If a user is already authenticated at app start, the root route redirects directly to `/trips`
  without showing login.

### REQ-AUTH-008 — Route Protection

- Unauthenticated users attempting to access `/trips` or `/trips/:tripId` are redirected to `/`.
- Authenticated users attempting to access `/login` or `/onboarding` are redirected to `/trips`.

---

## 6. Module: App-Level Settings (Theme / Language / Logout)

### REQ-SET-001 — Settings Access

- On the Home page app bar, a **settings gear icon** opens a popup menu.

### REQ-SET-002 — Theme Switcher

- Shows a toggle switch labelled with the localized "Dark Theme" text.
- Toggling dispatches `ChangeTheme(ThemeMode.dark)` or `ChangeTheme(ThemeMode.light)`.
- Theme change is persisted across app restarts.

### REQ-SET-003 — Language Switcher (Home Toolbar)

- Shows a submenu of supported languages (same set as onboarding).
- Selecting a language dispatches `ChangeLanguage` and the entire app re-renders.
- Language preference is persisted across app restarts.

### REQ-SET-004 — Logout

- Dispatches `Logout`.
- On success (`AuthStatus.loggedOut`), the router redirects to the root route.

---

## 7. Module: Trip List (Home Page)

### REQ-TL-001 — Trip List Display

- Shows all trips belonging to or shared with the current user.
- Trips are grouped into two sections: **Upcoming Trips** (end date ≥ today) and **Past Trips** (end
  date < today).
- Each section has year filter chips derived from trip start dates.
- Only trips matching the selected year chip are displayed in each section.

### REQ-TL-002 — Trip Card Content

- Each trip is shown as a grid card containing:
    - Trip thumbnail image (based on `thumbnailTag`).
    - Trip name.
    - Date range (formatted with month and day).
    - Contributor count badge.
    - Budget display (formatted currency amount).

### REQ-TL-003 — Trip Card Grid

- Displayed as a `SliverGrid` with `maxCrossAxisExtent: 300` and `childAspectRatio: 0.75`.
- Adapts to screen width: more columns on wider screens.

### REQ-TL-004 — Trip Card Actions

- Each card has a popup menu with:
    - **Copy Trip** — opens the Copy Trip dialog.
    - **Delete Trip** — opens the Delete Trip confirmation dialog.

### REQ-TL-005 — Opening a Trip

- Tapping a trip card dispatches `LoadTrip` and navigates to `/trips/:tripId`.
- While loading, a `LoadingTrip` state is emitted with the trip metadata (can be used for a loading
  indicator).

### REQ-TL-006 — Empty State

- When no trips exist, a localized "No trips created" message is shown centered.

### REQ-TL-007 — Rebuild Rules

- The trip list rebuilds only when a `TripMetadataFacade` is created or deleted (not on updates) to
  avoid unnecessary rebuilds.

### REQ-TL-008 — FAB: Create Trip

- A centered FAB labelled with localized "Plan a Trip" and a location icon is shown.
- Hidden when the soft keyboard is open.
- Tapping opens the Create Trip dialog.

---

## 8. Module: Create Trip

### REQ-CT-001 — Create Trip Dialog Content

- Shows (in order):
    1. **Thumbnail picker:** Horizontal carousel of predefined trip thumbnail images. User selects
       one.
    2. **Date range picker:** Selects start and end date. Earliest selectable date is today.
    3. **Trip name text field:** Free text. Required.
    4. **Budget editor:** Amount field + currency dropdown. Defaults to `INR`.

### REQ-CT-002 — Validation (Create)

- The submit button is enabled only when `TripMetadataFacade.validate()` passes:
    - `name` is non-empty.
    - Both `startDate` and `endDate` are set.
    - `endDate >= startDate`.

### REQ-CT-003 — Submit Behaviour

- Sets the current user as the sole contributor.
- Dispatches `UpdateTripEntity<TripMetadataFacade>.create(...)`.
- Closes the dialog.

### REQ-CT-004 — Default Values

- Currency: `INR`.
- Thumbnail: `roadTrip` asset.
- Budget amount: `0`.
- Contributors: `[currentUser.userName]`.

---

## 9. Module: Copy Trip

### REQ-CP-001 — Copy Trip Dialog Content

- Shows:
    1. **Trip name field:** Pre-filled with `"Copy of <original name>"`. Validated as non-empty.
    2. **Start date picker:** Defaults to today. Selecting a new start date auto-computes end date
       preserving original duration.
    3. **Date shift info:** Read-only text showing original date range → new date range.
    4. **Contributors editor:** Pre-filled from source trip. Supports add/remove.
    5. **Budget editor:** Pre-filled from source trip. Editable amount and currency.

### REQ-CP-002 — Validation (Copy)

- Form validation: name must be non-empty (trimmed).
- Start date must be selectable from today up to 10 years ahead.

### REQ-CP-003 — Submit Behaviour

- Dispatches `CopyTrip` event with all edited fields.
- The backend (`TripCopyService`) creates a new trip in Firestore, copying all entities with
  date-shifted values.
- On success, emits `UpdatedTripEntity<TripMetadataFacade>.created`.
- On failure, emits the same state with `isOperationSuccess: false`.

---

## 10. Module: Delete Trip

### REQ-DT-001 — Delete Trip Dialog Content

- Shows a warning icon and localized confirmation text.
- Two buttons: **No** (dismisses dialog) and **Yes** (proceeds with deletion, styled as
  destructive).

### REQ-DT-002 — Delete Behaviour

- Dispatches `UpdateTripEntity<TripMetadataFacade>.delete(...)`.
- The backend deletes the trip and all subcollections from Firestore.
- Dialog closes. The trip disappears from the list on next rebuild.

---

## 11. Module: Trip Editor — Overview & Navigation

### REQ-TE-001 — Trip Editor Sections

- **Mobile:** Two sections accessible via a bottom navigation bar:
    1. **Itinerary** (timeline per day).
    2. **Budgeting** (expenses, debt, breakdown).
- **Tablet/Web:** Both sections displayed side-by-side in a `Row` with `Expanded` children. No
  bottom nav bar.

### REQ-TE-002 — App Bar

- Shows trip name (or loading indicator) and action buttons.
- Contains a settings/edit button to open the Trip Details editor.

### REQ-TE-003 — FAB: Add Entity

- A centered add (+) FAB.
- Tapping opens a bottom sheet (mobile) or dialog showing entity creation options:
    - Stay, Travel, Expense (plus Transit mode sub-selection for Travel).

### REQ-TE-004 — Entity Editor Presentation

- **Mobile:** Entity editors open as a modal bottom sheet (draggable, full-height capable).
- **Tablet/Web:** Same bottom sheet, but the editor may use wider layouts internally.

### REQ-TE-005 — Entity Editor Modes

- **Create:** When an entity has no `id` or is flagged `DataState.newUiEntry`. A blank form is
  shown.
- **Edit:** When an entity has an `id`. The form is pre-populated with current values.

### REQ-TE-006 — Editor View Switching

- Editors that support conflict detection show a two-page `PageView`:
    - **Page 0:** Entity editor form.
    - **Page 1:** Conflict resolution subpage.
- Navigation between pages is programmatic (not swipeable).

---

## 12. Module: Trip Details Editor (TripMetadata)

### REQ-TD-001 — Displayed Fields

- **Trip title:** Editable text field. Bold, large typography.
- **Date range:** Start and end date pickers. Constrained to valid range.
- **Budget:** Amount + currency dropdown.
- **Contributors ("Trip Mates"):** List of contributor username chips with add/remove capability.

### REQ-TD-002 — Title Validation

- Name must be non-empty after trimming.

### REQ-TD-003 — Date Range Change → Conflict Detection

- Changing the date range dispatches `UpdateEntityTimeRange<TripMetadataFacade>` to the
  `TripEntityEditorBloc`.
- The bloc scans all existing stays, transits, and sights for entities that fall outside the new
  date range.
- If conflicts are found, a conflict banner appears and the FAB is disabled until conflicts are
  resolved or acknowledged.

### REQ-TD-004 — Contributor Changes → Expense Split Detection

- Adding or removing a contributor triggers detection of all `ExpenseBearingTripEntity` items.
- These are shown as `ExpenseSplitChange` entries in the update plan.
- The user can opt-in/opt-out each expense from including the new contributor in its `splitBy` list.
- Tri-state checkbox: all selected / none selected / mixed.

### REQ-TD-005 — Contributor Add Flow

- An "Add" button reveals a text field.
- User types a username. The system validates that the username exists (`doesUserNameExist`).
- If the username does not exist, an error is shown.
- If valid, the contributor is added to the local list immediately and `onContributorsChanged`
  fires.
- The current user cannot be removed from the contributors list.

### REQ-TD-006 — Submit

- Dispatches the updated `TripMetadataFacade`.
- If a conflict plan exists and is confirmed, dispatches `ApplyTripDataUpdatePlan` for atomic batch
  writes.

### REQ-TD-007 — Removed Contributor Notification

- After a successful update that removed contributors, a snackbar is shown:  
  *"Past expenses with removed tripmates are preserved for historical accuracy."*

---

## 13. Module: Itinerary Timeline (Per-Day View)

### REQ-IT-001 — Day Navigation

- The itinerary navigator shows the current day with left/right arrow buttons to move between trip
  days.
- A calendar icon opens a date picker allowing direct jump to any trip day.
- Day transitions animate with fade + slide.

### REQ-IT-002 — Day View Tabs

- Each day view has **4 tabs**:
    1. **Timeline** — Chronological list of all events for the day.
    2. **Notes** — Viewer for day notes.
    3. **Checklists** — Viewer for day checklists.
    4. **Sights** — Viewer for day sights.

### REQ-IT-003 — Timeline Events

- For each day, the timeline aggregates:
    - **Check-in lodging:** A Stay whose check-in date falls on this day.
    - **Check-out lodging:** A Stay whose check-out date falls on this day.
    - **Full-day lodging:** A Stay that spans across this day (check-in before, check-out after).
    - **Transits:** All transit legs whose departure date falls on this day.
    - **Sights:** All sights for this day (from ItineraryPlanData).
- Events are sorted chronologically by their time.

### REQ-IT-004 — Timeline Event Card Content

- Each event card shows:
    - Type-specific icon and colour.
    - Time (formatted).
    - Title (descriptive, e.g., "Stay at Hotel X from Jan 5 to Jan 7").
    - Subtitle (contextual detail, e.g., location name).
    - Notes preview (if any).
    - Confirmation ID badge (if any).
- Tapping an event opens its editor (dispatches `UpdateTripEntity.select`).
- Swipe-to-delete dispatches `UpdateTripEntity.delete`.

### REQ-IT-005 — Connected Journey Display

- Transit legs sharing a `journeyId` are rendered as connected segments.
- Each leg shows its position: start / middle / end / standalone.
- Layover duration is displayed between connected legs.
- Tapping any leg in a journey opens the full Journey Editor for that journey.

### REQ-IT-006 — Timeline Rebuild Rules

- The timeline rebuilds when any entity (transit, lodging, expense, itinerary plan data) relevant to
  the displayed day is created, updated, or deleted.

---

## 14. Module: Stay (Lodging) Editor

### REQ-ST-001 — Displayed Fields

1. **Location:** Geo-location autocomplete search. Required.
2. **Check-in / Check-out date-times:** Date-time pickers constrained within trip date range.
   Required. Check-out must be after check-in.
3. **Confirmation ID:** Optional text field.
4. **Notes:** Optional expandable text area.
5. **Payment Details (Expense):** Shared expense editing component (
   see [Module 19](#19-module-expense-split--payment-details-shared-component)).

### REQ-ST-002 — Validation

- `location` must be set (non-null).
- `checkinDateTime` must be set (non-null).
- `checkoutDateTime` must be set (non-null).
- `expense.validate()` must pass (paidBy and splitBy non-empty).
- Check-out must be ≥ check-in (implicitly enforced by the date picker UX, but validated in model).

### REQ-ST-003 — Conflict Detection on Date Change

- Changing check-in or check-out dispatches `UpdateEntityTimeRange<LodgingFacade>`.
- The `TripEntityEditorBloc` scans for:
    - Other stays overlapping with the new stay range.
    - Transits overlapping with the new stay range.
    - Sights overlapping with the new stay range.
- **Stay-specific conflict rule:** Transits and sights that are *fully contained* within a stay do
  NOT conflict (a transit can happen during a stay). Only overlaps at boundaries or containment of
  the stay within a transit are conflicts.

### REQ-ST-004 — Entity Display Name

- Format: `"Stay at <location> from <month day> to <month day>"`.
- Falls back to `"Unnamed Entry"` if location or dates are incomplete.

---

## 15. Module: Transit Editor (Single Leg)

### REQ-TR-001 — Displayed Fields

1. **Transit type badge:** Dropdown picker showing all `TransitOption` values (bus, flight,
   rentedVehicle, train, walk, ferry, cruise, vehicle, publicTransport, taxi), each with an icon.
2. **Operator section (conditional):** Shown only for types that need prior booking (all except
   `walk` and `vehicle`).
    - For **flight:** A specialized airline + flight number editor section.
      See [REQ-TR-005](#req-tr-005).
    - For **other bookable types:** A simple text field for operator name.
3. **Departure:** Location autocomplete + date-time picker. For flights, airport-specific search.
4. **Arrival:** Location autocomplete + date-time picker. For flights, airport-specific search.
5. **Confirmation ID (conditional):** Shown only for bookable types. Optional.
6. **Notes:** Optional expandable text area.
7. **Payment Details (Expense):** Shared expense editing component.

### REQ-TR-002 — Validation

- `departureLocation` must be set.
- `arrivalLocation` must be set.
- `departureDateTime` must be set.
- `arrivalDateTime` must be set.
- `arrivalDateTime > departureDateTime` (strictly).
- For flight: `operator` must contain at least 3 space-separated non-empty tokens (e.g.,
  `"Airline Code 1234"`).
- `expense.validate()` must pass.

### REQ-TR-003 — Transit Type Change

- Changing the transit type may toggle visibility of operator/confirmation sections.
- If switching from flight to non-flight, the operator and location fields may reset.

### REQ-TR-004 — Entity Display Name

- Format: `"<departure> to <arrival> on <month day>"`.
- Falls back to `"Unnamed Entry"`.

### REQ-TR-005 — Flight Operator Validation

- The operator field for flights must contain `≥ 3` space-separated non-empty tokens.
- Example valid: `"IndiGo 6E 2341"`.
- Example invalid: `"IndiGo"`, `""`, `"IndiGo "`.

### REQ-TR-006 — Smart Timezone Display

- When both departure and arrival locations are set, a single timezone indicator is shown.
- If both locations share the same timezone, only one timezone string is displayed.
- If both locations are in different timezones but the same region (e.g., Europe/Berlin and
  Europe/Amsterdam), the region is shown once with both cities: "Europe: Berlin → Amsterdam".
- If the locations are in different regions, both full timezone strings are shown: "America/New
  York → Europe/London".

---

## 16. Module: Multi-Leg Journey Editor

### REQ-JE-001 — Journey Initialization

- If the initial transit has a `journeyId`, all legs sharing that ID are loaded and cloned for
  editing.
- If no `journeyId`, the editor starts with a single standalone leg.
- Legs are sorted by departure time ascending.

### REQ-JE-002 — Journey Display

- Each leg is shown in a collapsible expansion panel.
- The clicked/initial leg is expanded by default.
- A journey overview header shows the overall departure → arrival with layover summary.

### REQ-JE-003 — Add / Remove Legs

- An "Add Connecting Leg" button appends a new empty leg.
- New legs inherit the `journeyId`, `tripId`, transit type, and the previous leg's arrival location
  as departure.
- Each leg (except the first) can be removed.

### REQ-JE-004 — Leg Connectivity Constraint

- Each subsequent leg's minimum departure date-time is constrained to the previous leg's arrival
  time.
- The editor passes `minDepartureDateTime` to each leg's `TravelEditor`.

### REQ-JE-005 — Journey-Level Validation

- All individual legs must be valid.
- Each leg's arrival must be ≥ 1 minute after its departure.
- Each connecting leg's departure must be ≥ the previous leg's arrival.

### REQ-JE-006 — Journey-Level Conflict Detection

- Dispatches `UpdateJourneyTimeRange(legs)` when any leg's time changes.
- The bloc aggregates conflicts across all legs and deduplicates by entity ID.

### REQ-JE-007 — Save Behaviour

- On submit, all legs are saved individually:
    - New legs (no ID) → `create`.
    - Existing legs → `update`.

### REQ-JE-008 — Layover Display

- Between consecutive legs, the layover duration is computed and displayed.

---

## 17. Module: Itinerary Plan Data Editor (Sights / Notes / Checklists)

### REQ-IPD-001 — Entry Modes

- **Create New Component:** Opens the editor with a new item already appended (sight, note, or
  checklist). The new item is created for the date currently displayed in the itinerary viewer.
- **Update Existing Component:** Opens the editor scrolled/focused to the component at the specified
  index.

### REQ-IPD-002 — Tabs

- Three tabs: **Sights**, **Notes**, **Checklists**.
- Initial tab is determined by `ItineraryPlanDataEditorConfig.planDataType`.

### REQ-IPD-003 — Sights Tab

- List of sight entries, each with:
    - **Name:** Required, minimum 3 characters.
    - **Location:** Optional geo-location autocomplete.
    - **Visit time:** Optional date-time picker.
    - **Description:** Optional text.
    - **Expense:** Optional payment details.
- Add button appends a new blank sight.
- Remove button deletes a sight.

### REQ-IPD-004 — Sight Overlap Detection

- When any sight's visit time changes, dispatches `UpdateSightsTimeRange(sights)`.
- If two sights on the same day have the same visit time, an error is emitted:
  `"Sights cannot overlap on the same day"`.
- Additionally, standard conflict detection runs against transits and stays.

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

- `ItineraryPlanData.validate()` returns `true` if:
    - No content at all (`noContent`) — valid (empty plan data is acceptable).
    - All sights pass `sight.validate()`.
    - All notes are non-empty.
    - All checklist titles are ≥ 3 chars and all items are non-empty.
- Specific validation results:
    - `sightInvalid`: A sight has name empty or < 3 chars.
    - `noteEmpty`: A note text is empty.
    - `checkListTitleNotValid`: A checklist title is null or < 3 chars.
    - `checkListItemEmpty`: A checklist has no items or contains empty items.

### REQ-IPD-008 — Submit

- Dispatches `UpdateTripEntity<ItineraryPlanData>.update(...)`.
- The itinerary model is updated via `updatePlanData`.

---

## 18. Module: Standalone Expense Editor

### REQ-SE-001 — Displayed Fields

1. **Category badge:** Shows the expense category (from `ExpenseCategory` enum) with icon and
   colour.
2. **Title:** Editable text field.
3. **Paid-On date:** Date picker.
4. **Description:** Optional text field.
5. **Payment Details (Expense):** Shared expense editing component.

### REQ-SE-002 — Layout Adaptation

- **Mobile:** Fields stacked vertically.
- **Tablet/Web:** Date/description on the left column; payment details on the right column.

### REQ-SE-003 — Validation

- `expense.validate()` must pass (paidBy and splitBy non-empty).

### REQ-SE-004 — Category List

- `other`, `flights`, `lodging`, `carRental`, `publicTransit`, `food`, `drinks`, `sightseeing`,
  `activities`, `shopping`, `fuel`, `groceries`, `taxi`.

---

## 19. Module: Expense Split & Payment Details (Shared Component)

### REQ-EX-001 — Component Structure

- Two tabs: **Paid By** and **Split By**.
- A currency selector + total amount display at the top.

### REQ-EX-002 — Paid By Tab

- Shows all trip contributors.
- Each contributor has an amount field (how much they paid).
- Total expense is computed as the sum of all paidBy amounts.

### REQ-EX-003 — Split By Tab

- Shows all trip contributors with checkboxes.
- Checked contributors are included in the expense split.
- At least one contributor must be checked.

### REQ-EX-004 — Currency Selector

- Dropdown of all supported currencies (loaded from `supported_currencies.json`).
- Each currency shows: code, name, symbol.
- Changing currency updates `expense.currency`.

### REQ-EX-005 — Validation

- `paidBy.isNotEmpty` and `splitBy.isNotEmpty`.

### REQ-EX-006 — Callback

- On any change, invokes the parent callback with updated `paidBy`, `splitBy`, and computed
  `totalExpense`.

---

## 20. Module: Budgeting — Expenses List, Debt Summary, Breakdown

The budgeting service is available across the entire trip editor, including in dialogs and bottom
sheets. When the trip's currency is updated, the service reflects the change automatically.

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
- Tapping opens the Expense Editor (for standalone) or the parent entity editor.
- Swipe to delete.

### REQ-BU-004 — Debt Summary

- Shows each debt as: "[person] needs to pay [person] [amount]".
- Contributors are shown as badges; the current user is labelled "You".
- If no expenses or total expenditure is 0, shows "No expenses to split".

### REQ-BU-005 — Budget Breakdown

- **By Category:** Pie chart of total spending per expense category.
- **By Day:** Bar chart of total spending per trip day.

### REQ-BU-006 — Expense List Rebuild Rules

- Updates when expenses are added, changed, or removed.

---

## 21. Module: Conflict Detection & Resolution

### REQ-CD-001 — Conflict Triggers

- Conflicts are detected when:
    - TripMetadata date range changes.
    - TripMetadata contributors change.
    - Stay check-in/out times change.
    - Transit departure/arrival times change (single or journey).
    - Sight visit times change.

### REQ-CD-002 — Conflict Types

| Conflict Type                 | Entities Affected                                                     | Detection Logic                                                                       |
|-------------------------------|-----------------------------------------------------------------------|---------------------------------------------------------------------------------------|
| **Date out-of-bounds**        | Stays, Transits, Sights                                               | Entity's time range falls partially or fully outside the new trip date range.         |
| **Temporal overlap**          | Stays vs Stays, Transits vs Transits/Stays/Sights, Sights vs Transits | Two entities' time ranges overlap in a way that is not allowed by the conflict rules. |
| **Intra-day sight overlap**   | Sight vs Sight                                                        | Two sights on the same day have identical visit times.                                |
| **Contributor expense split** | All ExpenseBearing entities                                           | Contributors added/removed from trip; expenses may need split updates.                |

### REQ-CD-003 — Conflict Position Classification

- `EntityTimelinePosition` enum:
    - `exactBoundaryMatch`: A boundary of one entity exactly matches a boundary of the other.
    - `beforeEvent`: Entity is entirely before the reference range.
    - `afterEvent`: Entity is entirely after the reference range.
    - `containedIn`: Entity is fully within the reference range.
    - `contains`: Reference range is fully within the entity.
    - `startsBeforeEndsDuring`: Entity starts before and ends during the reference range.
    - `startsDuringEndsAfter`: Entity starts during and ends after the reference range.
    - `isOverlapping`: Generic overlap (used for same-type intra-day).

### REQ-CD-004 — Conflict Rules by Source Entity Type

- **TripMetadata (date change):** Conflicts with `beforeEvent`, `afterEvent`,
  `startsBeforeEndsDuring`, `startsDuringEndsAfter`, `contains`.
- **Stay (editing):** Transits/Sights fully *contained in* the stay are NOT conflicts. Other
  overlaps are conflicts.
- **Transit / Sight (standard):** All boundary matches, containments, and partial overlaps are
  conflicts.

### REQ-CD-005 — Clamping (Auto-Resolution)

- For positions `startsBeforeEndsDuring` and `startsDuringEndsAfter`, the system attempts to **clamp
  ** the conflicting entity's times:
    - **Transit:** Adjusts departure or arrival by ±1 minute from the conflict boundary. Returns
      null (cannot clamp) if the remaining range is too small.
    - **Stay:** Adjusts check-in or check-out to the nearest half-hour boundary. Returns null if no
      valid range remains.
    - **Sight:** Only clampable for `exactBoundaryMatch` by shifting ±1 minute. Non-boundary
      overlaps cannot be clamped.
- For `exactBoundaryMatch`:
    - **Transit:** Shifts departure/arrival by +1 minute from the matching boundary.
    - **Stay:** Shifts check-in/out to next/previous half-hour.
    - **Sight:** Shifts visit time by ±1 minute.
- For `containedIn` or `contains`, clamping is not possible → entity is marked for deletion.

### REQ-CD-006 — Conflict Resolution UI

- When conflicts are detected:
    - A **sticky conflict banner** appears above the editor form showing the conflict count and a "
      View Conflicts" button.
    - The **FAB is disabled** until conflicts are acknowledged.
- The conflict resolution subpage shows:
    - A header with a back button.
    - A status bar with conflict summary.
    - Sections for Stays, Transits, and Sights (each section rebuilds independently based on its
      count).
    - Each conflicted entity shows:
        - Original vs. modified (clamped) times.
        - Source of conflict (what entity caused it).
        - A **delete/restore toggle** button.
        - For clamped entities: editable time fields to manually adjust.
    - A **Confirm** button to acknowledge the plan.

### REQ-CD-007 — Conflict Confirmation

- Pressing Confirm dispatches `ConfirmConflictPlan`.
- The plan is marked as confirmed, the banner hides, and the FAB is re-enabled.
- The actual changes are committed when the user presses the FAB (submit).

### REQ-CD-008 — Inter-Conflict Detection

- When a user edits the time of a *conflicted* entity (on the resolution page), the system checks:
    1. Does the new time conflict with the *editable entity itself*? → Error, revert.
    2. Does the new time conflict with *other existing entities in the trip*? → Add new conflicts to
       the plan.
- New conflicts are added to the plan in-place and appropriate UI updates emitted.

### REQ-CD-009 — Expense Deletion Sync

- When a timeline entity is marked for deletion in the conflict plan, its corresponding
  `ExpenseSplitChange` (if any) is also marked for deletion.
- When restored, the expense change is also restored.

### REQ-CD-010 — Localized UI Rebuilds (Performance)

- State emissions are tiered:
    - `ConflictsAdded` → full conflict UI appears.
    - `ConflictsUpdated` → section-level rebuild (section counts may have changed).
    - `ConflictItemUpdated` → single-item rebuild (only the specific entity re-renders).
    - `ConflictsRemoved` → conflict UI hides entirely.

### REQ-CD-011 — Scan Exclusions

- When scanning for conflicts, the entity being edited (or all legs of a journey, or all sights of
  an itinerary) is excluded from detection to avoid self-conflicts.
- For new entities (no ID yet), no exclusions are applied since there is nothing to exclude.

---

## 22. Module: Trip Entity Update Plan (Batch Commit)

### REQ-UP-001 — Plan Structure

- A `TripEntityUpdatePlan<T>` holds:
    - `oldEntity` and `newEntity`.
    - Lists of `StayChange`, `TransitChange`, `SightChange`, `ExpenseSplitChange`.
    - `tripStartDate` and `tripEndDate`.
    - Confirmation state (`isConfirmed`).

### REQ-UP-002 — Commit Order

1. Update currency (if changed).
2. Process entity date/time changes: update modified entities, delete marked entities.
3. Update itinerary days (add/remove days for new date range).
4. Recalculate total expenditure.

### REQ-UP-003 — Atomic Writes

- All changes in a plan are committed in a single Firestore `WriteBatch` to ensure atomicity.

### REQ-UP-004 — Expense Selection in Plan

- For contributor changes, the plan exposes tri-state selection:
    - All expenses selected for split update.
    - No expenses selected.
    - Mixed selection.
- `selectAllExpenses()` / `deselectAllExpenses()` / `toggleExpenseSelection()`.

### REQ-UP-005 — Plan Mutation

- `updateConflicts()` replaces conflict lists in-place and resets confirmation.
- `syncExpenseDeletionState()` syncs expense entry when its parent entity is toggled.

---

## 23. Validation Rules Reference

| Entity                | Rule                                                                                                                                                                                            | Error Condition                                                    |
|-----------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------|
| **TripMetadata**      | `name.isNotEmpty && endDate ≥ startDate && both dates non-null`                                                                                                                                 | Missing name or invalid date range.                                |
| **Lodging**           | `location ≠ null && checkinDateTime ≠ null && checkoutDateTime ≠ null && expense.validate()`                                                                                                    | Missing location or dates or invalid expense.                      |
| **Transit**           | `departureLocation ≠ null && arrivalLocation ≠ null && departureDateTime ≠ null && arrivalDateTime ≠ null && arrival > departure && (if flight: operator has ≥ 3 tokens) && expense.validate()` | Missing locations/times, arrival ≤ departure, bad flight operator. |
| **TransitJourney**    | `all legs valid && each leg arrival ≥ departure + 1 min && each connecting departure ≥ prev arrival`                                                                                            | Invalid leg, time sequence error.                                  |
| **Sight**             | `name.isNotEmpty && name.length ≥ 3`                                                                                                                                                            | Name too short or empty.                                           |
| **CheckList**         | `title ≠ null && title.isNotEmpty && items.isNotEmpty && all items non-empty`                                                                                                                   | Missing title or empty items.                                      |
| **ItineraryPlanData** | `(noContent is valid) OR (all sights valid && all notes non-empty && all checklists valid)`                                                                                                     | See `ItineraryPlanDataValidationResult` enum values.               |
| **ExpenseFacade**     | `paidBy.isNotEmpty && splitBy.isNotEmpty`                                                                                                                                                       | No payers or no splitters.                                         |
| **StandaloneExpense** | `expense.validate()`                                                                                                                                                                            | Invalid expense data.                                              |

---

## 24. Mobile vs Tablet/Web Layout Differences

| Area                               | Mobile (≤ 1000px)                              | Tablet/Web (> 1000px)                                            |
|------------------------------------|------------------------------------------------|------------------------------------------------------------------|
| **Startup**                        | Onboarding → Login (sequential screens)        | Onboarding (left) + Login (right) side-by-side                   |
| **Home App Bar**                   | Full width                                     | Half width (centered)                                            |
| **Trip List Grid**                 | Fewer columns (1-2 cards per row)              | More columns (3+ cards per row)                                  |
| **Trip Editor**                    | Bottom nav bar to switch Itinerary / Budgeting | Side-by-side split (Itinerary left, Budgeting right), no nav bar |
| **Trip Editor FAB**                | Docked to bottom nav bar                       | Floating at bottom center with padding                           |
| **Entity Editors**                 | Modal bottom sheet (full-screen capable)       | Same bottom sheet; editor internals may use row layouts          |
| **Expense Editor**                 | Single column layout                           | Two-column layout (details left, payment right)                  |
| **Language Switcher (Onboarding)** | Shows "Next" FAB alongside language buttons    | "Next" FAB hidden; login visible alongside                       |

---

## 25. Internationalization (i18n)

### REQ-I18N-001 — String Sources

- All user-facing strings are defined in ARB files: `app_en.arb`, `app_hi.arb`, `app_ta.arb`.
- Accessed via `AppLocalizations` (generated by `flutter_localizations`).

### REQ-I18N-002 — Runtime Language Switch

- Language can be switched at any time (onboarding or settings).
- The entire widget tree rebuilds with the new locale.
- Selected language persists in `SharedPreferences`.

### REQ-I18N-003 — Date/Time Formatting

- Custom date formatting via `DateTimeExtensions` (e.g., `monthFormat`, `dayDateMonthFormat`).
- Uses English month abbreviations regardless of locale.

---

## 26. Real-Time Sync & Data Subscriptions

### REQ-SYNC-001 — Firestore Collection Listeners

- On trip load, the app subscribes to:
    - Transit collection changes.
    - Lodging collection changes.
    - Standalone expense collection changes.
    - Itinerary plan data changes (per day).
    - Trip metadata collection changes (for trip list).

### REQ-SYNC-002 — Change Propagation

- Remote changes emit internal events (`_UpdateTripEntityInternalEvent`) that update BLoC state and
  trigger UI rebuilds.
- Each change is classified as `create`, `update`, or `delete`.
- Changes marked as `isFromExplicitAction: false` indicate remote/subscription-based updates.

### REQ-SYNC-003 — Subscription Lifecycle

- Subscriptions are created when a trip is loaded.
- Subscriptions are cleared when navigating back to home (`GoToHome` event) or loading a different
  trip.
- Itinerary subscriptions are re-created when trip dates change (since day documents may be
  added/removed).

---

## 27. App Update Mechanism

### REQ-UPD-001 — Remote Config

- On startup and periodically, the app fetches `latest_version`, `min_version`, and `release_notes`
  from Firebase Remote Config.

### REQ-UPD-002 — Update Detection

- Compares current build number with the latest build number.
- If an update is available: shows an `UpdateAvailable` dialog with version and release notes.
- If `min_version` build number ≥ current build number: the update is **forced** (non-dismissable).

---

## 28. Test Traceability

Each requirement ID (e.g., `REQ-AUTH-002`) should be referenced in test file names or doc comments
to enable traceability.

### Recommended Test Mapping

| Requirement Group         | BLoC Events to Test                                                                | UI Elements to Verify                                                     |
|---------------------------|------------------------------------------------------------------------------------|---------------------------------------------------------------------------|
| AUTH                      | `AuthenticateWithUsernamePassword`, `AuthenticateWithThirdParty`, `Logout`         | Login/register tabs, form validation, error messages, navigation          |
| SET                       | `ChangeTheme`, `ChangeLanguage`, `Logout`                                          | Theme toggle, language submenu, logout behaviour                          |
| TL (Trip List)            | `LoadedRepository`, `UpdatedTripEntity<TripMetadata>.create/delete`                | Grid cards, year chips, empty state, popup actions                        |
| CT (Create Trip)          | `UpdateTripEntity<TripMetadata>.create`                                            | Dialog fields, validation toggle, submit                                  |
| CP (Copy Trip)            | `CopyTrip`                                                                         | Pre-filled fields, date shift display, submit                             |
| DT (Delete Trip)          | `UpdateTripEntity<TripMetadata>.delete`                                            | Confirmation dialog, trip removal                                         |
| TD (Trip Details)         | `UpdateEntityTimeRange<TripMetadata>`, `ApplyTripDataUpdatePlan`                   | Fields, conflict banner, contributor chips                                |
| IT (Itinerary)            | Day navigation, tab switching                                                      | Timeline events, notes/checklists/sights viewers                          |
| ST (Stay)                 | `UpdateEntityTimeRange<Lodging>`, `UpdateTripEntity<Lodging>.create/update`        | Form fields, date pickers, conflict banner                                |
| TR (Transit)              | `UpdateJourneyTimeRange`, `UpdateTripEntity<Transit>.create/update`                | Transit type picker, operator field, flight validation                    |
| JE (Journey)              | `UpdateJourneyTimeRange`, multi-leg save                                           | Leg panels, add/remove, layover, connectivity constraint                  |
| IPD (Itinerary Plan Data) | `UpdateSightsTimeRange`, `UpdateTripEntity<ItineraryPlanData>.update`              | Sight/note/checklist CRUD, tab switching, validation errors               |
| SE (Standalone Expense)   | `UpdateTripEntity<StandaloneExpense>.create/update`                                | Category badge, title, date, expense split                                |
| EX (Expense Component)    | Expense callback invocation                                                        | PaidBy/SplitBy tabs, currency selector, total display                     |
| CD (Conflicts)            | `ConflictsAdded`, `ConflictsUpdated`, `ConflictItemUpdated`, `ConfirmConflictPlan` | Conflict banner, resolution page sections, clamped values, confirm button |
| BU (Budgeting)            | `sortExpenses`, `retrieveDebtDataList`, `retrieveTotalExpensePerCategory`          | Sort toggles, debt rows, breakdown charts, budget tile                    |
| SYNC                      | Subscription events, `_UpdateTripEntityInternalEvent`                              | Real-time UI updates on remote changes                                    |

