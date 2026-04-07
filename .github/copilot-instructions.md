# Development Guidelines

You are assisting in developing Wandrr, a cross-platform travel planning app built with Flutter. The
app enables users to create and manage trips, including accommodations, transit, daily itineraries,
expenses, and collaborative features like expense splitting and debt settlement. It supports
multi-user collaboration with real-time updates and conflict resolution for timeline entities.

## Core Architecture

* State Management: BLoC pattern.
* Clean Architecture Layers:
    * Data Layer: Define models (TripData/Stay/Expense) as immutable Dart classes with JSON serialization (toJson/fromJson). Use repositories for data access.
    * Domain Layer: Implement use cases in the services layer (JourneyService/ConflictDetection). These encapsulate business logic, calling repositories and handling errors.
    * Presentation Layer: UI widgets react to BLoC states. Use BlocBuilder/BlocSelector for rebuilding on state changes and BlocListener for side effects (e.g., showing snackbars on errors).
* Firebase Integration: Enable real-time listeners for collaborative features. Use type-safe Firestore converters for data mapping.
* Internationalization: Support English, Hindi, Tamil via flutter_localizations and l10n.yaml. Use AppLocalizations for strings in UI.
* Navigation: Use go_router for routes.
* Only the Bloc layer can use Implementation layer. UI should only use the model, bloc and services layer.

### UI/UX Design Principles

Prioritize a unique, expressive design that feels modern and adventurous, inspired by travel themes (e.g., subtle gradients evoking landscapes, icons with a wanderlust flair like custom map pins or backpack motifs). Ensure consistency across the app: use Material 3 components with custom ThemeData extensions for colors, typography, and elevations. Support light/dark modes with adaptive palettes.

* User-Friendly Focus: Make interfaces intuitive and minimalistic—top priority. Avoid clutter: use whitespace generously, hide advanced options in collapsible sections or drawers. Employ clear hierarchies (e.g., bold headings for trip names, subtle text for details).
* Efficient Screen Utilization: Optimize layouts for all devices. Adapt on small screens (phones), stack elements vertically with scrollabl lists; on large screens (tablets/web), use grids or split views (e.g., timeline on left, details on right). Handle orientations: ensure timelines remain readable in landscape.
* Responsive and Expressive: Incorporate subtle animations (e.g., fade transitions for state changes) to make interactions feel lively. Unique elements: expressive custom widgets like ConnectedTimelineItemWidget for multi-level itineraries, with color-coded bars for activities (green for stays, blue for transit). Should be interactive and scale gracefully.

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
* Always update requirements.md file

## Testing

For each feature:

* Include at least one test that interacts with UI (e.g., via FlutterTester: pumpWidget, enterText, tap, verify widget states).
* In others, emulate actions by dispatching BLoC events, await state emissions, assert expected states/models.
* Use mock repositories for isolating REST API calls.

## Code Style and Best Practices

* Dart: Null safety, async/await for Futures, Streams for real-time. Immutable models with copyWith.
* Performance: Optimize Firestore queries (e.g., limit results, use indexes). Lazy-load images/assets.
* Security: Validate inputs, handle auth states globally.