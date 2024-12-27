import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/data/trip/trip_repository_extensions.dart';
import 'package:wandrr/presentation/app/blocs/bloc_extensions.dart';
import 'package:wandrr/presentation/app/extensions.dart';
import 'package:wandrr/presentation/app/widgets/text.dart';
import 'package:wandrr/presentation/trip/bloc/bloc.dart';
import 'package:wandrr/presentation/trip/bloc/events.dart';
import 'package:wandrr/presentation/trip/bloc/states.dart';

class TripListView extends StatelessWidget {
  static const _tripPlanningImageAssets = [
    'assets/images/trip_planning_1.jpg',
    'assets/images/trip_planning_2.jpg',
    'assets/images/trip_planning_3.jpg'
  ];

  const TripListView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: (previousState, currentState) {
        if (currentState.isTripEntityUpdated<TripMetadataFacade>()) {
          var tripMetadataUpdatedState = currentState as UpdatedTripEntity;
          if (tripMetadataUpdatedState.dataState == DataState.Delete ||
              tripMetadataUpdatedState.dataState == DataState.Create) {
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
        onTripSelected: () {
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext dialogContext) {
                return BlocConsumer<TripManagementBloc, TripManagementState>(
                  bloc: BlocProvider.of<TripManagementBloc>(context),
                  listener: (context, state) {},
                  buildWhen: (previousState, currentState) {
                    return currentState is ActivatedTrip;
                  },
                  builder: (BuildContext context, TripManagementState state) {
                    if (state is ActivatedTrip) {
                      Navigator.of(dialogContext).pop();
                    }
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3.0),
                          child: Text(context.localizations.loadingTrip),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3.0),
                          child: CircularProgressIndicator(),
                        ),
                      ],
                    );
                  },
                );
              });
        },
      ));
    }
    return GridView.extent(
      maxCrossAxisExtent: 350,
      mainAxisSpacing: 7,
      crossAxisSpacing: 7,
      childAspectRatio: 0.7,
      children: tripMetadataGridItems,
    );
  }

  List<String> _generateRandomImages(int numberOfTripMetadatas) {
    List<String> tempImages = List.from(_tripPlanningImageAssets);
    Random random = Random();
    var gridImages = <String>[];
    for (int i = 0; i < numberOfTripMetadatas; i++) {
      if (i < numberOfTripMetadatas) {
        tempImages.shuffle(random);
        gridImages.add(tempImages[i % 3]);
      } else {
        List<String> remainingImages = List.from(_tripPlanningImageAssets);
        remainingImages.remove(gridImages[i - 1]);
        remainingImages.remove(gridImages[i - 2]);

        gridImages.add(remainingImages[random.nextInt(remainingImages.length)]);
      }
    }

    return gridImages;
  }
}

class _TripMetadataGridItem extends StatelessWidget {
  final _dateFormat = DateFormat.MMMEd();
  VoidCallback onTripSelected;

  _TripMetadataGridItem(
      {super.key,
      required this.tripMetaDataFacade,
      required String imageAsset,
      required this.onTripSelected})
      : imageAsset = AssetImage(imageAsset),
        imageAssetLocation = imageAsset;

  TripMetadataFacade tripMetaDataFacade;
  final String imageAssetLocation;
  final AssetImage imageAsset;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      builder: (BuildContext context, TripManagementState state) {
        var subTitle =
            '${_dateFormat.format(tripMetaDataFacade.startDate!)} to ${_dateFormat.format(tripMetaDataFacade.endDate!)}';
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Material(
            child: InkWell(
              onTap: () {
                onTripSelected();
                context.addTripManagementEvent(
                    LoadTrip(tripMetadata: tripMetaDataFacade));
              },
              child: Column(
                //TODO: There is empty space below the Column widget. Remove it
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      Image.asset(imageAssetLocation, fit: BoxFit.cover),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 3),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.black, Colors.black38],
                              stops: [0, 1],
                            ),
                          ),
                          child: FittedBox(
                            child: Text(
                              subTitle,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Card(
                    shape: StadiumBorder(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              tripMetaDataFacade.name,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3.0),
                            child: IconButton(
                              onPressed: () {
                                _buildDeleteTripConfirmationDialog(context);
                              },
                              icon: Icon(Icons.delete_rounded),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
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

  Future<Object?> _buildDeleteTripConfirmationDialog(BuildContext context) {
    return showGeneralDialog(
        context: context,
        pageBuilder: (BuildContext dialogContext, Animation<double> animation,
            Animation<double> secondaryAnimation) {
          return AlertDialog(
            title: Center(
              child: Text(
                  AppLocalizations.of(dialogContext)!.deleteTripConfirmation),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: Text(AppLocalizations.of(dialogContext)!.no),
              ),
              TextButton(
                onPressed: () {
                  context.addTripManagementEvent(
                      UpdateTripEntity<TripMetadataFacade>.delete(
                          tripEntity: tripMetaDataFacade));
                  Navigator.of(dialogContext).pop();
                },
                child: Text(AppLocalizations.of(dialogContext)!.yes),
              ),
            ],
          );
        });
  }
}
