import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/presentation/app/blocs/bloc_extensions.dart';
import 'package:wandrr/presentation/app/extensions.dart';
import 'package:wandrr/presentation/app/widgets/button.dart';
import 'package:wandrr/presentation/app/widgets/text.dart';
import 'package:wandrr/presentation/trip/bloc/events.dart';
import 'package:wandrr/presentation/trip/trip_repository_extensions.dart';

class AddTripMateField extends StatelessWidget {
  AddTripMateField({
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
        if (currentContributors
            .any((e) => e.toLowerCase() == username.toLowerCase())) {
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
            onContributorAdded: () {
              addTripEditingValueNotifier.value = false;
              tripMateUserNameEditingController.clear();
            },
          ),
        ),
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
      required this.contributors,
      required this.onContributorAdded});

  Iterable<String> contributors;
  final ValueNotifier<bool> addTripEditingValueNotifier;
  final TextEditingController tripMateUserNameEditingController;
  final VoidCallback onContributorAdded;

  @override
  State<_AddTripMateTextFieldButton> createState() =>
      _AddTripMateTextFieldButtonState();
}

class _AddTripMateTextFieldButtonState
    extends State<_AddTripMateTextFieldButton> {
  @override
  Widget build(BuildContext context) {
    return PlatformSubmitterFAB.conditionallyEnabled(
      icon: Icons.add,
      context: context,
      valueNotifier: widget.addTripEditingValueNotifier,
      isSubmitted: false,
      isElevationRequired: false,
      callback: () async {
        var didAcceptDialog = false;
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 3.0),
                              child: TextButton(
                                onPressed: () {
                                  _onDialogAccepted(context, dialogContext);
                                  didAcceptDialog = false;
                                },
                                child: Text(context.localizations.no),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 3.0),
                              child: TextButton(
                                onPressed: () {
                                  _onDialogAccepted(context, dialogContext);
                                  didAcceptDialog = true;
                                },
                                child: Text(context.localizations.yes),
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
        if (!didAcceptDialog) {
          setState(() {});
        }
      },
    );
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
