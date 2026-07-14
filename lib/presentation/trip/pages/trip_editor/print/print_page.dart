import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/print_options.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/data/trip/services/trip_print_service.dart';
import 'package:wandrr/l10n/app_localizations.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/bloc_extensions.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/print/models/print_transit_group.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/print/widgets/print_action_panel.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/print/widgets/print_form_content.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/print/widgets/print_transit_group_tile.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

/// Route entry point for the print flow.
///
/// Resolves [tripId] to a [TripDataFacade] by reusing the currently active
/// trip when it already matches, or by dispatching a non-activating
/// [LoadTrip] (`shouldActivateTrip: false`) so the trip data can be loaded
/// for preview purposes only — no API services / budgeting service overhead
/// is spun up just to print a trip. The bloc responds with
/// [LoadedTripPreview] once the requested trip data is available, which this
/// widget listens for exclusively.
class PrintTripPage extends StatefulWidget {
  final String tripId;

  const PrintTripPage({required this.tripId, super.key});

  @override
  State<PrintTripPage> createState() => _PrintTripPageState();
}

class _PrintTripPageState extends State<PrintTripPage> {
  TripDataFacade? _tripData;
  bool _hasRequestedPreviewLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureTripDataAvailable();
  }

  @override
  void didUpdateWidget(covariant PrintTripPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tripId == widget.tripId) {
      return;
    }

    _tripData = null;
    _hasRequestedPreviewLoad = false;
    _ensureTripDataAvailable();
  }

  void _ensureTripDataAvailable() {
    final tripRepository = context.tripRepository;
    if (_hasRequestedPreviewLoad) {
      return;
    }

    final metadata = tripRepository.tripMetadataCollection.items
        .where((trip) => trip.id == widget.tripId)
        .single;
    _hasRequestedPreviewLoad = true;
    context.addTripManagementEvent(
      LoadTrip(tripMetadata: metadata, isTripActivated: false),
    );
  }

  TripMetadataFacade? get _displayMetadata =>
      _tripData?.tripMetadata ??
      context.tripRepository.tripMetadataCollection.items
          .where((trip) => trip.id == widget.tripId)
          .firstOrNull;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripManagementBloc, TripManagementState>(
        buildWhen: (_, state) => state is LoadedTripPreview,
        builder: (context, state) {
          if (state is LoadedTripPreview) {
            _tripData = state.tripData;
          }

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 420),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity:
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
              child: child,
            ),
            child: _tripData != null
                ? KeyedSubtree(
                    key: const ValueKey('print_page_ready'),
                    child: PrintPage(tripData: _tripData!),
                  )
                : KeyedSubtree(
                    key: const ValueKey('print_page_loading'),
                    child: PrintPage.loading(metadata: _displayMetadata),
                  ),
          );
        });
  }
}

class PrintPage extends StatefulWidget {
  final TripDataFacade? tripData;
  final TripMetadataFacade? metadata;

  PrintPage({required TripDataFacade tripData, super.key})
      : tripData = tripData,
        metadata = tripData.tripMetadata;

  const PrintPage.loading({this.metadata, super.key}) : tripData = null;

  @override
  State<PrintPage> createState() => _PrintPageState();
}

class _PrintPageState extends State<PrintPage> {
  static const _minimumTransitLoadingDuration = Duration(milliseconds: 1500);

  late final TextEditingController _titleController;
  late PrintOptions _options;

  bool _isGenerating = false;
  bool _transitsReady = false;

  late List<TransitFacade> _allTransits;

  StreamSubscription<bool>? _loadSub;
  Timer? _minDelayTimer;

  TripDataFacade? get _tripData => widget.tripData;

