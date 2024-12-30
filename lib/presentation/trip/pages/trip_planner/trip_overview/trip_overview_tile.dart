import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/data/app/app_data_repository_extensions.dart';
import 'package:wandrr/data/app/models/collection_change_metadata.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/data/trip/trip_repository_extensions.dart';
import 'package:wandrr/presentation/app/blocs/bloc_extensions.dart';
import 'package:wandrr/presentation/app/widgets/button.dart';
import 'package:wandrr/presentation/app/widgets/date_range_pickers.dart';
import 'package:wandrr/presentation/trip/bloc/bloc.dart';
import 'package:wandrr/presentation/trip/bloc/events.dart';
import 'package:wandrr/presentation/trip/bloc/states.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/constants.dart';

import 'add_tripmate_button.dart';

const double _heightOfContributorWidget = 20.0;
const double _maxOverviewElementHeight = 50.0;

class TripOverviewTile extends StatelessWidget {
  TripOverviewTile({Key? key}) : super(key: key);

  static const _imageHeight = 250.0;
  static const _assetImage = 'assets/images/planning_the_trip.jpg';

  @override
  Widget build(BuildContext context) {
    var activeTrip = context.activeTrip;
    var numberOfContributors = activeTrip.tripMetadata.contributors.length;
    var isBigLayout = context.isBigLayout;
    var heightOfOverViewTile =
        _calculateOverViewTileSize(isBigLayout, numberOfContributors);
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
              height: heightOfOverViewTile,
            ),
          ],
        ),
        Positioned(
          left: 10,
          right: 10,
          top: isBigLayout ? 230 : 220,
          child: _TripOverviewTile(),
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
      overviewTileSize += _maxOverviewElementHeight + 30;
    }
    return overviewTileSize;
  }
}

class _TripOverviewTile extends StatefulWidget {
  const _TripOverviewTile({super.key});

  @override
  State<_TripOverviewTile> createState() => _TripOverviewTileState();
}

class _TripOverviewTileState extends State<_TripOverviewTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _swayAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _swayAnimation = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: -pi / 8)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 1.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -pi / 8, end: pi / 8)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: pi / 8, end: -pi / 8)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -pi / 8, end: 0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 1.0,
      ),
    ]).animate(_controller);

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    var activeTrip = context.activeTrip;
    _controller.forward();
    return AnimatedBuilder(
      animation: _swayAnimation,
      builder: (context, child) {
        final double angle = _swayAnimation.value;
        final double scale = 1 / cos(angle); // Adjust scale to maintain size

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Perspective
            ..rotateY(angle), // Rotate around vertical axis
          alignment: Alignment.center,
          child: Transform.scale(
            scale: scale, // Scale the card appropriately
            child: child,
          ),
        );
      },
      child: Padding(
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
                  child: _buildOverviewTile(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildOverviewTile() {
    var activeTrip = context.activeTrip;
    var isBigLayout = context.isBigLayout;
    return !isBigLayout
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: SizedBox(
                    height: _maxOverviewElementHeight,
                    child: _buildDateRangeButton(
                        context, activeTrip.tripMetadata, isBigLayout),
                  ),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: _ContributorDetails(
                      contributors: activeTrip.tripMetadata.contributors),
                ),
              ),
            ],
          )
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: Row(
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
                    child: _ContributorDetails(
                        contributors: activeTrip.tripMetadata.contributors),
                  ),
                ),
              ],
            ),
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
                  as CollectionChangeMetadata<TripMetadataFacade>;
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

class _ContributorDetails extends StatelessWidget {
  List<String> contributors;
  static const double _heightOfContributorWidget = 20.0;
  static const double _maxOverviewElementHeight = 50.0;

  _ContributorDetails({super.key, required Iterable<String> contributors})
      : contributors = contributors.toList();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: (previousState, currentState) {
        if (currentState.isTripEntityUpdated<TripMetadataFacade>()) {
          var updatedTripEntity = currentState as UpdatedTripEntity;
          if (updatedTripEntity.dataState == DataState.Update) {
            var tripMetadataModificationData =
                updatedTripEntity.tripEntityModificationData
                    as CollectionChangeMetadata<TripMetadataFacade>;
            var latestContributors = tripMetadataModificationData
                .modifiedCollectionItem.contributors;
            if (!listEquals(latestContributors, contributors)) {
              contributors = latestContributors;
              return true;
            }
          }
        }
        return false;
      },
      builder: (BuildContext context, TripManagementState state) {
        contributors.sort((a, b) => a.compareTo(b));
        var contributorsVsColors = <String, Color>{};
        for (var index = 0; index < contributors.length; index++) {
          var contributor = contributors.elementAt(index);
          contributorsVsColors[contributor] =
              contributorColors.elementAt(index);
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
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }
}
