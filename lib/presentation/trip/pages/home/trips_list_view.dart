import 'dart:async';

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
import 'package:wandrr/presentation/app/routing/app_router.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/app/widgets/dialog.dart';
import 'package:wandrr/presentation/trip/bloc_extensions.dart';
import 'package:wandrr/presentation/trip/pages/home/copy_trip_dialog.dart';
import 'package:wandrr/presentation/trip/pages/home/thumbnail_selector.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/delete_trip_dialog.dart';
import 'package:wandrr/presentation/trip/widgets/print_trip_dialog.dart';
import 'package:wandrr/presentation/trip/widgets/shimmer_placeholder.dart';
import 'package:wandrr/presentation/trip/widgets/trip_entity_update_handler.dart';
import 'package:wandrr/presentation/trip/widgets/unified_trip_dialog.dart';

// Extra clearance so the last card is never hidden behind the centered-float FAB.
// Extended-FAB height (≈56) + kFloatingActionButtonMargin (16) + comfortable buffer.
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
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 10),
      child: BlocConsumer<TripManagementBloc, TripManagementState>(
        buildWhen: _shouldBuildListView,
        listener: (context, state) {},
        builder: (context, state) {
          return StreamBuilder<bool>(
            stream: context.tripRepository.tripMetadataCollection.onLoaded,
            initialData: context.tripRepository.tripMetadataCollection.isLoaded,
            builder: (context, snapshot) {
              final isLoaded = snapshot.data ?? false;
              final tripMetadatas = context
                  .tripRepository.tripMetadataCollection.items
                  .toList(growable: false)
                ..sort((a, b) => a.startDate!.compareTo(b.startDate!));

              if (!isLoaded && tripMetadatas.isEmpty) {
                return _buildShimmerGrid();
              }

              if (tripMetadatas.isNotEmpty) {
                return _buildTripsSections(context, tripMetadatas, isLoaded);
              }

              return _EmptyState();
            },
          );
        },
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: _kFabBottomClearance),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      itemCount: 3,
      itemBuilder: (_, __) =>
          ShimmerPlaceholder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildTripsSections(
      BuildContext context, List<TripMetadataFacade> trips, bool isLoaded) {
    final today = DateTime.now().toMidnight();

    final upcomingRaw =
        trips.where((t) => !t.endDate!.isBefore(today)).toList();
    final pastRaw = trips.where((t) => t.endDate!.isBefore(today)).toList();

    final upcomingYears = upcomingRaw
        .map((t) => t.startDate!.year)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    final pastYears = pastRaw.map((t) => t.startDate!.year).toSet().toList()
      ..sort((a, b) => b.compareTo(a));

    // Sync selections when the year list changes.
    if (upcomingYears.isNotEmpty &&
        (_selectedUpcomingYear == null ||
            !upcomingYears.contains(_selectedUpcomingYear))) {
      _selectedUpcomingYear = upcomingYears.first;
    }
    if (pastYears.isNotEmpty &&
        (_selectedPastYear == null || !pastYears.contains(_selectedPastYear))) {
      _selectedPastYear = pastYears.first;
    }

    final slivers = <Widget>[];

    if (upcomingRaw.isNotEmpty) {
      slivers.add(_buildSectionHeader(
        context,
        label: context.localizations.upcomingTrips,
        icon: Icons.flight_takeoff_rounded,
        color: AppColors.brandPrimary,
      ));
      slivers.add(SliverToBoxAdapter(
        child: _YearChips(
          years: upcomingYears,
          selectedYear: _selectedUpcomingYear,
          onSelected: (y) => setState(() => _selectedUpcomingYear = y),
        ),
      ));
      final filtered = upcomingRaw
          .where((t) => t.startDate!.year == _selectedUpcomingYear)
          .toList();
      slivers.add(_buildTripGrid(filtered, isLoaded));
    }

    if (pastRaw.isNotEmpty) {
      slivers.add(_buildSectionHeader(
        context,
        label: context.localizations.pastTrips,
        icon: Icons.history_rounded,
        color: AppColors.neutral500,
      ));
      slivers.add(SliverToBoxAdapter(
        child: _YearChips(
          years: pastYears,
          selectedYear: _selectedPastYear,
          onSelected: (y) => setState(() => _selectedPastYear = y),
        ),
      ));
      final filtered = pastRaw
          .where((t) => t.startDate!.year == _selectedPastYear)
          .toList()
        ..sort((a, b) => b.startDate!.compareTo(a.startDate!));
      slivers.add(_buildTripGrid(filtered, isLoaded));
    }

    // Ensure last cards are never hidden behind the FAB.
    slivers.add(const SliverPadding(
      padding: EdgeInsets.only(bottom: _kFabBottomClearance),
    ));

    return CustomScrollView(slivers: slivers);
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 10),
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
      ),
    );
  }

  Widget _buildTripGrid(List<TripMetadataFacade> trips, bool isLoaded) {
    final itemCount =
        isLoaded ? trips.length : (trips.length < 3 ? 3 : trips.length + 1);
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index < trips.length) {
            return _TripCard(tripId: trips[index].id!);
          }
          return ShimmerPlaceholder(borderRadius: BorderRadius.circular(16));
        },
        childCount: itemCount,
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
  final List<int> years;
  final int? selectedYear;
  final ValueChanged<int> onSelected;

  const _YearChips({
    required this.years,
    required this.selectedYear,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: years.map((year) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(year.toString()),
              selected: selectedYear == year,
              onSelected: (selected) {
                if (selected) {
                  onSelected(year);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// Trip card
// ─────────────────────────────────────────────────────────────────────────────

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
    final trip = context.tripRepository.tripMetadataCollection.items
        .firstWhere((e) => e.id == widget.tripId);

    final thumbnail = Assets.images.tripThumbnails.values.firstWhere(
      (e) => e.keyName.split('/').last.split('.').first == trip.thumbnailTag,
    );

    final dateRange =
        '${trip.startDate!.dayDateMonthFormat} – ${trip.endDate!.dayDateMonthFormat}';
    final statusText = _computeStatusLabel(context, trip);

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
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        dateRange,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Status badge (top-left) ──────────────────────────────
              if (statusText != null)
                Positioned(
                  top: 10,
                  left: 10,
                  child: _StatusBadge(
                    label: statusText,
                    color: _statusColor(statusText),
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

  String? _computeStatusLabel(BuildContext context, TripMetadataFacade trip) {
    final today = DateTime.now().toMidnight();
    final start = trip.startDate!.toMidnight();
    final end = trip.endDate!.toMidnight();

    // Currently active
    if (!today.isBefore(start) && !today.isAfter(end)) {
      return context.localizations.tripStatusActive;
    }

    final daysUntil = start.difference(today).inDays;
    if (daysUntil == 1) {
      return context.localizations.tripStatusTomorrow;
    }
    if (daysUntil > 1 && daysUntil <= 30) {
      return context.localizations.tripStatusInDays(daysUntil);
    }
    return null;
  }

  Color _statusColor(String label) {
    if (label == context.localizations.tripStatusActive) {
      return AppColors.brandPrimary;
    }
    if (label == context.localizations.tripStatusTomorrow) {
      return AppColors.warning;
    }
    return AppColors.brandSecondaryLight;
  }

  // ── Dialog helpers ───────────────────────────────────────────────────────

  void _showThumbnailPicker(BuildContext context, TripMetadataFacade trip) {
    var selectedTag = trip.thumbnailTag;
    PlatformDialogElements.showGeneralDialog<String>(
      context,
      (dialogContext) => UnifiedTripDialog(
        title: dialogContext.localizations.chooseTripThumbnail,
        icon: const Icon(Icons.image_rounded),
        content: TripThumbnailCarouselSelector(
          selectedThumbnailTag: selectedTag,
          onChanged: (tag) {
            selectedTag = tag;
            (dialogContext as Element).markNeedsBuild();
          },
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
    final activeTrip = context.tripRepository.activeTrip;
    if (activeTrip != null && activeTrip.tripMetadata.id == trip.id) {
      showDialog(
        context: context,
        builder: (_) => PrintTripDialog(tripData: activeTrip),
      );
      return;
    }
    late final StreamSubscription<TripManagementState> sub;
    sub = BlocProvider.of<TripManagementBloc>(context).stream.listen((s) {
      if (s is LoadedTripPreview) {
        sub.cancel();
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (_) => PrintTripDialog(tripData: s.tripData),
          );
        }
      }
    });
    context.addTripManagementEvent(
      LoadTrip(tripMetadata: trip, shouldActivateTrip: false),
    );
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
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
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
