# Development Guidelines

You are assisting in developing Wandrr, a cross-platform travel planning app built with Flutter. The
app enables users to create and manage trips, including accommodations, transit, daily itineraries,
expenses, and collaborative features like expense splitting and debt settlement. It supports
multi-user collaboration with real-time updates and conflict resolution for timeline entities.

This document describes **how Wandrr is built**: architecture, technology choices, and project
policy. It intentionally does not contain code-review heuristics or UI design guidance — those live
in the dedicated skills:

* `.github/skills/flutter-code-reviewer/SKILL.md` — how to evaluate code quality.
* `.github/skills/flutter-ui-architect/SKILL.md` — how to design and compose new screens/UI.

## Architecture

### Layers

* **Data Layer**: Models (TripData/Stay/Expense) as immutable Dart classes with JSON
  serialization (toJson/fromJson). Repositories are the only data-access surface.
* **Domain Layer**: Use cases live in the services layer (JourneyService/ConflictDetection).
  Services encapsulate business logic, call repositories, and handle errors.
* **Presentation Layer**: UI widgets react to BLoC state. Use BlocBuilder/BlocSelector for
  rebuilds and BlocListener for side effects (e.g., showing snackbars on errors).

### Layer Access Rules

* Only the Bloc layer may depend on the repository/implementation layer.
* UI (presentation) may only depend on Models, Blocs, and the Services layer.
* Business logic belongs in Services — never in the UI, and never duplicated across Blocs.

### Folder Structure (`lib/`)

* `asset_manager/` — asset loading/registration
* `blocs/` — BLoC state management
* `data/` — models and repositories
* `l10n/` — generated localization
* `presentation/` — screens and widgets

## Technology Stack

* **State management**: flutter_bloc
* **Navigation**: go_router
* **Backend**: Firebase (Firestore real-time listeners, Firebase Auth, Remote Config)
* **Localization**: flutter_localizations + l10n.yaml, generated AppLocalizations
  (English, Hindi, Tamil)
* **UI**: Material 3 with custom ThemeData extensions for colors, typography, and elevations;
  light/dark adaptive palettes

## Firebase Integration

* Use type-safe Firestore converters for data mapping.
* Enable real-time listeners for collaborative features (multi-user edits, conflict resolution on
  timeline entities).

## Product Design Philosophy

* UI must be minimal, clean, modern, and clutter-free; user-friendliness is the top priority.
* Visual identity is travel-themed (gradients evoking landscapes, wanderlust iconography) expressed
  consistently through the shared theme rather than ad hoc per screen.
* Prefer progressive disclosure over dense layouts: surface only what's needed, move advanced
  options into collapsible sections or drawers.
* Layouts must adapt smoothly between small phones and large screens (tablets/web): stacked
  scrollable lists on phones, grids or split views (e.g., timeline on left, details on right) on
  larger screens. Timelines must remain readable in both portrait and landscape.
* Prefer static interfaces by default. Introduce animation only when it improves comprehension,
  continuity, or perceived responsiveness — favor implicit Material animations before custom
  animation implementations.

## Internationalization

* All user-visible strings must come from AppLocalizations / .arb files — no hardcoded UI text.
* Every new string requires a translated entry in app_en.arb, app_hi.arb, and app_ta.arb.

## Delivery Checklist

* Run code analyzers to ensure no errors/warnings (except must_be_immutable)/infos, ensure code
  compiles, and don't run tests.
* Update requirements alongside any user-visible behaviour change.

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