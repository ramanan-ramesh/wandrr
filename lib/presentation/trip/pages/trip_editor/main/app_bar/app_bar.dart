import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/presentation/app/routing/app_router.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/print_trip_dialog.dart';
import 'package:wandrr/presentation/trip/widgets/trip_entity_update_handler.dart';

import 'collaborator_list.dart';

class TripEditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

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
    showDialog(
      context: pageContext,
      builder: (_) => PrintTripDialog(
        tripData: pageContext.activeTrip,
      ),
    );
  }

  void _selectTripMetadata(BuildContext context) {
    context.addTripManagementEvent(UpdateTripEntity<TripMetadataFacade>.select(
        tripEntity: context.activeTrip.tripMetadata));
  }
}
