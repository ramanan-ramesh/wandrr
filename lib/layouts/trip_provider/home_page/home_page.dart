import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/master_page_bloc/master_page_bloc.dart';
import 'package:wandrr/blocs/master_page_bloc/master_page_events.dart';
import 'package:wandrr/blocs/trip_management_bloc/bloc.dart';
import 'package:wandrr/blocs/trip_management_bloc/events.dart';

import 'home_page_content.dart';
import 'trip_creator_fragment.dart';
import 'trips_list_fragment.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isTripCreatorPage = false;
  late HomePageContent _tripListFragment;
  late HomePageContent _tripCreatorFragment;
  static const _cutOffPageWidth = 1000.0;

  void _switchFragment() {
    setState(() {
      _isTripCreatorPage = !_isTripCreatorPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    print("HomePage-build");
    _initializeFragments(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > _cutOffPageWidth) {
          return _buildLayout(contentWidth: constraints.maxWidth / 2);
        } else {
          return _buildLayout();
        }
      },
    );
  }

  void _initializeFragments(BuildContext context) {
    _tripListFragment = TripListFragment(context, _switchFragment);
    _tripCreatorFragment = TripCreatorFragment(context: context);
  }

  Widget _buildLayout({double? contentWidth}) {
    return Scaffold(
      appBar: _HomeAppBar(
        contentWidth: contentWidth,
      ),
      floatingActionButton: _isTripCreatorPage
          ? _tripCreatorFragment.floatingActionButton
          : _tripListFragment.floatingActionButton,
      floatingActionButtonLocation: _isTripCreatorPage
          ? _tripCreatorFragment.floatingActionButtonLocation
          : _tripListFragment.floatingActionButtonLocation,
      body: contentWidth != null
          ? Center(
              child: SizedBox(
                width: contentWidth,
                child: _isTripCreatorPage
                    ? _tripCreatorFragment.body
                    : _tripListFragment.body,
              ),
            )
          : _isTripCreatorPage
              ? _tripCreatorFragment.body
              : _tripListFragment.body,
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
            GestureDetector(
              onTap: () {
                var tripManagementBloc =
                    BlocProvider.of<TripManagementBloc>(context);
                tripManagementBloc.add(GoToHome());
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Image.asset(
                      _appLogoAsset, //
                      color: Colors.white,
                      // Replace with your app logo asset
                      width: 40,
                      height: 40,
                    ),
                  ),
                  const Text(
                    'wandrr', // Replace with your app name
                    style: TextStyle(fontSize: 20),
                  ),
                ],
              ),
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
            onTap: () {
              // Handle settings click
            },
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
              // Handle logout click
              var masterPageBloc = BlocProvider.of<MasterPageBloc>(context);
              masterPageBloc.add(Logout());
            },
          ),
        ];
      },
      offset: const Offset(0, kToolbarHeight + 5),
      child: const Padding(
        padding: EdgeInsets.all(2.0),
        child: _ProfileActionButton(),
      ), // Adjust the offset to position the popup
    );
  }
}

class _ProfileActionButton extends StatefulWidget {
  const _ProfileActionButton({Key? key}) : super(key: key);

  @override
  State<_ProfileActionButton> createState() => _ProfileActionButtonState();
}

class _ProfileActionButtonState extends State<_ProfileActionButton> {
  var _isImageLoaded = false;
  final NetworkImage _userProfileNetworkImage =
      const NetworkImage("https://picsum.photos/250?image=9");

  @override
  void initState() {
    super.initState();
    var imageStreamListener = ImageStreamListener((image, synchronousCall) {
      if (mounted) {
        setState(() {
          _isImageLoaded = true;
        });
      }
    }, onError: (object, stackTrace) {
      print('error while loading user profile image');
    });
    _userProfileNetworkImage
        .resolve(const ImageConfiguration(size: Size(40, 40)))
        .addListener(imageStreamListener);
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
