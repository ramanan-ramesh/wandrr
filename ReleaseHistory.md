## Release History
- Version 2.0.0 (Commit: 33779efecbe7bab13dab7d3a5b2b6c6a6f17e8ea)
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

