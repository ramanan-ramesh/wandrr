import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/stay_and_transits.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

class ItineraryViewer extends StatefulWidget {
  const ItineraryViewer({super.key});

  @override
  State<ItineraryViewer> createState() => _ItineraryViewerState();
}

class _ItineraryViewerState extends State<ItineraryViewer>
    with SingleTickerProviderStateMixin {
  late DateTime _currentDate;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _currentDate = context.activeTrip.tripMetadata.startDate!;
    return Column(
      children: [
        _buildNavigationBar(context),
        FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ItineraryStayAndTransits(itineraryDay: _currentDate),
          ),
        )
      ],
    );
  }

  void _navigateToDate(DateTime newDate) {
    setState(() {
      _currentDate = newDate;
      _animationController.reset();
      _animationController.forward();
    });
  }

  void _goToPreviousDay() {
    final startDate = context.activeTrip.tripMetadata.startDate;
    if (startDate == null) return;

    final previousDate = _currentDate.subtract(const Duration(days: 1));
    if (!previousDate.isBefore(startDate)) {
      _navigateToDate(previousDate);
    }
  }

  void _goToNextDay() {
    final endDate = context.activeTrip.tripMetadata.endDate;
    if (endDate == null) return;

    final nextDate = _currentDate.add(const Duration(days: 1));
    if (!nextDate.isAfter(endDate)) {
      _navigateToDate(nextDate);
    }
  }

  bool _canGoToPreviousDay() {
    final startDate = context.activeTrip.tripMetadata.startDate;
    if (startDate == null) return false;
    return !_currentDate.isAtSameMomentAs(startDate) &&
        _currentDate.isAfter(startDate);
  }

  bool _canGoToNextDay() {
    final endDate = context.activeTrip.tripMetadata.endDate;
    if (endDate == null) return false;
    return !_currentDate.isAtSameMomentAs(endDate) &&
        _currentDate.isBefore(endDate);
  }

  Widget _buildNavigationBar(BuildContext context) {
    final canGoPrevious = _canGoToPreviousDay();
    final canGoNext = _canGoToNextDay();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'Previous',
            iconSize: 32,
            onPressed: canGoPrevious ? _goToPreviousDay : null,
          ),
          Expanded(
            child: Center(
              child: _buildDatePickerButton(context),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: 'Next',
            iconSize: 32,
            onPressed: canGoNext ? _goToNextDay : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerButton(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showDatePickerDialog(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).colorScheme.primaryContainer.withAlpha(200),
              ],
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 12),
              Text(
                _currentDate.dayDateMonthFormat,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDatePickerDialog(BuildContext context) {
    final startDate = context.activeTrip.tripMetadata.startDate;
    final endDate = context.activeTrip.tripMetadata.endDate;

    if (startDate == null || endDate == null) return;

    showDatePicker(
      helpText: 'Select a date to view itinerary',
      context: context,
      initialDate: _currentDate,
      firstDate: startDate,
      lastDate: endDate,
    ).then((selectedDate) {
      if (selectedDate != null) {
        _navigateToDate(selectedDate);
      }
    });
  }
}
