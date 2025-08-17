import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/asset_manager/assets.gen.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/store/models/collection_item_change_metadata.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/presentation/app/bloc/bloc_extensions.dart';
import 'package:wandrr/presentation/app/widgets/button.dart';
import 'package:wandrr/presentation/app/widgets/card.dart';
import 'package:wandrr/presentation/app/widgets/date_range_pickers.dart';
import 'package:wandrr/presentation/trip/bloc/bloc.dart';
import 'package:wandrr/presentation/trip/bloc/events.dart';
import 'package:wandrr/presentation/trip/bloc/states.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/navigation/constants.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/navigation/trip_navigator.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/flip_card/flip_card.dart';

import 'trip_contributor_details.dart';

const double _heightOfContributorWidget = 20.0;
const double _maxOverviewElementHeight = 50.0;

class TripOverviewTile extends StatelessWidget {
  static const _imageHeight = 250.0;

  const TripOverviewTile({super.key});

  @override
  Widget build(BuildContext context) {
    var activeTrip = context.activeTrip;
    var numberOfContributors = activeTrip.tripMetadata.contributors.length;
    var isBigLayout = context.isBigLayout;
    var heightOfOverViewTile =
        _calculateOverViewTileSize(isBigLayout, numberOfContributors);
    return BlocListener<TripManagementBloc, TripManagementState>(
      listenWhen: (previousState, currentState) {
        return currentState is ProcessSectionNavigation &&
            currentState.section == NavigationSections.tripOverview;
      },
      listener: (BuildContext context, TripManagementState state) {
        if (state is ProcessSectionNavigation &&
            state.section == NavigationSections.tripOverview) {
          RepositoryProvider.of<TripNavigator>(context).jumpToList(context);
        }
      },
      child: Stack(
        fit: StackFit.passthrough,
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              Assets.images.planningTheTrip.image(
                fit: isBigLayout ? BoxFit.fill : BoxFit.contain,
                height: TripOverviewTile._imageHeight,
              ),
              SizedBox(
                height: heightOfOverViewTile,
              ),
            ],
          ),
          const Positioned(
            left: 10,
            right: 10,
            top: 200,
            child: _OverviewTile(),
          )
        ],
      ),
    );
  }

  double _calculateOverViewTileSize(
      bool isBigLayout, int numberOfContributors) {
    var overviewTileSize = 3 * _maxOverviewElementHeight +
        numberOfContributors * (_heightOfContributorWidget + 10) +
        _maxOverviewElementHeight;
    if (!isBigLayout) {
      overviewTileSize += _maxOverviewElementHeight + 30;
    }
    return overviewTileSize;
  }
}

class _OverviewTile extends StatelessWidget {
  const _OverviewTile();

  @override
  Widget build(BuildContext context) {
    var activeTrip = context.activeTrip;
    var overViewTile = PlatformCard(
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
              child: _buildOverviewTile(context),
            ),
          ],
        ),
      ),
    );
    return FlipCard(
      fill: Fill.back,
      direction: Axis.vertical,
      duration: const Duration(milliseconds: 750),
      autoFlipDuration: const Duration(seconds: 0),
      front: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: overViewTile,
      ),
      back: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: overViewTile,
      ),
    );
  }

  Widget _buildOverviewTile(BuildContext context) {
    var activeTrip = context.activeTrip;
    var isBigLayout = context.isBigLayout;
    return !isBigLayout
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3.0),
                child: SizedBox(
                  height: _maxOverviewElementHeight,
                  child: _buildDateRangeButton(
                      context, activeTrip.tripMetadata, isBigLayout),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5.0),
                child: ContributorDetails(
                    contributors: activeTrip.tripMetadata.contributors,
                    heightOfContributorWidget: _heightOfContributorWidget,
                    maxOverviewElementHeight: _maxOverviewElementHeight),
              ),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                  child: _buildDateRangeButton(
                      context, activeTrip.tripMetadata, isBigLayout),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                  child: ContributorDetails(
                      contributors: activeTrip.tripMetadata.contributors,
                      heightOfContributorWidget: _heightOfContributorWidget,
                      maxOverviewElementHeight: _maxOverviewElementHeight),
                ),
              ),
            ],
          );
  }

  Widget _buildTitleEditingField(
      TripDataFacade activeTrip, BuildContext context) {
    var activeTripTitle = activeTrip.tripMetadata.name;
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: (previousState, currentState) {
        if (currentState.isTripEntityUpdated<TripMetadataFacade>()) {
          var updatedTripEntity = currentState as UpdatedTripEntity;
          var tripMetadataModificationData =
              updatedTripEntity.tripEntityModificationData
                  as CollectionItemChangeMetadata<TripMetadataFacade>;
          if (tripMetadataModificationData.modifiedCollectionItem.name !=
              activeTripTitle) {
            activeTripTitle =
                tripMetadataModificationData.modifiedCollectionItem.name;
            return true;
          }
        }
        return false;
      },
      builder: (BuildContext context, TripManagementState state) {
        var titleEditingController =
            TextEditingController(text: activeTripTitle);
        var titleValidityNotifier = ValueNotifier<bool>(false);
        return TextField(
          controller: titleEditingController,
          onChanged: (newTitle) {
            var shouldDisableButton = false;
            if (newTitle.length <= 5 || newTitle == activeTripTitle) {
              shouldDisableButton = true;
            }
            titleValidityNotifier.value = !shouldDisableButton;
          },
          decoration: InputDecoration(
            suffixIcon: Padding(
              padding: const EdgeInsets.all(3.0),
              child: PlatformSubmitterFAB.conditionallyEnabled(
                icon: Icons.check_rounded,
                isSubmitted: false,
                context: context,
                isElevationRequired: false,
                callback: () {
                  var tripMetadataModelFacade = activeTrip.tripMetadata;
                  tripMetadataModelFacade.name = titleEditingController.text;
                  context.addTripManagementEvent(
                      UpdateTripEntity<TripMetadataFacade>.update(
                          tripEntity: tripMetadataModelFacade));
                },
                valueNotifier: titleValidityNotifier,
              ),
            ),
          ),
        );
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }

  Widget _buildDateRangeButton(
      BuildContext context, TripMetadataFacade tripMetadata, bool isBigLayout) {
    var startDate = tripMetadata.startDate;
    var endDate = tripMetadata.endDate;
    return PlatformFABDateRangePicker(
      startDate: startDate,
      endDate: endDate,
      firstDate: DateTime.now(),
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
