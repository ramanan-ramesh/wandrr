import 'package:flutter/material.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/trip_entity_update_handler.dart';

import 'collaborator_list.dart';

class TripEditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  const TripEditorAppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: _createHomeButton(context),
      centerTitle: false,
      title: _createTripDetails(context),
      actions: !context.isBigLayout
          ? [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.0),
                child: CollaboratorList(),
              ),
            ]
          : [],
    );
  }

  Widget _createTripDetails(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: _createTitleAndDate(context),
        ),
        if (context.isBigLayout)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.0),
            child: CollaboratorList(),
          ),
      ],
    );
  }

  Widget _createTitleAndDate(BuildContext context) {
    var tripDateRange =
        '${context.activeTrip.tripMetadata.startDate!.dateMonthFormat} - ${context.activeTrip.tripMetadata.endDate!.dateMonthFormat}';
    return TripEntityUpdateHandler<TripMetadataFacade>(
      shouldRebuild: (beforeUpdate, afterUpdate) {
        final newStartDate = afterUpdate.startDate!;
        final newEndDate = afterUpdate.endDate!;
        if (!beforeUpdate.startDate!.isOnSameDayAs(newStartDate) ||
            !beforeUpdate.endDate!.isOnSameDayAs(newEndDate) ||
            beforeUpdate.name != afterUpdate.name) {
          return true;
        }
        return false;
      },
      widgetBuilder: (context) => InkWell(
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
      ),
    );
  }

  Widget _createHomeButton(BuildContext context) {
    return IconButton(
      onPressed: () {
        context.addTripManagementEvent(GoToHome());
      },
      icon: const Icon(Icons.home_rounded),
      style: context.isLightTheme
          ? ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(AppColors.brandSecondary),
            )
          : null,
    );
  }

  void _selectTripMetadata(BuildContext context) {
    context.addTripManagementEvent(UpdateTripEntity<TripMetadataFacade>.select(
        tripEntity: context.activeTrip.tripMetadata));
  }
}
