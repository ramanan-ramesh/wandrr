import 'package:flutter/material.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/widgets/dialog.dart';
import 'package:wandrr/presentation/trip/pages/home/app_bar/app_bar.dart';

import 'trip_creator_dialog.dart';
import 'trips_list_view.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom != 0;
    return Scaffold(
      appBar: const HomeAppBar(),
      floatingActionButton: keyboardOpen
          ? null
          : FloatingActionButton.extended(
              heroTag: 'homePageCreateTripButton',
              onPressed: () => PlatformDialogElements.showGeneralDialog(
                context,
                (dialogContext) => TripCreatorDialog(widgetContext: context),
              ),
              label: Text(context.localizations.planTrip),
              icon: const Icon(Icons.add_location_alt_rounded),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: const Padding(
        padding: EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 10),
        child: TripListView(),
      ),
    );
  }
}
