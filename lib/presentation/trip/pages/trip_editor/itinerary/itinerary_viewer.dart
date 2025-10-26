import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/l10n/extension.dart';

class ItineraryViewer extends StatefulWidget {
  const ItineraryViewer({super.key});

  @override
  State<ItineraryViewer> createState() => _ItineraryViewerState();
}

class _ItineraryViewerState extends State<ItineraryViewer>
    with SingleTickerProviderStateMixin {
  DateTime _currentDate = DateTime.now();
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

  void _navigateToDate(DateTime newDate) {
    setState(() {
      _currentDate = newDate;
      _animationController.reset();
      _animationController.forward();
    });
  }

  void _goToPreviousDay() {
    _navigateToDate(_currentDate.subtract(const Duration(days: 1)));
  }

  void _goToNextDay() {
    _navigateToDate(_currentDate.add(const Duration(days: 1)));
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildNavigationBar(context)),
        const SliverToBoxAdapter(child: Divider(height: 1, thickness: 1)),
        SliverFillRemaining(
          hasScrollBody: true,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildItineraryContent(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationBar(BuildContext context) {
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
            onPressed: _goToPreviousDay,
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
            onPressed: _goToNextDay,
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
    showDatePicker(
      context: context,
      initialDate: _currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    ).then((selectedDate) {
      if (selectedDate != null) {
        _navigateToDate(selectedDate);
      }
    });
  }

  Widget _buildItineraryContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context,
            icon: Icons.bed_rounded,
            title: context.localizations.lodging,
          ),
          const SizedBox(height: 8),
          _buildLodgingCard(context),
          const SizedBox(height: 24),
          _buildSectionHeader(
            context,
            icon: Icons.directions_transit_rounded,
            title: context.localizations.transit,
          ),
          const SizedBox(height: 8),
          _buildTransitsCard(context),
          const SizedBox(height: 24),
          _buildSectionHeader(
            context,
            icon: Icons.list_alt_rounded,
            title: 'Trip Data',
          ),
          const SizedBox(height: 8),
          _buildPlanDataCard(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context,
      {required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withAlpha(51),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildLodgingCard(BuildContext context) {
    // Placeholder for lodging information
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.hotel_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sample Hotel Name',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Check-in: 3:00 PM',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Check-out: 11:00 AM',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: const Text('Full Day'),
                  avatar: const Icon(Icons.check_circle, size: 18),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransitsCard(BuildContext context) {
    // Placeholder for transit information
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTransitItem(
              context,
              icon: Icons.flight_rounded,
              from: 'New York (JFK)',
              to: 'London (LHR)',
              time: '8:00 AM - 8:00 PM',
            ),
            const Divider(height: 24),
            _buildTransitItem(
              context,
              icon: Icons.train_rounded,
              from: 'London Station',
              to: 'Paris Station',
              time: '9:00 AM - 11:30 AM',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransitItem(BuildContext context,
      {required IconData icon,
      required String from,
      required String to,
      required String time}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      from,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      to,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(179),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlanDataCard(BuildContext context) {
    // Placeholder for plan data information
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Plan',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            _buildPlanItem(
              context,
              icon: Icons.restaurant_rounded,
              title: 'Lunch at Italian Restaurant',
              time: '12:30 PM',
            ),
            const SizedBox(height: 8),
            _buildPlanItem(
              context,
              icon: Icons.museum_rounded,
              title: 'Visit Art Museum',
              time: '2:00 PM',
            ),
            const SizedBox(height: 8),
            _buildPlanItem(
              context,
              icon: Icons.shopping_bag_rounded,
              title: 'Shopping at Market',
              time: '5:00 PM',
            ),
            const SizedBox(height: 16),
            Text(
              'Notes',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Remember to bring camera for museum visit. Check weather forecast for evening.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanItem(BuildContext context,
      {required IconData icon, required String title, required String time}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          time,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
              ),
        ),
      ],
    );
  }
}
