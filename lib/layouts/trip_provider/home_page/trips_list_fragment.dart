import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart' as intl;
import 'package:wandrr/blocs/trip_management_bloc/bloc.dart';
import 'package:wandrr/blocs/trip_management_bloc/events.dart';
import 'package:wandrr/blocs/trip_management_bloc/states.dart';
import 'package:wandrr/contracts/trip_metadata.dart';
import 'package:wandrr/platform_elements/button.dart';
import 'package:wandrr/platform_elements/text.dart';

import 'home_page.dart';

class TripListFragment implements HomePageContent {
  TripListFragment(BuildContext context, VoidCallback? callback)
      : _buildContext = ValueNotifier(context) {
    _floatingActionButton = _buildCreateTripButton(callback);
    _body = _buildBody(context);
  }

  @override
  void updateContext(BuildContext context) {
    _buildContext.value = context;
  }

  final ValueNotifier<BuildContext> _buildContext;

  Widget? _floatingActionButton;

  @override
  Widget? get floatingActionButton {
    return _floatingActionButton;
  }

  Widget? _body;

  @override
  Widget? get body {
    return _body;
  }

  Widget _createFABFromParameters(
      BuildContext context, bool isKeyboardOpened, VoidCallback? callback) {
    return Visibility(
        visible: !isKeyboardOpened,
        child: PlatformButtonElements.createExtendedFAB(
            iconData: Icons.add_location_alt_rounded,
            text: AppLocalizations.of(context)!.planTrip,
            onPressed: () {
              if (callback != null) {
                callback.call();
              }
            },
            context: context));
  }

  Widget _buildCreateTripButton(VoidCallback? callback) {
    var buildContext = _buildContext.value;
    bool keyboardIsOpened =
        MediaQuery.of(buildContext).viewInsets.bottom != 0.0;
    return ValueListenableBuilder(
      valueListenable: _buildContext,
      builder: (context, updatedContext, widget) {
        bool keyboardIsOpened =
            MediaQuery.of(updatedContext).viewInsets.bottom != 0.0;
        return _createFABFromParameters(
            updatedContext, keyboardIsOpened, callback);
      },
      child: _createFABFromParameters(buildContext, keyboardIsOpened, callback),
    );
  }

  Widget _buildTripList() {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: (previousState, currentState) {
        return currentState is LoadedTripMetadatas;
      },
      listener: (context, state) {},
      builder: (context, state) {
        print("TripsList-builder-${state}");
        if (state is LoadedTripMetadatas) {
          if (state.tripMetadatas.isNotEmpty) {
            return GridView.extent(
              maxCrossAxisExtent: 350,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: state.tripMetadatas
                  .map((e) => _TripMetadataGridItem(tripMetaDataFacade: e))
                  .toList(),
            );
          } else {
            return Align(
              alignment: Alignment.center,
              child: PlatformTextElements.createSubHeader(
                context: context,
                text: AppLocalizations.of(context)!.noTripsCreated,
              ),
            );
          }
        }
        return Container();
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 10),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: PlatformTextElements.createHeader(
              context: context,
              text: AppLocalizations.of(context)!.viewRecentTrips,
            ),
          ),
          Expanded(
            child: _buildTripList(),
          ),
        ],
      ),
    );
  }

  @override
  FloatingActionButtonLocation get floatingActionButtonLocation =>
      FloatingActionButtonLocation.centerFloat;
}

class _TripMetadataGridItem extends StatelessWidget {
  static const AssetImage _assetImage =
      AssetImage('assets/images/trip_metadata_image.webp');
  final _dateFormat = intl.DateFormat.MMMEd();

  _TripMetadataGridItem({
    super.key,
    required this.tripMetaDataFacade,
  });

  final TripMetaDataFacade tripMetaDataFacade;

  @override
  Widget build(BuildContext context) {
    var subTitle =
        '${_dateFormat.format(tripMetaDataFacade.startDate)} to ${_dateFormat.format(tripMetaDataFacade.endDate)}';
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Material(
        child: Ink.image(
          image: _assetImage,
          fit: BoxFit.fill,
          child: InkWell(
            onTap: () {
              var tripManagementBloc =
                  BlocProvider.of<TripManagementBloc>(context);
              tripManagementBloc.add(LoadTrip(
                  tripMetaDataFacade: tripMetaDataFacade,
                  isNewlyCreatedTrip: false));
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Opacity(
                  opacity: 0.8,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black12, Colors.black],
                        stops: [0, 1],
                      ),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.card_travel_rounded,
                        color: Colors.white,
                      ),
                      title: Text(
                        tripMetaDataFacade.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      subtitle: Text(
                        subTitle,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
