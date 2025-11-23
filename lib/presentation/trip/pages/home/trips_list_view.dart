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
import 'package:wandrr/presentation/trip/widgets/trip_entity_update_handler.dart';

import 'thumbnail_selector.dart';

class TripListView extends StatelessWidget {
  TripListView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 10),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              context.localizations.viewRecentTrips,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Expanded(
            child: BlocConsumer<TripManagementBloc, TripManagementState>(
              buildWhen: _shouldBuildListView,
              listener: (context, state) {},
              builder: (context, state) {
                var tripMetadatas = context
                    .tripRepository.tripMetadataCollection.collectionItems
                    .toList(growable: false)
                  ..sort((tripMetadata1, tripMetadata2) => tripMetadata1
                      .startDate!
                      .compareTo(tripMetadata2.startDate!));
                if (tripMetadatas.isNotEmpty) {
                  return GridView.extent(
                    maxCrossAxisExtent: 300,
                    mainAxisSpacing: 7,
                    crossAxisSpacing: 7,
                    childAspectRatio: 0.75,
                    children: tripMetadatas.map((tripMetadata) {
                      return _TripMetadataGridItem(
                        tripId: tripMetadata.id!,
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
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldBuildListView(
      TripManagementState previousState, TripManagementState currentState) {
    if (currentState.isTripEntityUpdated<TripMetadataFacade>()) {
      var tripMetadataUpdatedState = currentState as UpdatedTripEntity;
      if (tripMetadataUpdatedState.dataState == DataState.delete ||
          tripMetadataUpdatedState.dataState == DataState.create) {
        return true;
      }
    }
    return false;
  }
}

class _TripMetadataGridItem extends StatelessWidget {
  final String tripId;
  _TripMetadataGridItem({required this.tripId});

  @override
  Widget build(BuildContext context) {
    return TripEntityUpdateHandler<TripMetadataFacade>(
      widgetBuilder: (context) {
        var tripMetaDataFacade = context
            .tripRepository.tripMetadataCollection.collectionItems
            .firstWhere((element) => element.id == tripId);
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
                              _showDeleteTripConfirmationDialog(
                                  context, tripMetaDataFacade);
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
      shouldRebuild:
          (TripMetadataFacade beforeUpdate, TripMetadataFacade afterUpdate) {
        return afterUpdate.id == tripId &&
                beforeUpdate.name != afterUpdate.name ||
            !beforeUpdate.startDate!.isOnSameDayAs(afterUpdate.startDate!) ||
            !beforeUpdate.endDate!.isOnSameDayAs(afterUpdate.endDate!) ||
            beforeUpdate.thumbnailTag != afterUpdate.thumbnailTag;
      },
    );
  }

  void _showDeleteTripConfirmationDialog(
      BuildContext pageContext, TripMetadataFacade tripMetaDataFacade) {
    PlatformDialogElements.showAlertDialog(pageContext, (context) {
      return DeleteTripDialog(
          widgetContext: pageContext, tripMetadataFacade: tripMetaDataFacade);
    });
  }
}
