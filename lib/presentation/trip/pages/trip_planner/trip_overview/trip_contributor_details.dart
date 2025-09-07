import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/store/models/collection_item_change_metadata.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/constants.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

import 'add_tripmate_button.dart';

class ContributorDetails extends StatelessWidget {
  final List<String> contributors;
  final double heightOfContributorWidget;
  final double maxOverviewElementHeight;

  ContributorDetails(
      {required Iterable<String> contributors,
      required this.heightOfContributorWidget,
      required this.maxOverviewElementHeight,
      super.key})
      : contributors = contributors.toList();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: _shouldBuildContributorDetails,
      builder: (BuildContext context, TripManagementState state) {
        var contributorWidgets = _createContributorWidgets(context);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.0),
              child: SizedBox(
                height: maxOverviewElementHeight,
                child: const AddTripMateField(),
              ),
            ),
            ...contributorWidgets
          ],
        );
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }

  bool _shouldBuildContributorDetails(
      TripManagementState previousState, TripManagementState currentState) {
    if (currentState.isTripEntityUpdated<TripMetadataFacade>()) {
      var updatedTripEntity = currentState as UpdatedTripEntity;
      if (updatedTripEntity.dataState == DataState.update) {
        var tripMetadataModificationData =
            updatedTripEntity.tripEntityModificationData
                as CollectionItemChangeMetadata<TripMetadataFacade>;
        var latestContributors =
            tripMetadataModificationData.modifiedCollectionItem.contributors;
        if (!listEquals(latestContributors, contributors)) {
          return true;
        }
      }
    }
    return false;
  }

  Iterable<Widget> _createContributorWidgets(BuildContext context) {
    contributors.clear();
    contributors.addAll(context.activeTrip.tripMetadata.contributors);
    contributors.sort((a, b) => a.compareTo(b));
    var contributorsVsColors = <String, Color>{};
    for (var index = 0; index < contributors.length; index++) {
      var contributor = contributors.elementAt(index);
      contributorsVsColors[contributor] =
          AppColors.travelAccents.elementAt(index);
    }
    return contributorsVsColors.entries.map(
      (e) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.0),
        child: TextButton.icon(
            onPressed: null,
            icon: Container(
              width: 20,
              height: heightOfContributorWidget,
              decoration: BoxDecoration(
                color: e.value,
                shape: BoxShape.circle,
              ),
            ),
            label: FittedBox(child: Text(e.key))) as Widget,
      ),
    );
  }
}
