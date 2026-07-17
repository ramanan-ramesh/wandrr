# Development Guidelines

You are assisting in developing Wandrr, a cross-platform travel planning app built with Flutter. The
app enables users to create and manage trips, including accommodations, transit, daily itineraries,
expenses, and collaborative features like expense splitting and debt settlement. It supports
multi-user collaboration with real-time updates and conflict resolution for timeline entities.

## Core Architecture

* State Management: BLoC pattern.
* Clean Architecture Layers:
    * Data Layer: Define models (TripData/Stay/Expense) as immutable Dart classes with JSON
      serialization (toJson/fromJson). Use repositories for data access.
    * Domain Layer: Implement use cases in the services layer (JourneyService/ConflictDetection).
      These encapsulate business logic, calling repositories and handling errors.
    * Presentation Layer: UI widgets react to BLoC states. Use BlocBuilder/BlocSelector for
      rebuilding on state changes and BlocListener for side effects (e.g., showing snackbars on
      errors).
* Firebase Integration: Enable real-time listeners for collaborative features. Use type-safe
  Firestore converters for data mapping.
* Internationalization: Support English, Hindi, Tamil via flutter_localizations and l10n.yaml. Use
  AppLocalizations for strings in UI.
* Navigation: Use go_router for routes.
* Only the Bloc layer can use Implementation layer. UI should only use the model, bloc and services
  layer.

### UI/UX Design Principles

Prioritize a unique, expressive design that feels modern and adventurous, inspired by travel
themes (e.g., subtle gradients evoking landscapes, icons with a wanderlust flair like custom map
pins or backpack motifs). Ensure consistency across the app: use Material 3 components with custom
ThemeData extensions for colors, typography, and elevations. Support light/dark modes with adaptive
palettes.

* User-Friendly Focus: Make interfaces intuitive and minimalistic—top priority. Avoid clutter: use
  whitespace generously, hide advanced options in collapsible sections or drawers. Employ clear
  hierarchies (e.g., bold headings for trip names, subtle text for details).
* Efficient Screen Utilization: Optimize layouts for all devices. Adapt on small screens (phones),
  stack elements vertically with scrollabl lists; on large screens (tablets/web), use grids or split
  views (e.g., timeline on left, details on right). Handle orientations: ensure timelines remain
  readable in landscape.
* Responsive and Expressive: Incorporate subtle animations (e.g., fade transitions for state
  changes) to make interactions feel lively. Unique elements: expressive custom widgets like
  ConnectedTimelineItemWidget for multi-level itineraries, with color-coded bars for activities (
  green for stays, blue for transit). Should be interactive and scale gracefully.

## Key Features Implementation

* UI must be **minimal, clean, modern, and clutter-free**
* Prioritize **user-friendliness above everything**
* Use consistent:
    * Typography
    * Spacing
    * Colors
    * Border radius
    * Component styles
* Use screen space efficiently. Layout must adapt smoothly to:
    * Small phones
    * Tablets
* Prefer progressive disclosure over dense layouts
* No business logic in UI
* Avoid tightly coupling layers
* Ensure responsive layouts
* Update requirements if needed
* Move displayed words in UI to localizations arb files. Translate the corresponding entry for each
  word.
* Run code analyzers to ensure no errors/warnings(except must_be_immutable)/infos, ensure code compiles and don't run tests

## Requirements documents
The requirements documents under /docs/requirements are the canonical description of the product.

Whenever a user-visible behaviour changes, you MUST update the corresponding requirements before or alongside the implementation.

Never describe implementation details.

### Requirements shall describe only:

- visible information
- user actions
- business rules
- navigation
- validation
- empty states
- loading states
- error states
- responsive differences only when behaviour differs

### Requirements shall never describe:

- widgets
- framework APIs
- state management
- theming
- typography
- animations
- spacing
- implementation details

Every requirement shall:

- have exactly one unique REQ_<PAGE>_<NUMBER> identifier
- belong to exactly one Path
- describe one behaviour or one atomic piece of UI entity(ItineraryViewer/Timeline/Journeys(or Stays or Sights)/Multi-leg(or Single-leg) etc.)
- be independently testable
- remain stable across refactoring


### Requirements Organization

Store functional requirements under `/docs/requirements`.

Example:

docs/
└── requirements/
├── README.md
├── Login.md
├── TripsListView.md
├── TripEditor.md
├────── ItineraryViewer.md
├────────── Itinerary.md
├────── BudgetingPage.md
└── ExpenseEditor.md

Each file represents one logical page or reusable user-facing component.

Within each file, organize requirements hierarchically using stable, self-explanatory Paths:

#### TripsListView
- TripsListView
- TripsListView.UpcomingTrips
- TripsListView.UpcomingTrips.YearFilter
- TripsListView.UpcomingTrips.TripCard
- TripsListView.UpcomingTrips.TripCard.StatusBadge
- TripsListView.UpcomingTrips.TripCard.Actions
- TripsListView.PastTrips
- TripsListView.PlanATrip
- TripsListView.EmptyState

#### TripEditor
- TripEditor
- TripEditor.Overview
- TripEditor.Itinerary
- TripEditor.Itinerary.Timeline
- TripEditor.Itinerary.Timeline.Transits
- TripEditor.Itinerary.Navigator
- TripEditor.Expenses
- TripEditor.Settings

Each requirement shall:
- Have a unique, permanent ID (e.g. `REQ_TLV_001`, `REQ_TED_042`).
- Belong to exactly one Path.
- Describe exactly one observable user-visible behaviour or business rule.
- Avoid implementation details (widgets, animations, colors, layouts, state management, etc.).

Never reuse or renumber requirement IDs.

## Testing

For each feature:

* Include at least one test that interacts with UI (e.g., via FlutterTester: pumpWidget, enterText,
  tap, verify widget states).
* In others, emulate actions by dispatching BLoC events, await state emissions, assert expected
  states/models.
* Use mock repositories for isolating REST API calls.

## Code Style and Best Practices

* Dart: Null safety, async/await for Futures, Streams for real-time. Immutable models with copyWith.
* Performance: Optimize Firestore queries and loading of pages dependent on trip data. Lazy-load
  images/assets.