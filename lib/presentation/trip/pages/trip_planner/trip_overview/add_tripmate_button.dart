import 'package:flutter/material.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/widgets/button.dart';
import 'package:wandrr/presentation/app/widgets/dialog.dart';
import 'package:wandrr/presentation/app/widgets/text.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

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
      onEmailChanged: (username, {required bool isValid}) {
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
        icon: const Icon(Icons.person_2_rounded),
      ),
      textInputAction: TextInputAction.done,
    );
  }
}

class _AddTripMateTextFieldButton extends StatelessWidget {
  const _AddTripMateTextFieldButton(
      {required this.addTripEditingValueNotifier,
      required this.tripMateUserNameEditingController,
      required this.contributors,
      required this.onContributorAdded});

  final Iterable<String> contributors;
  final ValueNotifier<bool> addTripEditingValueNotifier;
  final TextEditingController tripMateUserNameEditingController;
  final VoidCallback onContributorAdded;

  @override
  Widget build(BuildContext context) {
    return PlatformSubmitterFAB.conditionallyEnabled(
      child: Icon(Icons.add),
      valueNotifier: addTripEditingValueNotifier,
      isSubmitted: false,
      isElevationRequired: false,
      callback: () async {
        PlatformDialogElements.showAlertDialog(context, (dialogContext) {
          return AlertDialog(
            title:
                Text(context.localizations.splitExpensesWithNewTripMateMessage),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: Text(context.localizations.no),
              ),
              TextButton(
                onPressed: () {
                  _onDialogAccepted(context, dialogContext);
                  Navigator.of(dialogContext).pop();
                },
                child: Text(context.localizations.yes),
              ),
            ],
          );
        });
      },
    );
  }

  void _onDialogAccepted(
      BuildContext widgetContext, BuildContext dialogContext) {
    var tripMetadataModelFacade = widgetContext.activeTrip.tripMetadata.clone();
    var currentContributors = tripMetadataModelFacade.contributors.toList();
    var contributorToAdd = tripMateUserNameEditingController.text;
    if (!currentContributors.contains(contributorToAdd)) {
      currentContributors.add(contributorToAdd);
      tripMetadataModelFacade.contributors = currentContributors;
      widgetContext.addTripManagementEvent(
          UpdateTripEntity<TripMetadataFacade>.update(
              tripEntity: tripMetadataModelFacade));
    }
  }
}
