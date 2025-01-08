import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/data/trip/trip_repository_extensions.dart';
import 'package:wandrr/presentation/app/blocs/bloc_extensions.dart';
import 'package:wandrr/presentation/app/extensions.dart';
import 'package:wandrr/presentation/app/widgets/button.dart';
import 'package:wandrr/presentation/app/widgets/text.dart';
import 'package:wandrr/presentation/trip/bloc/bloc.dart';
import 'package:wandrr/presentation/trip/bloc/events.dart';
import 'package:wandrr/presentation/trip/bloc/states.dart';

class AddTripMateField extends StatelessWidget {
  const AddTripMateField({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var addTripEditingValueNotifier = ValueNotifier<bool>(false);
    var currentContributors = context.activeTrip.tripMetadata.contributors;
    var tripMateUserNameEditingController = TextEditingController();
    return PlatformTextElements.createUsernameFormField(
      context: context,
      controller: tripMateUserNameEditingController,
      onTextChanged: (username, isValid) {
        if (currentContributors.contains(username)) {
          addTripEditingValueNotifier.value = false;
        } else {
          addTripEditingValueNotifier.value = isValid;
        }
      },
      inputDecoration: InputDecoration(
        hintText: context.localizations.add_tripmate,
        suffixIcon: Padding(
          padding: const EdgeInsets.all(3.0),
          child: _AddTripMateTextFieldButton(
            addTripEditingValueNotifier: addTripEditingValueNotifier,
            tripMateUserNameEditingController:
                tripMateUserNameEditingController,
            contributors: currentContributors,
          ),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelText: context.localizations.userName,
        icon: Icon(Icons.person_2_rounded),
      ),
      textInputAction: TextInputAction.done,
    );
  }
}

class _AddTripMateTextFieldButton extends StatefulWidget {
  _AddTripMateTextFieldButton(
      {super.key,
      required this.addTripEditingValueNotifier,
      required this.tripMateUserNameEditingController,
      required this.contributors});

  Iterable<String> contributors;
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
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: _shouldBuildAddTripMateButton,
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
                    child: Dialog(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppBar(
                            leading: IconButton(
                              //TODO: Unable to style splashColor here
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              icon: Icon(
                                Icons.close_rounded,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Text(
                              context.localizations
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
                                      _onDialogAccepted(context, dialogContext);
                                      didSubmitDialog = true;
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

  bool _shouldBuildAddTripMateButton(
      TripManagementState previousState, TripManagementState currentState) {
    if (currentState.isTripEntityUpdated<TripMetadataFacade>()) {
      var updatedTripEntity = currentState as UpdatedTripEntity;
      if (updatedTripEntity.dataState == DataState.Update) {
        var updatedTripMetadata = updatedTripEntity.tripEntityModificationData
            .modifiedCollectionItem as TripMetadataFacade;
        if (!listEquals(
            updatedTripMetadata.contributors, widget.contributors.toList())) {
          widget.contributors = updatedTripMetadata.contributors;
          return true;
        }
      }
    }
    return false;
  }

  void _onDialogAccepted(
      BuildContext widgetContext, BuildContext dialogContext) {
    var tripMetadataModelFacade = widgetContext.activeTrip.tripMetadata.clone();
    var currentContributors = tripMetadataModelFacade.contributors.toList();
    var contributorToAdd = widget.tripMateUserNameEditingController.text;
    if (!currentContributors.contains(contributorToAdd)) {
      currentContributors.add(contributorToAdd);
      tripMetadataModelFacade.contributors = currentContributors;
      widgetContext.addTripManagementEvent(
          UpdateTripEntity<TripMetadataFacade>.update(
              tripEntity: tripMetadataModelFacade));
    }
    Navigator.of(dialogContext).pop();
  }
}
