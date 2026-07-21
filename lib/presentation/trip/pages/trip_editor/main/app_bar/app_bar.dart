import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/presentation/app/routing/app_routes.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/bloc_extensions.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/trip_entity_update_handler.dart';

import 'collaborator_list.dart';

class TripEditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  // Extra 2 px for the animated loading bar at the bottom of the AppBar.
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 2);

  const TripEditorAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: _createHomeButton(context),
      centerTitle: false,
      title: _createTripDetails(context),
      actions: !context.isBigLayout
          ? [
              _createPrintButton(context),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 3.0),
                child: CollaboratorList(),
              ),
            ]
          : [
              _createPrintButton(context),
            ],
      // Thin animated progress bar at the bottom — visible only while the full
      // trip data is being fetched from Firestore.
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(2),
        child: StreamBuilder<bool>(
          stream: context.tripRepository.activeTrip!.isFullyLoaded,
          initialData: context.tripRepository.activeTrip!.isFullyLoadedValue,
          builder: (context, snapshot) {
            final isLoaded = snapshot.data ?? false;
            return AnimatedOpacity(
              opacity: isLoaded ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  context.isLightTheme
                      ? AppColors.brandPrimary.withValues(alpha: 0.55)
                      : AppColors.brandPrimaryLight.withValues(alpha: 0.55),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _createTripDetails(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: _createTitleAndDate(context),
        ),
        if (context.isBigLayout)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 3.0),
            child: CollaboratorList(),
          ),
      ],
    );
  }

  Widget _createTitleAndDate(BuildContext context) {
    return TripEntityUpdateHandler<TripMetadataFacade>(
      shouldRebuild: (beforeUpdate, afterUpdate) {
        final newStartDate = afterUpdate.startDate!;
        final newEndDate = afterUpdate.endDate!;
        return !beforeUpdate.startDate!.isOnSameDayAs(newStartDate) ||
            !beforeUpdate.endDate!.isOnSameDayAs(newEndDate) ||
            beforeUpdate.name != afterUpdate.name;
      },
      widgetBuilder: (context) {
        var tripDateRange =
            '${context.activeTrip.tripMetadata.startDate!.dateMonthFormat} - ${context.activeTrip.tripMetadata.endDate!.dateMonthFormat}';
        return InkWell(
          onTap: () => _selectTripMetadata(context),
          child: Padding(
            padding: const EdgeInsets.all(3.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  context.activeTrip.tripMetadata.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  tripDateRange,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _createHomeButton(BuildContext context) {
    return IconButton(
      onPressed: () {
        context.go(AppRoutes.trips);
      },
      icon: const Icon(Icons.home_rounded),
      style: context.isLightTheme
          ? const ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(AppColors.brandSecondary),
            )
          : null,
    );
  }

  Widget _createPrintButton(BuildContext context) {
    return IconButton(
      onPressed: () => _showPrintDialog(context),
      icon: const Icon(Icons.print_rounded),
      tooltip: 'Print trip',
      style: context.isLightTheme
          ? const ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(AppColors.brandSecondary),
            )
          : null,
    );
  }

  void _showPrintDialog(BuildContext pageContext) {
    final tripId = pageContext.activeTrip.tripMetadata.id;
    if (tripId == null) {
      return;
    }

    pageContext.go(
      AppRoutes.printTripPath(tripId),
      extra: AppRoutes.tripEditorPath(tripId),
    );
  }

  void _selectTripMetadata(BuildContext context) {
    context.addTripManagementEvent(UpdateTripEntity<TripMetadataFacade>.select(
        tripEntity: context.activeTrip.tripMetadata));
  }
}
