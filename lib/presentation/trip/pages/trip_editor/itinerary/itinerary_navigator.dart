import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/app/widgets/bubble_tab_bar.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/itinerary_viewer.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/viewer/notes_and_checklists.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/viewer/sights.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/widgets/date_strip.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/trip_entity_update_handler.dart';

class ItineraryNavigator extends StatefulWidget {
  final void Function(DateTime) onNavigatedToDate;

  const ItineraryNavigator({required this.onNavigatedToDate, super.key});

  @override
  State<ItineraryNavigator> createState() => _ItineraryNavigatorState();
}

class _ItineraryNavigatorState extends State<ItineraryNavigator>
    with TickerProviderStateMixin {
  static const Duration _kAnimationDuration = Duration(milliseconds: 400);
  static const Curve _kFadeCurve = Curves.easeInOut;
  static const Curve _kSlideCurve = Curves.easeOutCubic;

  late DateTime _currentDate;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late TabController _tabController;

  DateTime get _startDate => context.activeTrip.tripMetadata.startDate!;
  DateTime get _endDate => context.activeTrip.tripMetadata.endDate!;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: _kAnimationDuration,
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: _kFadeCurve,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: _kSlideCurve,
    ));

    _currentDate = _startDate;
    widget.onNavigatedToDate(_currentDate);
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TripEntityUpdateHandler<TripMetadataFacade>(
      shouldRebuild: (beforeUpdate, afterUpdate) {
        final newStartDate = afterUpdate.startDate!;
        final newEndDate = afterUpdate.endDate!;
        if (!beforeUpdate.startDate!.isOnSameDayAs(newStartDate) ||
            !beforeUpdate.endDate!.isOnSameDayAs(newEndDate)) {
          if (_currentDate.isBefore(newStartDate)) {
            _currentDate = newStartDate;
          } else if (_currentDate.isAfter(newEndDate)) {
            _currentDate = newEndDate;
          }
          return true;
        }
        return false;
      },
      widgetBuilder: (context) {
        final isLight = context.isLightTheme;
        return Column(
          children: [
            // Shared 3-tab bar for all itinerary sub-sections
            BubbleTabBar(
              controller: _tabController,
              height: 46,
              showLabels: true,
              tabs: [
                BubbleTabData(
                  icon: Icons.timeline,
                  label: context.localizations.timeline,
                  semanticLabel: context.localizations.timeline,
                ),
                BubbleTabData(
                  icon: Icons.sticky_note_2_rounded,
                  label: context.localizations.notes,
                  semanticLabel: context.localizations.notes,
                ),
                BubbleTabData(
                  icon: Icons.place_outlined,
                  label: context.localizations.places,
                  semanticLabel: context.localizations.places,
                ),
              ],
            ),
            DateStrip(
              startDate: _startDate,
              endDate: _endDate,
              selectedDate: _currentDate,
              onDateSelected: _tryNavigateToDate,
            ),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ColoredBox(
                    color: isLight
                        ? AppColors.lightBackground
                        : AppColors.darkSurfaceVariant,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab 0 – Timeline
                        ItineraryViewer(itineraryDay: _currentDate),
                        // Tab 1 – Notes + Checklists combined
                        ItineraryNotesAndChecklistsViewer(day: _currentDate),
                        // Tab 2 – Sights / Places
                        ItinerarySightsViewer(
                          tripId: context.activeTripId,
                          day: _currentDate,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _tryNavigateToDate(DateTime newDate) {
    if (newDate.isBefore(_startDate) || newDate.isAfter(_endDate)) {
      return;
    }
    setState(() {
      _currentDate = newDate;
      _animationController
        ..reset()
        ..forward();
    });
    widget.onNavigatedToDate(_currentDate);
  }
}
