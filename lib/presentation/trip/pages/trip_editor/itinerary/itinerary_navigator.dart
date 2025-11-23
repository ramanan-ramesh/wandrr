import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/presentation/app/widgets/date_picker.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/itinerary_viewer.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/trip_entity_update_handler.dart';

class ItineraryNavigator extends StatefulWidget {
  const ItineraryNavigator({super.key});

  @override
  State<ItineraryNavigator> createState() => _ItineraryNavigatorState();
}

class _ItineraryNavigatorState extends State<ItineraryNavigator>
    with SingleTickerProviderStateMixin {
  static const double _kNavBarHorizontalPadding = 8.0;
  static const double _kNavBarVerticalPadding = 12.0;
  static const double _kNavBarIconSize = 32.0;
  static const Duration _kAnimationDuration = Duration(milliseconds: 400);
  static const Offset _kSlideBeginOffset = Offset(0.1, 0);
  static const Curve _kFadeCurve = Curves.easeInOut;
  static const Curve _kSlideCurve = Curves.easeOutCubic;

  late DateTime _currentDate;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  DateTime get _startDate => context.activeTrip.tripMetadata.startDate!;

  DateTime get _endDate => context.activeTrip.tripMetadata.endDate!;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: _kAnimationDuration,
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: _kFadeCurve,
    );

    _slideAnimation = Tween<Offset>(
      begin: _kSlideBeginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: _kSlideCurve,
    ));

    _currentDate = _startDate;
    _animationController.forward();
  }

  @override
  void dispose() {
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
        return Column(
          children: [
            _buildNavigationBar(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ItineraryViewer(itineraryDay: _currentDate),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  bool _tryNavigateToDate(DateTime newDate) {
    if (newDate.isBefore(_startDate) || newDate.isAfter(_endDate)) {
      return false;
    }
    setState(() {
      _currentDate = newDate;
      _animationController
        ..reset()
        ..forward();
    });
    return true;
  }

  void _goToPreviousDay() =>
      _tryNavigateToDate(_currentDate.subtract(const Duration(days: 1)));

  void _goToNextDay() =>
      _tryNavigateToDate(_currentDate.add(const Duration(days: 1)));

  Widget _buildNavigationBar() {
    final bool canGoPrevious = _currentDate.isAfter(_startDate);
    final bool canGoNext = _currentDate.isBefore(_endDate);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _kNavBarHorizontalPadding,
        vertical: _kNavBarVerticalPadding,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            iconSize: _kNavBarIconSize,
            onPressed: canGoPrevious ? _goToPreviousDay : null,
          ),
          Expanded(
            child: Center(child: _buildDatePickerButton()),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            iconSize: _kNavBarIconSize,
            onPressed: canGoNext ? _goToNextDay : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerButton() {
    return PlatformDatePicker(
      widgetAnchor: Alignment.bottomCenter,
      dialogAnchor: Alignment.topCenter,
      onDateSelected: _tryNavigateToDate,
      selectedDate: _currentDate,
      calendarConfig: CalendarDatePicker2WithActionButtonsConfig(
        firstDate: _startDate,
        lastDate: _endDate,
        currentDate: _currentDate,
      ),
    );
  }
}
