## Release History
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

