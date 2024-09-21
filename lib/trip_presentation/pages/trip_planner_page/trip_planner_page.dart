import 'package:flutter/material.dart';
import 'package:wandrr/app_data/models/app_level_data.dart';
import 'package:wandrr/app_data/platform_data_repository_extensions.dart';
import 'package:wandrr/app_presentation/blocs/bloc_extensions.dart';
import 'package:wandrr/app_presentation/extensions.dart';
import 'package:wandrr/trip_data/models/trip_metadata.dart';
import 'package:wandrr/trip_data/trip_repository_extensions.dart';
import 'package:wandrr/trip_presentation/pages/trip_planner_page/expense_view_adapter.dart';
import 'package:wandrr/trip_presentation/pages/trip_planner_page/trip_entity_list_views/itinerary.dart';
import 'package:wandrr/trip_presentation/pages/trip_planner_page/trip_entity_list_views/lodging.dart';
import 'package:wandrr/trip_presentation/pages/trip_planner_page/trip_entity_list_views/transit.dart';
import 'package:wandrr/trip_presentation/pages/trip_planner_page/trip_overview_tile/trip_overview_tile.dart';
import 'package:wandrr/trip_presentation/trip_management_bloc/events.dart';

import 'budgeting/header_tile.dart';
import 'expense_view_type.dart';
import 'trip_entity_list_views/plan_data.dart';

class TripPlannerPage extends StatelessWidget {
  static const _breakOffLayoutWidth = 1000;
  static const _maximumPageWidth = 700.0;
  final _expenseViewTypeNotifier =
      ValueNotifier<ExpenseViewType>(ExpenseViewType.ShowExpenseList);

  TripPlannerPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var appLevelData = context.getAppLevelData() as AppLevelDataModifier;
        if (constraints.maxWidth > _breakOffLayoutWidth) {
          appLevelData.updateLayoutType(true);
          return Row(
            children: [
              _buildConstrainedPageForLayout(_buildLayout(context, true)),
              _buildConstrainedPageForLayout(
                CustomScrollView(
                  slivers: <Widget>[
                    SliverToBoxAdapter(
                      child: BudgetingHeaderTile(
                        expenseViewTypeNotifier: _expenseViewTypeNotifier,
                      ),
                    ),
                    ExpenseViewAdapter(
                      expenseViewTypeNotifier: _expenseViewTypeNotifier,
                    ),
                  ],
                ),
              ),
            ],
          );
        } else {
          appLevelData.updateLayoutType(false);
          return Center(
            child: Container(
              constraints:
                  BoxConstraints(minWidth: 500, maxWidth: _maximumPageWidth),
              child: _buildLayout(context, false),
            ),
          );
        }
      },
    );
  }

  Widget _buildConstrainedPageForLayout(Widget layout) {
    return Expanded(
      child: Center(
        child: Container(
          constraints: BoxConstraints(
              maxWidth: _maximumPageWidth, minWidth: _breakOffLayoutWidth / 2),
          child: layout,
        ),
      ),
    );
  }

  Widget _buildLayout(BuildContext context, bool isBigLayout) {
    return Scaffold(
      appBar: _AppBar(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: TripOverviewTile(),
          ),
          SliverPadding(
            sliver: TransitListView(),
            padding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
          ),
          SliverToBoxAdapter(
            child: Divider(
              height: 25,
            ),
          ),
          SliverPadding(
            sliver: LodgingListView(),
            padding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
          ),
          SliverToBoxAdapter(
            child: Divider(
              height: 25,
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
            sliver: PlanDataListView(),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
            sliver: ItineraryListView(),
          ),
          if (!isBigLayout)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
                child: BudgetingHeaderTile(
                  expenseViewTypeNotifier: _expenseViewTypeNotifier,
                ),
              ),
            ),
          if (!isBigLayout)
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
              sliver: ExpenseViewAdapter(
                expenseViewTypeNotifier: _expenseViewTypeNotifier,
              ),
            ),
        ],
      ),
    );
  }
}

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  static const String _appLogoAsset = 'assets/images/logo.jpg';

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  const _AppBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: GestureDetector(
        onTap: () {
          context.addTripManagementEvent(GoToHome());
        },
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Image.asset(
                  _appLogoAsset,
                  width: 40,
                  height: 40,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: const Text(
                'wandrr',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
      actions: [
        FloatingActionButton.extended(
          icon: Icon(
            Icons.share_rounded,
          ),
          label: Text(
            context.withLocale().share,
          ),
          onPressed: () {},
        ),
        _TripSettingsMenu()
      ],
    );
  }
}

class _TripSettingsMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Widget>(
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem(
            child: Row(
              children: [
                Icon(Icons.delete_rounded),
                SizedBox(width: 8),
                Text(context.withLocale().deleteTrip),
              ],
            ),
            onTap: () {
              var tripMetadataFacade = context.getActiveTrip().tripMetadata;
              context.addTripManagementEvent(
                  UpdateTripEntity<TripMetadataFacade>.delete(
                      tripEntity: tripMetadataFacade));
              context.addTripManagementEvent(GoToHome());
            },
          ),
        ];
      },
      offset: const Offset(0, kToolbarHeight + 5),
      child: Padding(
        padding: EdgeInsets.all(2.0),
        child: CircleAvatar(
          radius: 30,
          child: Icon(
            Icons.settings_rounded,
          ),
        ),
      ),
    );
  }
}
