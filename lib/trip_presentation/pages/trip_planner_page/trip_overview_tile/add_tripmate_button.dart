import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/app_data/models/collection_change_metadata.dart';
import 'package:wandrr/app_presentation/blocs/bloc_extensions.dart';
import 'package:wandrr/app_presentation/extensions.dart';
import 'package:wandrr/app_presentation/widgets/button.dart';
import 'package:wandrr/trip_data/models/trip_metadata.dart';
import 'package:wandrr/trip_data/trip_repository_extensions.dart';
import 'package:wandrr/trip_presentation/trip_management_bloc/bloc.dart';
import 'package:wandrr/trip_presentation/trip_management_bloc/events.dart';
import 'package:wandrr/trip_presentation/trip_management_bloc/states.dart';

class AddTripMateField extends StatelessWidget {
  const AddTripMateField({
    super.key,
  });

  static final _emailRegExValidator = RegExp('.*@.*.com');

  @override
  Widget build(BuildContext context) {
    var addTripEditingValueNotifier = ValueNotifier<bool>(false);
    var currentContributors = context.getActiveTrip().tripMetadata.contributors;
    var tripMateUserNameEditingController = TextEditingController();
    return TextFormField(
      maxLines: null,
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
