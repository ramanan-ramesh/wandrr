import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:wandrr/blocs/trip_management/bloc.dart';
import 'package:wandrr/blocs/trip_management/events.dart';
import 'package:wandrr/blocs/trip_management/states.dart';
import 'package:wandrr/contracts/data_states.dart';
import 'package:wandrr/contracts/trip_metadata.dart';
import 'package:wandrr/contracts/trip_repository.dart';
import 'package:wandrr/platform_elements/text.dart';

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
        if (currentState.isTripEntity<TripMetadataModelFacade>()) {
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
        print("TripsList-builder-${state}");
        var tripMetadatas =
            RepositoryProvider.of<TripRepositoryModelFacade>(context)
                .tripMetadatas
              ..sort((tripMetadata1, tripMetadata2) =>
                  tripMetadata1.startDate!.compareTo(tripMetadata2.startDate!));
        if (tripMetadatas.isNotEmpty) {
          var imageAssets = _generateRandomImages(tripMetadatas.length);
          var tripMetadataGridItems = <_TripMetadataGridItem>[];
          for (var index = 0; index < tripMetadatas.length; index++) {
            var imageAsset = imageAssets[index];
            var tripMetadataFacade = tripMetadatas[index];
            tripMetadataGridItems.add(_TripMetadataGridItem(
                tripMetaDataFacade: tripMetadataFacade,
                imageAsset: imageAsset));
          }
          return GridView.extent(
            maxCrossAxisExtent: 350,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: tripMetadataGridItems,
          );
        } else {
          return Align(
            alignment: Alignment.center,
            child: PlatformTextElements.createSubHeader(
              context: context,
              text: AppLocalizations.of(context)!.noTripsCreated,
            ),
          );
        }
      },
    );
  }

  List<String> _generateRandomImages(int numberOfTripMetadatas) {
    List<String> tempImages = List.from(_tripPlanningImageAssets);
    Random random = Random();
    var gridImages = <String>[];
    for (int i = 0; i < numberOfTripMetadatas; i++) {
      if (i < 3) {
        // Initial random distribution
        tempImages.shuffle(random);
        gridImages.add(tempImages[i % 3]);
      } else {
        // Ensure no repetition in three consequent items
        List<String> remainingImages = List.from(_tripPlanningImageAssets);
        remainingImages.remove(gridImages[i - 1]);
        remainingImages.remove(gridImages[i - 2]);

        gridImages.add(remainingImages[random.nextInt(remainingImages.length)]);
      }
    }

    return gridImages;
  }
}

class _TripSettingsMenu extends StatelessWidget {
  final TripMetadataModelFacade tripMetaDataFacade;

  _TripSettingsMenu({required this.tripMetaDataFacade});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Widget>(
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem(
            child: Row(
              children: [
                Icon(Icons.delete_rounded),
                SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.deleteTrip),
              ],
            ),
            onTap: () {
              var tripManagementBloc =
                  BlocProvider.of<TripManagementBloc>(context);
              tripManagementBloc.add(
                UpdateTripEntity<TripMetadataModelFacade>.delete(
                  tripEntity: tripMetaDataFacade,
                ),
              );
            },
          ),
        ];
      },
      offset: const Offset(0, kToolbarHeight + 5),
      child: Padding(
        padding: EdgeInsets.all(2.0),
        child: CircleAvatar(
          radius: 30,
          backgroundColor: Colors.black,
          child: Icon(
            Icons.settings_rounded,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _TripMetadataGridItem extends StatelessWidget {
  final _dateFormat = DateFormat.MMMEd();

  _TripMetadataGridItem(
      {super.key, required this.tripMetaDataFacade, required String imageAsset})
      : imageAsset = AssetImage(imageAsset);

  TripMetadataModelFacade tripMetaDataFacade;
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
            child: Ink.image(
              image: imageAsset,
              fit: BoxFit.fill,
              child: InkWell(
                onTap: () {
                  var tripManagementBloc =
                      BlocProvider.of<TripManagementBloc>(context);
                  tripManagementBloc
                      .add(LoadTrip(tripMetadata: tripMetaDataFacade));
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Opacity(
                      opacity: 0.8,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white12, Colors.black],
                            stops: [0, 1],
                          ),
                        ),
                        child: ListTile(
                          tileColor: Colors.transparent,
                          title: Text(
                            tripMetaDataFacade.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          subtitle: Text(
                            subTitle,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          trailing: IconButton(
                            onPressed: () {
                              _buildDeleteTripConfirmationDialog(context);
                            },
                            icon: Icon(Icons.delete_rounded),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      listener: (BuildContext context, TripManagementState state) {},
      buildWhen: (previousState, currentState) {
        if (currentState.isTripEntity<TripMetadataModelFacade>()) {
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
                  BlocProvider.of<TripManagementBloc>(context).add(
                      UpdateTripEntity<TripMetadataModelFacade>.delete(
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
