import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/asset_manager/assets.gen.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/presentation/trip/pages/trip_provider/app_bar/toolbar.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
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
                    Toolbar(),
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

  Widget _createHomeButton(BuildContext context) {
    return FloatingActionButton.extended(
      elevation: 0,
      onPressed: () {
        context.addTripManagementEvent(GoToHome());
      },
      label: Text(
        'wandrr',
        style: TextStyle(
          fontSize: Theme.of(context).textTheme.titleLarge!.fontSize,
        ),
      ),
      icon: Image(
        image: Assets.images.logo.provider(),
        color: context.isLightTheme ? Colors.white : Colors.black,
        width: 40,
        height: 40,
      ),
    );
  }
}