  @override
  void initState() {
    super.initState();
    final initialTitle = widget.metadata?.name ?? '';
    _titleController = TextEditingController(text: initialTitle);
    _options = PrintOptions(
      title: initialTitle,
      selectedTransitIds: const <String>{},
    );
    _allTransits = [];

    final tripData = _tripData;
    if (tripData == null) {
      return;
    }

    if (tripData.isFullyLoadedValue) {
      _hydrateLoadedData();
      _transitsReady = true;
      return;
    }

    final openTime = DateTime.now();
    _loadSub = tripData.isFullyLoaded.listen((loaded) {
      if (!loaded || !mounted) {
        return;
      }

      _loadSub?.cancel();
      _hydrateLoadedData();

      final elapsed = DateTime.now().difference(openTime);
      final remaining = _minimumTransitLoadingDuration - elapsed;
      if (remaining > Duration.zero) {
        _minDelayTimer = Timer(remaining, () {
          if (!mounted) {
            return;
          }
          setState(() => _transitsReady = true);
        });
      } else {
        setState(() => _transitsReady = true);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _loadSub?.cancel();
    _minDelayTimer?.cancel();
    super.dispose();
  }

  void _hydrateLoadedData() {
    _initTransits();
    _syncOptionsWithSectionAvailability();
  }

  void _initTransits() {
    final tripData = _tripData;
    if (tripData == null) {
      return;
    }

    _allTransits = tripData.transitCollection.items.toList()
      ..sort((a, b) => (a.departureDateTime ?? DateTime(0))
          .compareTo(b.departureDateTime ?? DateTime(0)));
    final allIds =
        _allTransits.where((t) => t.id != null).map((t) => t.id!).toSet();
    _options = _options.copyWith(selectedTransitIds: allIds);
  }

  void _syncOptionsWithSectionAvailability() {
    final availability = _computeSectionAvailability();
    _options = _options.copyWith(
      includeChecklist: availability.hasChecklist && _options.includeChecklist,
      includeExpenses: availability.hasExpenses && _options.includeExpenses,
      includeSights: availability.hasSights && _options.includeSights,
      includeNotes: availability.hasNotes && _options.includeNotes,
    );
  }

  _PrintSectionAvailability _computeSectionAvailability() {
    final tripData = _tripData;
    if (tripData == null) {
      return const _PrintSectionAvailability.allEnabled();
    }

    final start = tripData.tripMetadata.startDate;
    final end = tripData.tripMetadata.endDate;

    var hasChecklist = false;
    var hasSights = false;
    var hasNotes = false;

    if (start != null && end != null) {
      final totalDays =
          start.calculateDaysInBetween(end, includeBoundaryDay: true);
      for (var i = 0; i < totalDays; i++) {
        final day = start.add(Duration(days: i));
        final planData =
            tripData.itineraryCollection.getItineraryForDay(day).planData;
        hasChecklist = hasChecklist || planData.checkLists.isNotEmpty;
        hasSights = hasSights || planData.sights.isNotEmpty;
        hasNotes = hasNotes || planData.notes.isNotEmpty;
        if (hasChecklist && hasSights && hasNotes) {
          break;
        }
      }
    }

    return _PrintSectionAvailability(
      hasChecklist: hasChecklist,
      hasExpenses: tripData.expenseCollection.items.isNotEmpty,
      hasSights: hasSights,
      hasNotes: hasNotes,
    );
  }

  bool _isInterCity(TransitFacade t) {
    final dep = t.departureLocation?.context.city;
    final arr = t.arrivalLocation?.context.city;
    if (dep == null || arr == null) {
      return true;
    }
    return dep.toLowerCase() != arr.toLowerCase();
  }

  List<TransitFacade> get _visibleTransits {
    if (!_transitsReady) {
      return [];
    }
    return _allTransits.where((t) {
      final isInter = _isInterCity(t);
      if (isInter && !_options.includeInterCityTransit) {
        return false;
      }
      if (!isInter && !_options.includeIntraCityTransit) {
        return false;
      }
      return true;
    }).toList();
  }

  List<PrintTransitGroup> get _transitGroups {
    final visible = _visibleTransits;
    final journeyMap = <String, List<TransitFacade>>{};
    final standalone = <TransitFacade>[];

    for (final t in visible) {
      if (t.journeyId != null && t.journeyId!.isNotEmpty) {
        journeyMap.putIfAbsent(t.journeyId!, () => []).add(t);
      } else {
        standalone.add(t);
      }
    }

    final groups = <PrintTransitGroup>[];
    for (final entry in journeyMap.entries) {
      groups.add(PrintTransitGroup(journeyId: entry.key, legs: entry.value));
    }
    for (final t in standalone) {
      groups.add(PrintTransitGroup(journeyId: null, legs: [t]));
    }

    groups.sort((a, b) {
      final aTime = a.legs.first.departureDateTime ?? DateTime(0);
      final bTime = b.legs.first.departureDateTime ?? DateTime(0);
      return aTime.compareTo(bTime);
    });
    return groups;
  }

  PrintOptions _buildOptions() {
    final visibleIds =
        _visibleTransits.where((t) => t.id != null).map((t) => t.id!).toSet();
    final selectedIds = (_options.selectedTransitIds ?? const <String>{})
        .intersection(visibleIds);

    final fallbackTitle = widget.metadata?.name ?? '';
    return _options.copyWith(
      title: _titleController.text.trim().isEmpty
          ? fallbackTitle
          : _titleController.text.trim(),
      selectedTransitIds: selectedIds,
      mergedJourneyIds: Set<String>.from(_options.mergedJourneyIds),
    );
  }

  Future<void> _onGenerate() async {
    final tripData = _tripData;
    if (tripData == null) {
      return;
    }

    setState(() => _isGenerating = true);
    try {
      final options = _buildOptions();
      final pdfBytes = await TripPrintService().generatePdf(tripData, options);

      if (!mounted) {
        return;
      }

      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: options.title,
      );
    } on Exception catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.localizations.pdfGenerationFailed}: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final pageBackground =
        isLight ? AppColors.lightBackground : AppColors.darkSurfaceVariant;

    final controlsEnabled = _tripData != null && _transitsReady;

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: Text(l10n.printTrip),
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: theme.appBarTheme.backgroundColor ?? cs.surface,
        surfaceTintColor: cs.surfaceTint,
      ),
      body: ColoredBox(
        color: pageBackground,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isLargeScreen = constraints.maxWidth > 800;
              return Column(
                children: [
                  Expanded(
                    child: _buildFormContent(
                      context,
                      isLargeScreen: isLargeScreen,
                      controlsEnabled: controlsEnabled,
                    ),
                  ),
                  PrintActionPanel(
                    isLargeScreen: isLargeScreen,
                    transitsReady: controlsEnabled,
                    isGenerating: _isGenerating,
                    onGenerate: _onGenerate,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent(
    BuildContext context, {
    required bool isLargeScreen,
    required bool controlsEnabled,
  }) {
    final availability = controlsEnabled
        ? _computeSectionAvailability()
        : const _PrintSectionAvailability.allEnabled();

    return PrintFormContent(
      isLargeScreen: isLargeScreen,
      transitsReady: _transitsReady,
      controlsEnabled: controlsEnabled,
      titleController: _titleController,
      includeChecklist: _options.includeChecklist,
      includeExpenses: _options.includeExpenses,
      includeSights: _options.includeSights,
      includeNotes: _options.includeNotes,
      checklistEnabled: controlsEnabled && availability.hasChecklist,
      expensesEnabled: controlsEnabled && availability.hasExpenses,
      sightsEnabled: controlsEnabled && availability.hasSights,
      notesEnabled: controlsEnabled && availability.hasNotes,
      includeInterCityTransit: _options.includeInterCityTransit,
      includeIntraCityTransit: _options.includeIntraCityTransit,
      onIncludeChecklistChanged: (v) =>
          setState(() => _options = _options.copyWith(includeChecklist: v)),
      onIncludeExpensesChanged: (v) =>
          setState(() => _options = _options.copyWith(includeExpenses: v)),
      onIncludeSightsChanged: (v) =>
          setState(() => _options = _options.copyWith(includeSights: v)),
      onIncludeNotesChanged: (v) =>
          setState(() => _options = _options.copyWith(includeNotes: v)),
      onIncludeInterCityTransitChanged: (v) => setState(
          () => _options = _options.copyWith(includeInterCityTransit: v)),
      onIncludeIntraCityTransitChanged: (v) => setState(
          () => _options = _options.copyWith(includeIntraCityTransit: v)),
      transitContent:
          _buildTransitSelectionContent(context, isLargeScreen: isLargeScreen),
      transitLoadingContent:
          PrintTransitLoadingList(isLargeScreen: isLargeScreen),
    );
  }

  Widget _buildTransitSelectionContent(
    BuildContext context, {
    required bool isLargeScreen,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final groups = _transitGroups;

    if (groups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          l10n.noTransitsAvailable,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
        ),
      );
    }

    if (!isLargeScreen) {
      return Column(
        key: const ValueKey('printTransitListSingleCol'),
        children: groups.map(_buildTransitTile).toList(growable: false),
      );
    }

    final listHeight = _largeTransitListHeight(context);
    final shouldSplit = _shouldSplitIntoTwoColumns(
      itemCount: groups.length,
      availableListHeight: listHeight,
    );

    if (!shouldSplit) {
      return SizedBox(
        key: const ValueKey('printTransitListBigSingleCol'),
        height: listHeight,
        child: ListView(
          children: groups.map(_buildTransitTile).toList(growable: false),
        ),
      );
    }

    final midpoint = (groups.length / 2).ceil();
    final left = groups.take(midpoint).toList(growable: false);
    final right = groups.skip(midpoint).toList(growable: false);

    return SizedBox(
      key: const ValueKey('printTransitListBigTwoCol'),
      height: listHeight,
      child: SingleChildScrollView(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: left.map(_buildTransitTile).toList(growable: false),
              ),
            ),
            VerticalDivider(color: cs.outlineVariant, width: 16),
            Expanded(
              child: Column(
                children: right.map(_buildTransitTile).toList(growable: false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _largeTransitListHeight(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return (screenHeight * 0.42).clamp(260.0, 480.0);
  }

  bool _shouldSplitIntoTwoColumns({
    required int itemCount,
    required double availableListHeight,
  }) {
    const estimatedTileHeight = 72.0;
    final maxSingleColumnVisible =
        (availableListHeight / estimatedTileHeight).floor().clamp(2, 24);
    return itemCount > maxSingleColumnVisible;
  }

  Widget _buildTransitTile(PrintTransitGroup group) {
    final selectedIds = _options.selectedTransitIds ?? const <String>{};
    return PrintTransitGroupTile(
      group: group,
      isMerged: _options.mergedJourneyIds.contains(group.journeyId),
      selectedIds: selectedIds,
      onMergeToggled: (merged) {
        setState(() {
          if (group.journeyId == null) {
            return;
          }
          final mergedJourneyIds = Set<String>.from(_options.mergedJourneyIds);
          final nextSelectedIds = Set<String>.from(selectedIds);
          if (merged) {
            mergedJourneyIds.add(group.journeyId!);
            for (final leg in group.legs) {
              if (leg.id != null) {
                nextSelectedIds.add(leg.id!);
              }
            }
          } else {
            mergedJourneyIds.remove(group.journeyId!);
          }
          _options = _options.copyWith(
            mergedJourneyIds: mergedJourneyIds,
            selectedTransitIds: nextSelectedIds,
          );
        });
      },
      onLegToggled: (id, {required selected}) {
        setState(() {
          final nextSelectedIds = Set<String>.from(selectedIds);
          if (selected) {
            nextSelectedIds.add(id);
          } else {
            nextSelectedIds.remove(id);
          }
          _options = _options.copyWith(selectedTransitIds: nextSelectedIds);
        });
      },
    );
  }
}

class _PrintSectionAvailability {
  final bool hasChecklist;
  final bool hasExpenses;
  final bool hasSights;
  final bool hasNotes;

  const _PrintSectionAvailability({
    required this.hasChecklist,
    required this.hasExpenses,
    required this.hasSights,
    required this.hasNotes,
  });

  const _PrintSectionAvailability.allEnabled()
      : hasChecklist = true,
        hasExpenses = true,
        hasSights = true,
        hasNotes = true;
}
