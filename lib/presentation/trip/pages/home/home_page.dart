import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wandrr/data/app/app_data_repository_extensions.dart';
import 'package:wandrr/presentation/app/blocs/bloc_extensions.dart';
import 'package:wandrr/presentation/app/blocs/master_page/master_page_events.dart';
import 'package:wandrr/presentation/app/extensions.dart';
import 'package:wandrr/presentation/app/widgets/button.dart';

import 'trip_creator_dialog.dart';
import 'trips_list_view.dart';

class HomePage extends StatelessWidget {
  static const _cutOffPageWidth = 1000.0;

  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var appLevelData = context.appDataModifier;
        if (constraints.maxWidth > _cutOffPageWidth) {
          appLevelData.isBigLayout = true;
          return _buildLayout(
              contentWidth: constraints.maxWidth / 2, context: context);
        } else {
          appLevelData.isBigLayout = false;
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
      floatingActionButton: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildCreateTripButton(context),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: LanguageSwitcher(),
          ),
        ],
      ),
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
              context.localizations.viewRecentTrips,
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
          showGeneralDialog(
            context: pageContext,
            barrierDismissible: false,
            pageBuilder: (BuildContext context, Animation<double> animation,
                Animation<double> secondaryAnimation) {
              return Material(
                color: Colors.black12,
                //TODO: Is this the right way to set dialog color?
                child: Dialog(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 450),
                    child: TripCreatorDialog(
                      widgetContext: pageContext,
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
                    _appLogoAsset,
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
            IconButton(
              onPressed: () {
                context.addMasterPageEvent(Logout());
              },
              icon: Icon(Icons.logout_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
