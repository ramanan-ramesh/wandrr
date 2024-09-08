import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wandrr/blocs/master_page_bloc/master_page_bloc.dart';
import 'package:wandrr/blocs/master_page_bloc/master_page_events.dart';
import 'package:wandrr/blocs/trip_management/bloc.dart';
import 'package:wandrr/blocs/trip_management/events.dart';
import 'package:wandrr/contracts/app_level_data.dart';
import 'package:wandrr/contracts/extensions.dart';
import 'package:wandrr/contracts/trip_metadata.dart';

import 'trip_creator_dialog.dart';
import 'trips_list_view.dart';

class HomePage extends StatelessWidget {
  static const _cutOffPageWidth = 1000.0;

  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    print("HomePage-build");
    return LayoutBuilder(
      builder: (context, constraints) {
        var appLevelData = context.getAppLevelData() as AppLevelDataModifier;
        if (constraints.maxWidth > _cutOffPageWidth) {
          appLevelData.updateLayoutType(true);
          return _buildLayout(
              contentWidth: constraints.maxWidth / 2, context: context);
        } else {
          appLevelData.updateLayoutType(false);
          return _buildLayout(context: context);
        }
      },
    );
  }

  Widget _buildLayout({double? contentWidth, required BuildContext context}) {
    return Scaffold(
      appBar: _HomeAppBar(
        contentWidth: contentWidth,
      ),
      floatingActionButton: _buildCreateTripButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: contentWidth != null
          ? Center(
              child: SizedBox(
                width: contentWidth,
                child: _buildLayoutContent(context),
              ),
            )
          : _buildLayoutContent(context),
    );
  }

  Widget _buildLayoutContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 10),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              AppLocalizations.of(context)!.viewRecentTrips,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Expanded(
            child: TripListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateTripButton(BuildContext pageContext) {
    bool keyboardIsOpened = MediaQuery.of(pageContext).viewInsets.bottom != 0.0;
    return Visibility(
      visible: !keyboardIsOpened,
      child: FloatingActionButton.extended(
        onPressed: () {
          var geoLocator = pageContext.getPlatformDataRepository().geoLocator;
          showGeneralDialog(
            context: pageContext,
            barrierDismissible: true,
            barrierLabel: 'Close',
            pageBuilder: (BuildContext context, Animation<double> animation,
                Animation<double> secondaryAnimation) {
              return Material(
                color: Colors.black12,
                //TODO: Is this the right way to set dialog color?
                child: Dialog(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 450),
                    child: TripCreatorDialog(
                      geoLocator: geoLocator,
                      eventSubmitter: (tripCreationMetadata) {
                        _submitTripCreationEvent(
                            pageContext, tripCreationMetadata);
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
        label: Text(AppLocalizations.of(pageContext)!.planTrip),
        icon: Icon(Icons.add_location_alt_rounded),
      ),
    );
  }

  void _submitTripCreationEvent(
      BuildContext pageContext, TripMetadataModelFacade tripCreationMetadata) {
    var userName = pageContext.getAppLevelData().activeUser!.userName;
    var tripManagement = BlocProvider.of<TripManagementBloc>(pageContext);
    var tripMetadata = tripCreationMetadata.clone();
    tripMetadata.contributors = [userName];
    tripManagement.add(
      UpdateTripEntity<TripMetadataModelFacade>.create(
          tripEntity: tripMetadata),
    );
  }
}

class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  static const String _appLogoAsset = 'assets/images/logo.jpg';
  final double? contentWidth;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  const _HomeAppBar({Key? key, this.contentWidth}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: contentWidth != null,
      title: SizedBox(
        width: contentWidth,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Image.asset(
                    _appLogoAsset, //
                    width: 40,
                    height: 40,
                  ),
                ),
                const Text(
                  'wandrr',
                  style: TextStyle(fontSize: 20),
                ),
              ],
            ),
            _UserProfilePopupMenu()
          ],
        ),
      ),
    );
  }
}

class _UserProfilePopupMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var userPhotoUrl = context.getAppLevelData().activeUser!.photoUrl;
    return PopupMenuButton<Widget>(
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem(
            child: const Row(
              children: [
                Icon(Icons.settings),
                SizedBox(width: 8),
                Text('Settings'),
              ],
            ),
            onTap: () {},
          ),
          PopupMenuItem(
            child: const Row(
              children: [
                Icon(Icons.logout),
                SizedBox(width: 8),
                Text('Logout'),
              ],
            ),
            onTap: () {
              var masterPageBloc = BlocProvider.of<MasterPageBloc>(context);
              masterPageBloc.add(Logout());
            },
          ),
        ];
      },
      offset: const Offset(0, kToolbarHeight + 5),
      child: Padding(
        padding: EdgeInsets.all(2.0),
        child: _ProfileActionButton(
          photoUrl: userPhotoUrl,
        ),
      ),
    );
  }
}

class _ProfileActionButton extends StatefulWidget {
  final String? photoUrl;

  const _ProfileActionButton({Key? key, required this.photoUrl})
      : super(key: key);

  @override
  State<_ProfileActionButton> createState() => _ProfileActionButtonState();
}

class _ProfileActionButtonState extends State<_ProfileActionButton> {
  var _isImageLoaded = false;
  NetworkImage? _userProfileNetworkImage;

  @override
  void initState() {
    super.initState();
    if (widget.photoUrl != null) {
      _userProfileNetworkImage = NetworkImage(widget.photoUrl!);
      var imageStreamListener = ImageStreamListener((image, synchronousCall) {
        if (mounted) {
          setState(() {
            _isImageLoaded = true;
          });
        }
      });
      _userProfileNetworkImage!
          .resolve(const ImageConfiguration(size: Size(40, 40)))
          .addListener(imageStreamListener);
    }
  }

  @override
  Widget build(BuildContext context) {
    return !_isImageLoaded
        ? const CircleAvatar(
            radius: 30,
            child: Icon(Icons.account_circle_rounded),
          )
        : CircleAvatar(
            radius: 30,
            backgroundImage: _userProfileNetworkImage,
          );
  }
}
