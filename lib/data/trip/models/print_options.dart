/// Options that control which sections appear in the generated trip PDF.
class PrintOptions {
  final String title;
  final bool includeChecklist;
  final bool includeExpenses;
  final bool includeSights;
  final bool includeNotes;
  final bool includeInterCityTransit;
  final bool includeIntraCityTransit;

  /// When non-null, only transits whose [id] is in this set are included.
  /// When null, all transits passing the inter/intra-city filter are included.
  final Set<String>? selectedTransitIds;

  /// Journey IDs whose legs should be merged into a single timeline entry
  /// (first leg departure → last leg arrival). Legs of merged journeys are
  /// excluded from the individual timeline and replaced by a single event.
  final Set<String> mergedJourneyIds;

  const PrintOptions({
    required this.title,
    this.includeChecklist = true,
    this.includeExpenses = true,
    this.includeSights = true,
    this.includeNotes = true,
    this.includeInterCityTransit = true,
    this.includeIntraCityTransit = true,
    this.selectedTransitIds,
    this.mergedJourneyIds = const {},
  });
}
