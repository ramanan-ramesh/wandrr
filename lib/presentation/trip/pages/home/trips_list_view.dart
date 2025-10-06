import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/asset_manager/assets.gen.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/app/widgets/dialog.dart';
import 'package:wandrr/presentation/app/widgets/text.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/delete_trip_dialog.dart';

import 'thumbnail_selector.dart';

class TripListView extends StatelessWidget {
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
        var tripMetadatas = context
            .tripRepository.tripMetadataCollection.collectionItems
            .toList(growable: false)
          ..sort((tripMetadata1, tripMetadata2) =>
              tripMetadata1.startDate!.compareTo(tripMetadata2.startDate!));
        if (tripMetadatas.isNotEmpty) {
          return GridView.extent(
            maxCrossAxisExtent: 300,
            mainAxisSpacing: 7,
            crossAxisSpacing: 7,
            childAspectRatio: 0.75,
            children: tripMetadatas.map((tripMetadata) {
              return _TripMetadataGridItem(
                tripMetaDataFacade: tripMetadata,
              );
            }).toList(growable: false),
          );
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
}

class _TripMetadataGridItem extends StatelessWidget {
  _TripMetadataGridItem({required this.tripMetaDataFacade});

  TripMetadataFacade tripMetaDataFacade;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      builder: (BuildContext context, TripManagementState state) {
        var subTitle =
            '${tripMetaDataFacade.startDate!.dayDateMonthFormat} to ${tripMetaDataFacade.endDate!.dayDateMonthFormat}';
        var currentThumbnail = Assets.images.tripThumbnails.values.firstWhere(
            (element) =>
                element.keyName.split('/').last.split('.').first ==
                tripMetaDataFacade.thumbnailTag);
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
                    currentThumbnail.image(fit: BoxFit.cover),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: ThumbnailPicker(
                          tripMetaDataFacade: tripMetaDataFacade,
                          widgetContext: context),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                        ),
                        child: FittedBox(
                          child: Text(
                            subTitle,
                            style: TextStyle(
                              fontSize: Theme.of(context)
                                  .textTheme
                                  .labelMedium!
                                  .fontSize,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Card(
                  shape: const StadiumBorder(),
                  shadowColor: Colors.transparent,
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
          if (currentState.dataState == DataState.update &&
              tripMetadataUpdatedState
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
