import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/app_data/models/collection_change_metadata.dart';
import 'package:wandrr/app_data/platform_data_repository_extensions.dart';
import 'package:wandrr/app_presentation/blocs/bloc_extensions.dart';
import 'package:wandrr/app_presentation/blocs/trip_management/bloc.dart';
import 'package:wandrr/app_presentation/blocs/trip_management/events.dart';
import 'package:wandrr/app_presentation/blocs/trip_management/states.dart';
import 'package:wandrr/app_presentation/extensions.dart';
import 'package:wandrr/app_presentation/widgets/button.dart';
import 'package:wandrr/app_presentation/widgets/date_range_pickers.dart';
import 'package:wandrr/trip_data/models/trip_data.dart';
import 'package:wandrr/trip_data/models/trip_metadata.dart';
import 'package:wandrr/trip_data/trip_repository_extensions.dart';

import 'constants.dart';

class TripOverviewTile extends StatelessWidget {
  TripOverviewTile({Key? key}) : super(key: key);

  static const _heightOfContributorWidget = 15.0;
  static const _imageHeight = 250.0;
  static const _assetImage = 'assets/images/planning_the_trip.jpg';
  final _canUpdateTripTitleNotifier = ValueNotifier(false);

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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(
              _assetImage,
              fit: isBigLayout ? BoxFit.fill : BoxFit.contain,
              height: _imageHeight,
            ),
            Container(
              height: isBigLayout ? 200 : 180,
            ),
          ],
        ),
        Positioned(
          left: 10,
          right: 10,
          top: _calculateOverViewTileSize(isBigLayout, numberOfContributors),
          child: _buildOverviewTile(context, activeTrip, isBigLayout),
        )
      ],
    );
  }

  double _calculateOverViewTileSize(
      bool isBigLayout, int numberOfContributors) {
    var baseSize = isBigLayout ? 200 : 150;
    return baseSize + (numberOfContributors + 1) * _heightOfContributorWidget;
  }

  Padding _buildOverviewTile(
      BuildContext context, TripDataFacade activeTrip, bool isBigLayout) {
    var orientedWidget = !isBigLayout
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: _buildDateRangeButton(
                    context, activeTrip.tripMetadata, isBigLayout),
              ),
              Flexible(
                  child: _buildSplitByIcons(context, activeTrip.tripMetadata))
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: _buildDateRangeButton(
                    context, activeTrip.tripMetadata, isBigLayout),
              ),
              Flexible(
                  child: _buildSplitByIcons(context, activeTrip.tripMetadata))
            ],
          );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              _buildTitleEditingField(activeTrip, context),
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
        _canUpdateTripTitleNotifier.value = false;
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
          onChanged: (newTitle) {
            if (newTitle.isNotEmpty &&
                newTitle != activeTrip.tripMetadata.name) {
              _canUpdateTripTitleNotifier.value = true;
            } else {
              _canUpdateTripTitleNotifier.value = false;
            }
          },
          decoration: InputDecoration(
              suffixIcon: Padding(
            padding: const EdgeInsets.all(3.0),
            child: PlatformSubmitterFAB.conditionallyEnabled(
              valueNotifier: _canUpdateTripTitleNotifier,
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

  Widget _buildSplitByIcons(
      BuildContext context, TripMetadataFacade tripMetadata) {
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
                child: _AddTripMateField())),
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

class _AddTripMateField extends StatelessWidget {
  const _AddTripMateField({
    super.key,
  });

  static final _emailRegExValidator = RegExp('.*@.*.com');

  @override
  Widget build(BuildContext context) {
    var addTripEditingValueNotifier = ValueNotifier<bool>(false);
    var currentContributors = context.getActiveTrip().tripMetadata.contributors;
    var tripMateUserNameEditingController = TextEditingController();
    return TextFormField(
      textInputAction: TextInputAction.done,
      controller: tripMateUserNameEditingController,
      decoration: InputDecoration(
        hintText: context.withLocale().add_tripmate,
        suffixIcon: Padding(
          padding: const EdgeInsets.all(3.0),
          child: _AddTripMateTextFieldButton(
              addTripEditingValueNotifier: addTripEditingValueNotifier,
              tripMateUserNameEditingController:
                  tripMateUserNameEditingController),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelText: context.withLocale().userName,
        icon: Icon(Icons.person_2_rounded),
      ),
      onChanged: (username) {
        var matches = _emailRegExValidator.firstMatch(username);
        final matchedText = matches?.group(0);
        if (matchedText != username || currentContributors.contains(username)) {
          addTripEditingValueNotifier.value = false;
        } else {
          addTripEditingValueNotifier.value = true;
        }
      },
    );
  }
}

class _AddTripMateTextFieldButton extends StatefulWidget {
  const _AddTripMateTextFieldButton(
      {super.key,
      required this.addTripEditingValueNotifier,
      required this.tripMateUserNameEditingController});

  final ValueNotifier<bool> addTripEditingValueNotifier;
  final TextEditingController tripMateUserNameEditingController;

  @override
  State<_AddTripMateTextFieldButton> createState() =>
      _AddTripMateTextFieldButtonState();
}

class _AddTripMateTextFieldButtonState
    extends State<_AddTripMateTextFieldButton> {
  @override
  Widget build(BuildContext context) {
    var currentContributors = context.getActiveTrip().tripMetadata.contributors;
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: (previousState, currentState) =>
          _canBuildButton(currentState, currentContributors),
      builder: (BuildContext context, TripManagementState state) {
        return PlatformSubmitterFAB.conditionallyEnabled(
          icon: Icons.add,
          context: context,
          valueNotifier: widget.addTripEditingValueNotifier,
          isSubmitted: false,
          callback: () async {
            var didSubmitDialog = false;
            await showDialog(
                context: context,
                builder: (BuildContext dialogContext) {
                  return Material(
                    color: Colors.black12,
                    child: Dialog(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Text(
                              context
                                  .withLocale()
                                  .splitExpensesWithNewTripMateMessage,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 3.0),
                                  child: IconButton(
                                    //TODO: Unable to style splashColor here
                                    onPressed: () {
                                      didSubmitDialog = false;
                                      Navigator.of(dialogContext).pop();
                                    },
                                    icon: Icon(
                                      Icons.close_rounded,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 3.0),
                                  child: IconButton(
                                    icon: Icon(Icons.check_rounded),
                                    onPressed: () {
                                      _onDialogAccepted(context, dialogContext);
                                      didSubmitDialog = true;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                });
            if (!didSubmitDialog) {
              setState(() {});
            }
          },
        );
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }

  bool _canBuildButton(
      TripManagementState currentState, List<String> currentContributors) {
    if (currentState.isTripEntity<TripMetadataFacade>()) {
      var updatedTripEntity = currentState as UpdatedTripEntity;
      var tripMetadataModificationData =
          updatedTripEntity.tripEntityModificationData
              as CollectionChangeMetadata<TripMetadataFacade>;
      if (tripMetadataModificationData.isFromEvent &&
          currentContributors !=
              tripMetadataModificationData
                  .modifiedCollectionItem.contributors) {
        return true;
      }
    }
    return false;
  }

  void _onDialogAccepted(
      BuildContext widgetContext, BuildContext dialogContext) {
    var tripMetadataModelFacade = widgetContext.getActiveTrip().tripMetadata;
    var currentContributors = tripMetadataModelFacade.contributors;
    var contributorToAdd = widget.tripMateUserNameEditingController.text;
    if (!currentContributors.contains(contributorToAdd)) {
      currentContributors.add(contributorToAdd);
      context.addTripManagementEvent(
          UpdateTripEntity<TripMetadataFacade>.update(
              tripEntity: tripMetadataModelFacade));
    }
    Navigator.of(dialogContext).pop();
  }
}
