## Release History
- Version 3.1.0 (Commit: e3055a84a2b8079d1bcd22d6f7505eb113ccf47b)
  - Display time-zone aware date times for transits/stays/sights
  - Ensure that only users registered with wandrr can be added as trip mates
  - Balance attractions/sights related expenses on trip mates add/removal

- Version 3.0.1 (Commit: d7bf42432b9443843bd6ee1d7bcde07ca230857f)
  - Ensure app initialization is synchronous to prevent the need for redundant loading animation on startup

- Version 3.0.0 (Commit: 6e88f70b487e3e5ad06cd85b789fbb8b07d7bc75)
  - Introduce itinerary timelines and sights/activities
  - Revamped the trip editor page for easy navigation
  - A common way to edit transits, stays and sights/notes/checklists

- Version 2.0.2 (Commit: ca7b51af2493dfbea522340cc17a326899a6023d)
  - Fixed a bug where theme and locale changes were not updating the app

- Version 2.0.1 (Commit: d7a14c7eeb6970390bbc7d4bdd6b380ec5759acc)
  - Make TripCreatorDialog scrollable
  - Navigate to Transits/Lodgings/Expenses/Itineraries with ease
  - Revamp and introduce consistent app theming
  - Format currency display according to locale
  - Consolidate actions and migrate them to HomeAppBar toolbar

- Version 2.0.0 (Commit: 4f19f210159ffe98ccf9ce91ddc0cc6af3366741)
  - Migrated gradle to work with Android Studio N and android's 16 KB page requirement
  - Bump android gradle and pubspec versions
  - Make TripCreatorDialog scrollable to avoid bottom overflow
  - Added iOS configuration support
  - Navigate to Transits/Lodgings/Expenses/Itineraries
  - Introduce a type of APIService CachedDataService and decouple ApiServices from TripRepository, to lazily initialize them in Trip layer instead
  - Revamp and introduce consistent app theming
  - Split lib/data layer into app/auth/store/trip and introduce lib/blocs folder
  - Format currency display according to locale
  - Consolidate actions and migrate them to HomeAppBar toolbar
  - Add multi-platform release and version management

