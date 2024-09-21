import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/app_data/models/collection_change_metadata.dart';
import 'package:wandrr/app_data/platform_data_repository_extensions.dart';
import 'package:wandrr/app_presentation/blocs/bloc_extensions.dart';
import 'package:wandrr/app_presentation/widgets/button.dart';
import 'package:wandrr/app_presentation/widgets/date_range_pickers.dart';
import 'package:wandrr/trip_data/models/trip_data.dart';
import 'package:wandrr/trip_data/models/trip_metadata.dart';
import 'package:wandrr/trip_data/trip_repository_extensions.dart';
import 'package:wandrr/trip_presentation/pages/trip_planner_page/constants.dart';
import 'package:wandrr/trip_presentation/trip_management_bloc/bloc.dart';
import 'package:wandrr/trip_presentation/trip_management_bloc/events.dart';
import 'package:wandrr/trip_presentation/trip_management_bloc/states.dart';

import 'add_tripmate_button.dart';

class TripOverviewTile extends StatelessWidget {
  TripOverviewTile({Key? key}) : super(key: key);

  static const double _heightOfContributorWidget = 20.0;
  static const double _maxOverviewElementHeight = 50.0;
  static const _imageHeight = 250.0;
  static const _assetImage = 'assets/images/planning_the_trip.jpg';

  @override
  Widget build(BuildContext context) {
    var activeTrip = context.getActiveTrip();
    var numberOfContributors = activeTrip.tripMetadata.contributors.length;
    var isBigLayout = context.isBigLayout();

    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        Column(
          children: [
            Image.asset(
              _assetImage,
              fit: isBigLayout ? BoxFit.fill : BoxFit.contain,
              height: _imageHeight,
            ),
            SizedBox(
              height:
                  _calculateOverViewTileSize(isBigLayout, numberOfContributors),
            ),
          ],
        ),
        Positioned(
          left: 10,
          right: 10,
          top: isBigLayout ? 230 : 220,
          child: _buildOverviewTile(context, activeTrip, isBigLayout),
        )
      ],
    );
  }

  double _calculateOverViewTileSize(
      bool isBigLayout, int numberOfContributors) {
    var overviewTileSize = 2 * _maxOverviewElementHeight +
        numberOfContributors * (_heightOfContributorWidget + 10) +
        50;
    if (!isBigLayout) {
      overviewTileSize += _maxOverviewElementHeight;
    }
    return overviewTileSize;
  }

  Padding _buildOverviewTile(
      BuildContext context, TripDataFacade activeTrip, bool isBigLayout) {
    var orientedWidget = !isBigLayout
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SizedBox(
                  height: _maxOverviewElementHeight,
                  child: _buildDateRangeButton(
                      context, activeTrip.tripMetadata, isBigLayout),
                ),
              ),
              Flexible(child: _buildSplitByIcons(activeTrip.tripMetadata))
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: _buildDateRangeButton(
                    context, activeTrip.tripMetadata, isBigLayout),
              ),
              Flexible(child: _buildSplitByIcons(activeTrip.tripMetadata))
            ],
          );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              SizedBox(
                height: _maxOverviewElementHeight,
                child: _buildTitleEditingField(activeTrip, context),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: orientedWidget,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleEditingField(
      TripDataFacade activeTrip, BuildContext context) {
    var activeTripTitle = activeTrip.tripMetadata.name;
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: (previousState, currentState) {
        if (currentState.isTripEntity<TripMetadataFacade>()) {
          var updatedTripEntity = currentState as UpdatedTripEntity;
          var tripMetadataModificationData =
              updatedTripEntity.tripEntityModificationData
                  as CollectionChangeMetadata<TripMetadataFacade>;
          if (tripMetadataModificationData.modifiedCollectionItem.name !=
              activeTripTitle) {
            return true;
          }
        }
        return false;
      },
      builder: (BuildContext context, TripManagementState state) {
        if (state.isTripEntity<TripMetadataFacade>()) {
          var updatedTripEntity = state as UpdatedTripEntity;
          var tripMetadataModificationData =
              updatedTripEntity.tripEntityModificationData
                  as CollectionChangeMetadata<TripMetadataFacade>;
          activeTripTitle =
              tripMetadataModificationData.modifiedCollectionItem.name;
        }
        var titleEditingController =
            TextEditingController(text: activeTripTitle);
        return TextField(
          controller: titleEditingController,
          decoration: InputDecoration(
              suffixIcon: Padding(
            padding: const EdgeInsets.all(3.0),
            child: PlatformSubmitterFAB(
              icon: Icons.check_rounded,
              isSubmitted: false,
              context: context,
              callback: () {
                var tripMetadataModelFacade = activeTrip.tripMetadata;
                tripMetadataModelFacade.name = titleEditingController.text;
                context.addTripManagementEvent(
                    UpdateTripEntity<TripMetadataFacade>.update(
                        tripEntity: tripMetadataModelFacade));
              },
            ),
          )),
        );
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }

  Widget _buildSplitByIcons(TripMetadataFacade tripMetadata) {
    var contributors = tripMetadata.contributors.toList();
    contributors.sort((a, b) => a.compareTo(b));
    var contributorsVsColors = <String, Color>{};
    for (var index = 0; index < contributors.length; index++) {
      var contributor = contributors.elementAt(index);
      contributorsVsColors[contributor] = contributorColors.elementAt(index);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: contributorsVsColors.entries
          .map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3.0),
                child: TextButton.icon(
                    onPressed: null,
                    icon: Container(
                      width: 20,
                      height: _heightOfContributorWidget,
                      decoration: BoxDecoration(
                        color: e.value,
                        shape: BoxShape.circle,
                      ),
                    ),
                    label: FittedBox(child: Text(e.key))) as Widget,
              ))
          .toList()
        ..insert(
          0,
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: SizedBox(
              height: _maxOverviewElementHeight,
              child: AddTripMateField(),
            ),
          ),
        ),
    );
  }

  Widget _buildDateRangeButton(
      BuildContext context, TripMetadataFacade tripMetadata, bool isBigLayout) {
    var startDate = tripMetadata.startDate;
    var endDate = tripMetadata.endDate;
    return PlatformFABDateRangePicker(
      startDate: startDate,
      endDate: endDate,
      callback: (startDate, endDate) {
        if (startDate != null && endDate != null) {
          tripMetadata.startDate = startDate;
          tripMetadata.endDate = endDate;
          context.addTripManagementEvent(
              UpdateTripEntity<TripMetadataFacade>.update(
                  tripEntity: tripMetadata));
        }
      },
    );
  }
}
