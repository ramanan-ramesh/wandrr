import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wandrr/asset_manager/assets.gen.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/routing/app_routes.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/app/widgets/dialog.dart';
import 'package:wandrr/presentation/trip/bloc_extensions.dart';
import 'package:wandrr/presentation/trip/pages/home/copy_trip_dialog.dart';
import 'package:wandrr/presentation/trip/pages/home/thumbnail_selector.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/delete_trip_dialog.dart';
import 'package:wandrr/presentation/trip/widgets/shimmer_placeholder.dart';
import 'package:wandrr/presentation/trip/widgets/trip_entity_update_handler.dart';
import 'package:wandrr/presentation/trip/widgets/unified_trip_dialog.dart';

const double _kFabBottomClearance = 80.0;

class TripListView extends StatefulWidget {
  const TripListView({super.key});

  @override
  State<TripListView> createState() => _TripListViewState();
}

class _TripListViewState extends State<TripListView> {
  int? _selectedUpcomingYear;
  int? _selectedPastYear;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripManagementBloc, TripManagementState>(
      buildWhen: _shouldBuildListView,
      builder: (context, state) {
        final tripMetadatas = context
            .tripRepository.tripMetadataCollection.items
            .toList(growable: false);

        if (tripMetadatas.isNotEmpty) {
          return _buildTripsSections(context, tripMetadatas);
        }

        return _EmptyState();
      },
    );
  }

  Widget _buildTripsSections(
      BuildContext context, List<TripMetadataFacade> trips) {
    final upcomingTrips =
        _partitionTripsByYear(trips, filterUpcomingTrips: true);
    final pastTrips = _partitionTripsByYear(trips, filterUpcomingTrips: false);

    _initializeSelectedUpcomingYear(upcomingTrips.keys);
    _initializeSelectedPastYear(pastTrips.keys);

    final slivers = <Widget>[];

    if (upcomingTrips.keys.isNotEmpty) {
      slivers.add(_buildSectionHeaderSliver(
        context,
        label: context.localizations.upcomingTrips,
        icon: Icons.flight_takeoff_rounded,
        color: AppColors.brandPrimary,
      ));
      slivers.add(const SliverToBoxAdapter(
        child: SizedBox(height: 10),
      ));
      slivers.add(SliverToBoxAdapter(
        child: _YearChips(
          years: upcomingTrips.keys,
          selectedYear: _selectedUpcomingYear,
          onSelected: (year) => setState(() => _selectedUpcomingYear = year),
        ),
      ));
      final upcomingTripsForSelectedYear =
          upcomingTrips[_selectedUpcomingYear] ?? const [];
      slivers.add(_buildTripSliverGrid(upcomingTripsForSelectedYear));
    }

    if (pastTrips.keys.isNotEmpty) {
      slivers.add(_buildSectionHeaderSliver(
        context,
        label: context.localizations.pastTrips,
        icon: Icons.history_rounded,
        color: AppColors.neutral500,
      ));
      slivers.add(const SliverToBoxAdapter(
        child: SizedBox(height: 10),
      ));
      slivers.add(SliverToBoxAdapter(
        child: _YearChips(
          years: pastTrips.keys,
          selectedYear: _selectedPastYear,
          onSelected: (year) => setState(() => _selectedPastYear = year),
        ),
      ));
      final pastTripsForSelectedYear = pastTrips[_selectedPastYear] ?? const [];
      slivers.add(_buildTripSliverGrid(pastTripsForSelectedYear));
    }

    slivers.add(const SliverPadding(
      padding: EdgeInsets.only(bottom: _kFabBottomClearance),
    ));

    return CustomScrollView(slivers: slivers);
  }

  Map<int, Iterable<TripMetadataFacade>> _partitionTripsByYear(
    List<TripMetadataFacade> trips, {
    required bool filterUpcomingTrips,
  }) {
    final today = DateTime.now().toMidnight();
    final recentToPastTrips = trips.toList()
      ..sort((a, b) => b.startDate!.compareTo(a.startDate!));

    final tripsPerYear = <int, List<TripMetadataFacade>>{};

    for (final trip in recentToPastTrips) {
      final startDate = trip.startDate;
      final endDate = trip.endDate;

      final isUpcoming = !endDate!.toMidnight().isBefore(today);
      if (isUpcoming == filterUpcomingTrips) {
        tripsPerYear.putIfAbsent(startDate!.year, () => []).add(trip);
      }
    }

    return tripsPerYear;
  }

  void _initializeSelectedUpcomingYear(Iterable<int> years) {
    if (years.isEmpty) {
      _selectedUpcomingYear = null;
      return;
    }
    if (_selectedUpcomingYear == null ||
        !years.contains(_selectedUpcomingYear)) {
      _selectedUpcomingYear = years.first;
    }
  }

  void _initializeSelectedPastYear(Iterable<int> years) {
    if (years.isEmpty) {
      _selectedPastYear = null;
      return;
    }
    if (_selectedPastYear == null || !years.contains(_selectedPastYear)) {
      _selectedPastYear = years.first;
    }
  }

  SliverToBoxAdapter _buildSectionHeaderSliver(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return SliverToBoxAdapter(
      child: Row(
        children: [
          Container(
            width: 3,
            height: 22,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
          ),
        ],
      ),
    );
  }

  SliverGrid _buildTripSliverGrid(Iterable<TripMetadataFacade> trips) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => _TripCard(tripId: trips.elementAt(index).id!),
        childCount: trips.length,
      ),
    );
  }

  bool _shouldBuildListView(
      TripManagementState prev, TripManagementState curr) {
    if (curr.isTripEntityUpdated<TripMetadataFacade>()) {
      final s = curr as UpdatedTripEntity;
      return s.dataState == DataState.delete || s.dataState == DataState.create;
    }
    return false;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Year chips
// ─────────────────────────────────────────────────────────────────────────────

class _YearChips extends StatelessWidget {
  final Iterable<int> years;
  final int? selectedYear;
  final ValueChanged<int> onSelected;

  const _YearChips({
    required this.years,
    required this.selectedYear,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = context.isLightTheme;
    final activeColor =
        isLight ? AppColors.brandPrimary : AppColors.brandPrimaryLight;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: years.map((year) {
          final isSelected = selectedYear == year;
          final borderColor = isSelected
              ? activeColor
              : (isLight ? AppColors.neutral400 : AppColors.neutral500);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(year.toString()),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onSelected(year);
                }
              },
              side: BorderSide(
                color: borderColor,
                width: isSelected ? 2.0 : 1.5,
              ),
              selectedColor: activeColor.withValues(alpha: 0.14),
              checkmarkColor: activeColor,
              labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isSelected
                        ? activeColor
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.luggage_rounded,
              size: 80,
              color: colorScheme.primary.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 20),
            Text(
              context.localizations.startYourAdventure,
              style:
                  textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              context.localizations.noTripsSubtitle,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.55),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TripCard extends StatefulWidget {
  final String tripId;

  const _TripCard({required this.tripId});

  @override
  State<_TripCard> createState() => _TripCardState();
}

class _TripCardState extends State<_TripCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return TripEntityUpdateHandler<TripMetadataFacade>(
      shouldRebuild: (before, after) =>
          after.id == widget.tripId &&
          (before.name != after.name ||
              !before.startDate!.isOnSameDayAs(after.startDate!) ||
              !before.endDate!.isOnSameDayAs(after.endDate!) ||
              before.thumbnailTag != after.thumbnailTag),
      widgetBuilder: _buildWithTrip,
    );
  }

  Widget _buildWithTrip(BuildContext context) {
    final trip = _findTripById(context);
    if (trip == null) {
      return const SizedBox.shrink();
    }

    final thumbnail = _resolveThumbnail(trip.thumbnailTag);

    final dateRange =
        '${trip.startDate!.dayDateMonthFormat} – ${trip.endDate!.dayDateMonthFormat}';
    final statusBadge = _computeStatusBadge(context, trip);

    return AnimatedScale(
      scale: _isPressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOut,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: _isPressed ? 1 : 3,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () => context.go(AppRoutes.tripEditorPath(trip.id!)),
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          splashColor: Colors.white.withValues(alpha: 0.20),
          highlightColor: Colors.white.withValues(alpha: 0.10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Hero image ──────────────────────────────────────────────
              thumbnail.image(
                fit: BoxFit.cover,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded || frame != null) {
                    return child;
                  }
                  return const ShimmerPlaceholder(
                      borderRadius: BorderRadius.zero);
                },
              ),

              // ── Bottom gradient + name / date ────────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 44, 14, 14),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        trip.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        dateRange,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white70,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Status badge (top-left) ──────────────────────────────
              if (statusBadge != null)
                Positioned(
                  top: 10,
                  left: 10,
                  child: _StatusBadge(
                    label: statusBadge.label,
                    color: statusBadge.color,
                  ),
                ),

              // ── Overflow actions menu (top-right) ────────────────────
              Positioned(
                top: 6,
                right: 6,
                child: _CardActionsMenu(
                  trip: trip,
                  onChangeThumbnail: () => _showThumbnailPicker(context, trip),
                  onPrint: () => _showPrintDialog(context, trip),
                  onCopy: () => _showCopyDialog(context, trip),
                  onDelete: () => _showDeleteDialog(context, trip),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Status badge helpers ─────────────────────────────────────────────────

  TripMetadataFacade? _findTripById(BuildContext context) {
    for (final trip in context.tripRepository.tripMetadataCollection.items) {
      if (trip.id == widget.tripId) {
        return trip;
      }
    }
    return null;
  }

  AssetGenImage _resolveThumbnail(String thumbnailTag) {
    for (final asset in Assets.images.tripThumbnails.values) {
      final tag = asset.keyName.split('/').last.split('.').first;
      if (tag == thumbnailTag) {
        return asset;
      }
    }
    return Assets.images.tripThumbnails.values.first;
  }

  _TripStatusBadgeData? _computeStatusBadge(
      BuildContext context, TripMetadataFacade trip) {
    final today = DateTime.now().toMidnight();
    final start = trip.startDate!.toMidnight();
    final end = trip.endDate!.toMidnight();

    // Currently active
    if (!today.isBefore(start) && !today.isAfter(end)) {
      return _TripStatusBadgeData(
        label: context.localizations.tripStatusActive,
        color: AppColors.brandPrimary,
      );
    }

    final daysUntil = start.difference(today).inDays;
    if (daysUntil == 1) {
      return _TripStatusBadgeData(
        label: context.localizations.tripStatusTomorrow,
        color: AppColors.warning,
      );
    }
    if (daysUntil > 1 && daysUntil <= 30) {
      return _TripStatusBadgeData(
        label: context.localizations.tripStatusInDays(daysUntil),
        color: AppColors.brandSecondaryLight,
      );
    }
    return null;
  }

  // ── Dialog helpers ───────────────────────────────────────────────────────

  void _showThumbnailPicker(BuildContext context, TripMetadataFacade trip) {
    var selectedTag = trip.thumbnailTag;
    PlatformDialogElements.showGeneralDialog<String>(
      context,
      (dialogContext) => UnifiedTripDialog(
        title: dialogContext.localizations.chooseTripThumbnail,
        icon: const Icon(Icons.image_rounded),
        content: StatefulBuilder(
          builder: (context, setStateDialog) => TripThumbnailCarouselSelector(
            selectedThumbnailTag: selectedTag,
            onChanged: (tag) {
              setStateDialog(() {
                selectedTag = tag;
              });
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(dialogContext.localizations.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(selectedTag),
            child: Text(dialogContext.localizations.select),
          ),
        ],
      ),
      onDialogResult: (result) {
        if (result != null && result != trip.thumbnailTag) {
          final updated = trip.clone()..thumbnailTag = result;
          context.addTripManagementEvent(
            UpdateTripEntity<TripMetadataFacade>.update(tripEntity: updated),
          );
        }
      },
    );
  }

  void _showPrintDialog(BuildContext context, TripMetadataFacade trip) {
    if (trip.id == null) {
      return;
    }
    // Uses go() (not push()) so the address bar reflects '.../print':
    // go_router's push() creates an ImperativeRouteMatch whose location is
    // excluded from the browser's reported URI. The origin page to return
    // to on close is passed via `extra` (not a query param) so the print
    // route itself stays a single stable URL.
    context.go(AppRoutes.printTripPath(trip.id!), extra: AppRoutes.trips);
  }

  void _showCopyDialog(BuildContext context, TripMetadataFacade trip) {
    PlatformDialogElements.showGeneralDialog(context, (dialogContext) {
      return MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: context.appDataRepository),
          RepositoryProvider.value(value: context.tripRepository),
        ],
        child: BlocProvider.value(
          value: BlocProvider.of<TripManagementBloc>(context),
          child: CopyTripDialog(sourceTrip: trip),
        ),
      );
    });
  }

  void _showDeleteDialog(BuildContext context, TripMetadataFacade trip) {
    PlatformDialogElements.showAlertDialog(context, (ctx) {
      return DeleteTripDialog(widgetContext: context, tripMetadataFacade: trip);
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card overflow‑menu widget
// ─────────────────────────────────────────────────────────────────────────────

class _CardActionsMenu extends StatelessWidget {
  final TripMetadataFacade trip;
  final VoidCallback onChangeThumbnail;
  final VoidCallback onPrint;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  const _CardActionsMenu({
    required this.trip,
    required this.onChangeThumbnail,
    required this.onPrint,
    required this.onCopy,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(
          context.isLightTheme ? Colors.white : AppColors.darkSurface,
        ),
        padding:
            const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 6)),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(14))),
        ),
      ),
      builder: (context, controller, _) {
        return Material(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () =>
                controller.isOpen ? controller.close() : controller.open(),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.more_vert, color: Colors.white, size: 20),
            ),
          ),
        );
      },
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.image_rounded),
          onPressed: onChangeThumbnail,
          child: Text(context.localizations.changeThumbnail),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.print_rounded),
          onPressed: onPrint,
          child: Text(context.localizations.printTrip),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.copy_rounded),
          onPressed: onCopy,
          child: Text(context.localizations.copyTrip),
        ),
        const Divider(height: 1, thickness: 1),
        MenuItemButton(
          leadingIcon:
              const Icon(Icons.delete_outline_rounded, color: AppColors.error),
          style: const ButtonStyle(
              foregroundColor: WidgetStatePropertyAll(AppColors.error)),
          onPressed: onDelete,
          child: Text(context.localizations.deleteTrip),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Frosted status badge
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DateTime midnight helper (local, avoids re-importing extensions)
// ─────────────────────────────────────────────────────────────────────────────

extension _DateTimeExt on DateTime {
  DateTime toMidnight() => DateTime(year, month, day);
}

class _TripStatusBadgeData {
  final String label;
  final Color color;

  const _TripStatusBadgeData({required this.label, required this.color});
}
