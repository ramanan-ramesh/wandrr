import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wandrr/blocs/trip_management/bloc.dart';
import 'package:wandrr/blocs/trip_management/events.dart';
import 'package:wandrr/contracts/trip_metadata.dart';
import 'package:wandrr/contracts/trip_repository.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/modules/budgeting/expense_view_adapter.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/modules/itinerary/itinerary_listview.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/modules/lodging/lodging_listview.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/modules/plan_data/plan_data_listview.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/modules/transit/transit_listview.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/trip_overview_tile.dart';

import 'modules/budgeting/header_tile.dart';

enum ExpenseViewType {
  ShowExpenseList,
  RequestExpenseList,
  ShowBreakdownViewer,
  RequestBreakdownViewer,
  ShowBudgetEditor,
  RequestBudgetEditor,
  ShowDebtSummary,
  RequestDebtSummary,
  ShowAddTripmate,
  RequestAddTripmate
}

class TripPlannerPage extends StatelessWidget {
  static const _breakOffLayoutWidth = 800;
  static const _maximumPageWidth = 700.0;
  var _expenseViewTypeNotifier =
      ValueNotifier<ExpenseViewType>(ExpenseViewType.ShowExpenseList);

  TripPlannerPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > _breakOffLayoutWidth) {
          return Row(
            children: [
              _buildPageWithSize(_buildLayout(context, true)),
              _buildPageWithSize(
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

  Widget _buildPageWithSize(Widget layout) {
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
              child: BudgetingHeaderTile(
                expenseViewTypeNotifier: _expenseViewTypeNotifier,
              ),
            ),
          if (!isBigLayout)
            ExpenseViewAdapter(
              expenseViewTypeNotifier: _expenseViewTypeNotifier,
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
          var tripManagementBloc = BlocProvider.of<TripManagementBloc>(context);
          tripManagementBloc.add(GoToHome());
        },
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.5),
              child: Image.asset(
                _appLogoAsset,
                width: 40,
                height: 40,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.5),
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
            AppLocalizations.of(context)!.share,
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
                Text(AppLocalizations.of(context)!.deleteTrip),
              ],
            ),
            onTap: () {
              var tripMetadataFacade =
                  RepositoryProvider.of<TripRepositoryModelFacade>(context)
                      .activeTrip!
                      .tripMetadata;
              var tripManagementBloc =
                  BlocProvider.of<TripManagementBloc>(context);
              tripManagementBloc.add(
                  UpdateTripEntity<TripMetadataModelFacade>.delete(
                      tripEntity: tripMetadataFacade));
              tripManagementBloc.add(GoToHome());
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
