/// Options that control which sections appear in the generated trip PDF.
class PrintOptions {
  final String title;
  final bool includeChecklist;
  final bool includeExpenses;
  final bool includeSights;
  final bool includeNotes;
  final bool includeInterCityTransit;
  final bool includeIntraCityTransit;

  /// When non-null, only transits whose id is in this set are included.
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

  PrintOptions copyWith({
    String? title,
    bool? includeChecklist,
    bool? includeExpenses,
    bool? includeSights,
    bool? includeNotes,
    bool? includeInterCityTransit,
    bool? includeIntraCityTransit,
    Set<String>? selectedTransitIds,
    Set<String>? mergedJourneyIds,
  }) {
    return PrintOptions(
      title: title ?? this.title,
      includeChecklist: includeChecklist ?? this.includeChecklist,
      includeExpenses: includeExpenses ?? this.includeExpenses,
      includeSights: includeSights ?? this.includeSights,
      includeNotes: includeNotes ?? this.includeNotes,
      includeInterCityTransit:
          includeInterCityTransit ?? this.includeInterCityTransit,
      includeIntraCityTransit:
          includeIntraCityTransit ?? this.includeIntraCityTransit,
      selectedTransitIds: selectedTransitIds ?? this.selectedTransitIds,
      mergedJourneyIds: mergedJourneyIds ?? this.mergedJourneyIds,
    );
  }
}
