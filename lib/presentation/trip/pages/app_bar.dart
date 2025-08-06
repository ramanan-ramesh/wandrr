import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/data/app/app_data_repository_extensions.dart';
import 'package:wandrr/presentation/app/blocs/bloc_extensions.dart';
import 'package:wandrr/presentation/app/widgets/dialog.dart';
import 'package:wandrr/presentation/trip/bloc/bloc.dart';
import 'package:wandrr/presentation/trip/bloc/events.dart';
import 'package:wandrr/presentation/trip/bloc/states.dart';
import 'package:wandrr/presentation/trip/trip_repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/delete_trip_dialog.dart';

import '../../app/blocs/master_page/master_page_events.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  static const String _appLogoAsset = 'assets/images/logo.jpg';
  final double? contentWidth;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  const HomeAppBar({Key? key, this.contentWidth}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: contentWidth != null,
      flexibleSpace: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: SizedBox(
            width: contentWidth,
            child: BlocConsumer<TripManagementBloc, TripManagementState>(
              builder: (BuildContext context, TripManagementState state) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _createHomeButton(context),
                    if (context.tripRepository.activeTrip != null)
                      IconButton(
                          onPressed: () {
                            _showDeleteTripConfirmationDialog(context);
                          },
                          icon: const Icon(Icons.delete_rounded)),
                    _createRightActionButtons(context),
                  ],
                );
              },
              listener: (BuildContext context, TripManagementState state) {},
              buildWhen: (previousState, currentState) {
                return currentState is ActivatedTrip ||
                    currentState is NavigateToHome;
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteTripConfirmationDialog(BuildContext pageContext) {
    var tripMetadataToDelete = pageContext.activeTrip.tripMetadata;
    PlatformDialogElements.showAlertDialog(pageContext, (context) {
      return DeleteTripDialog(
          widgetContext: pageContext, tripMetadataFacade: tripMetadataToDelete);
    });
  }

  Widget _createRightActionButtons(BuildContext context) {
    return Row(
      children: [
        _createThemeModeSwitcher(context),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            onPressed: () {
              context.addMasterPageEvent(Logout());
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ),
      ],
    );
  }

  Widget _createHomeButton(BuildContext context) {
    return FloatingActionButton.extended(
      elevation: 0,
      onPressed: () {
        context.addTripManagementEvent(GoToHome());
      },
      label: Text(
        'wandrr',
        style: TextStyle(
            fontSize: Theme.of(context).textTheme.titleLarge!.fontSize),
      ),
      icon: Image.asset(
        _appLogoAsset,
        color: context.isLightTheme ? Colors.black : Colors.green,
        width: 40,
        height: 40,
      ),
    );
  }

  Widget _createThemeModeSwitcher(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.light_mode_rounded,
          color: Colors.green,
        ),
        Switch(
          value: !context.isLightTheme,
          onChanged: (bool value) {
            context.addMasterPageEvent(ChangeTheme(
                themeModeToChangeTo: value ? ThemeMode.dark : ThemeMode.light));
          },
        ),
        const Icon(
          Icons.mode_night_rounded,
          color: Colors.black,
        ),
      ],
    );
  }
}
