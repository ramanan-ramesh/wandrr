import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wandrr/asset_manager/assets.gen.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/bloc/bloc_extensions.dart';
import 'package:wandrr/presentation/app/widgets/dialog.dart';
import 'package:wandrr/presentation/app/widgets/text.dart';
import 'package:wandrr/presentation/trip/bloc/bloc.dart';
import 'package:wandrr/presentation/trip/bloc/events.dart';
import 'package:wandrr/presentation/trip/bloc/states.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/delete_trip_dialog.dart';

class TripListView extends StatelessWidget {
  final List<AssetGenImage> _tripPlanningImageAssets = [
    Assets.images.tripPlanning1,
    Assets.images.tripPlanning2,
    Assets.images.tripPlanning3,
  ];

  TripListView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: (previousState, currentState) {
        if (currentState.isTripEntityUpdated<TripMetadataFacade>()) {
          var tripMetadataUpdatedState = currentState as UpdatedTripEntity;
          if (tripMetadataUpdatedState.dataState == DataState.delete ||
              tripMetadataUpdatedState.dataState == DataState.create) {
            return true;
          }
        }
        return false;
      },
      listener: (context, state) {},
      builder: (context, state) {
        var tripMetadatas = context.tripRepository.tripMetadatas
          ..sort((tripMetadata1, tripMetadata2) =>
              tripMetadata1.startDate!.compareTo(tripMetadata2.startDate!));
        if (tripMetadatas.isNotEmpty) {
          return _generateTripMetadataGrid(context, tripMetadatas);
        } else {
          return Align(
            alignment: Alignment.center,
            child: PlatformTextElements.createSubHeader(
              context: context,
              text: context.localizations.noTripsCreated,
            ),
          );
        }
      },
    );
  }

  Widget _generateTripMetadataGrid(
      BuildContext context, List<TripMetadataFacade> tripMetadatas) {
    var imageAssets = _generateRandomImages(tripMetadatas.length);
    var tripMetadataGridItems = <_TripMetadataGridItem>[];
    for (var index = 0; index < tripMetadatas.length; index++) {
      var imageAsset = imageAssets[index];
      var tripMetadataFacade = tripMetadatas[index];
      tripMetadataGridItems.add(_TripMetadataGridItem(
        tripMetaDataFacade: tripMetadataFacade,
        imageAsset: imageAsset,
      ));
    }
    return GridView.extent(
      maxCrossAxisExtent: 300,
      mainAxisSpacing: 7,
      crossAxisSpacing: 7,
      childAspectRatio: 0.7,
      children: tripMetadataGridItems,
    );
  }

  List<AssetGenImage> _generateRandomImages(int numberOfTripMetadatas) {
    List<AssetGenImage> tempImages = List.from(_tripPlanningImageAssets);
    Random random = Random();
    var gridImages = <AssetGenImage>[];
    for (int i = 0; i < numberOfTripMetadatas; i++) {
      tempImages.shuffle(random);
      gridImages.add(tempImages[i % 3]);
    }
    return gridImages;
  }
}

class _TripMetadataGridItem extends StatelessWidget {
  final _dateFormat = DateFormat.MMMEd();

  _TripMetadataGridItem(
      {required this.tripMetaDataFacade, required this.imageAsset});

  TripMetadataFacade tripMetaDataFacade;
  final AssetGenImage imageAsset;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      builder: (BuildContext context, TripManagementState state) {
        var subTitle =
            '${_dateFormat.format(tripMetaDataFacade.startDate!)} to ${_dateFormat.format(tripMetaDataFacade.endDate!)}';
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () {
              context.addTripManagementEvent(
                  LoadTrip(tripMetadata: tripMetaDataFacade));
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    imageAsset.image(fit: BoxFit.cover),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: context.isLightTheme
                                ? [Colors.teal.shade50, Colors.teal.shade500]
                                : [Colors.white70, Colors.black],
                            stops: const [0, 1],
                          ),
                        ),
                        child: FittedBox(
                          child: Text(
                            subTitle,
                            style: TextStyle(
                              fontSize: Theme.of(context)
                                  .textTheme
                                  .labelMedium!
                                  .fontSize,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Card(
                  shape: const StadiumBorder(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            tripMetaDataFacade.name,
                            style: TextStyle(
                                fontSize: Theme.of(context)
                                    .textTheme
                                    .titleSmall!
                                    .fontSize,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3.0),
                          child: IconButton(
                            onPressed: () {
                              _showDeleteTripConfirmationDialog(context);
                            },
                            icon: const Icon(Icons.delete_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
      listener: (BuildContext context, TripManagementState state) {},
      buildWhen: (previousState, currentState) {
        if (currentState.isTripEntityUpdated<TripMetadataFacade>()) {
          var tripMetadataUpdatedState = currentState as UpdatedTripEntity;
          if (tripMetadataUpdatedState
                  .tripEntityModificationData.modifiedCollectionItem.id ==
              tripMetaDataFacade.id) {
            tripMetaDataFacade = tripMetadataUpdatedState
                .tripEntityModificationData.modifiedCollectionItem;
            return true;
          }
        }
        return false;
      },
    );
  }

  void _showDeleteTripConfirmationDialog(BuildContext pageContext) {
    PlatformDialogElements.showAlertDialog(pageContext, (context) {
      return DeleteTripDialog(
          widgetContext: pageContext, tripMetadataFacade: tripMetaDataFacade);
    });
  }
}
