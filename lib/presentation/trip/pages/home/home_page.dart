import 'package:flutter/material.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/widgets/dialog.dart';
import 'package:wandrr/presentation/trip/pages/home/app_bar/app_bar.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

import 'trip_creator_dialog.dart';
import 'trips_list_view.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    context.updateLocalizations();
    return Scaffold(
      appBar: HomeAppBar(),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: _buildCreateTripButton(context),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: TripListView(),
    );
  }

  Widget _buildCreateTripButton(BuildContext pageContext) {
    var keyboardIsOpened = MediaQuery.of(pageContext).viewInsets.bottom != 0.0;
    return Visibility(
      visible: !keyboardIsOpened,
      child: FloatingActionButton.extended(
        onPressed: () {
          PlatformDialogElements.showGeneralDialog(
            pageContext,
            (dialogContext) => TripCreatorDialog(
              widgetContext: pageContext,
            ),
          );
        },
        label: Text(pageContext.localizations.planTrip),
        icon: const Icon(Icons.add_location_alt_rounded),
      ),
    );
  }
}
