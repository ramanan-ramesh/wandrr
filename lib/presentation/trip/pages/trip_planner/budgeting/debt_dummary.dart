import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wandrr/data/app/app_data_repository_extensions.dart';
import 'package:wandrr/data/trip/models/debt_data.dart';
import 'package:wandrr/data/trip/trip_repository_extensions.dart';
import 'package:wandrr/presentation/app/extensions.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/constants.dart';

class DebtSummaryTile extends StatelessWidget {
  const DebtSummaryTile({super.key});

  static const double _heightOfContributorWidget = 20.0;

  @override
  Widget build(BuildContext context) {
    var activeTrip = context.activeTrip;
    var currentUserName = context.activeUser!.userName;
    var budgetingModule = activeTrip.budgetingModuleFacade;
    var appLocalizations = context.localizations;
    var currentContributors = activeTrip.tripMetadata.contributors;
    currentContributors.sort((a, b) => a.compareTo(b));
    var contributorsVsColors = <String, Color>{};
    for (var index = 0; index < currentContributors.length; index++) {
      var contributor = currentContributors.elementAt(index);
      contributorsVsColors[contributor] = contributorColors.elementAt(index);
    }
    return SliverToBoxAdapter(
      child: FutureBuilder<List<DebtData>>(
        future: budgetingModule.retrieveDebtDataList(),
        builder:
            (BuildContext context, AsyncSnapshot<List<DebtData>> snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            var debtDataList = snapshot.data!;
            var personsOwingMoney = debtDataList.map((e) => e.owedBy);
            var personsOwedMoney = debtDataList.map((e) => e.owedTo);
            var allMoneyOwed = debtDataList.map((e) => e.money);
            Widget childWidget;
            if (budgetingModule.totalExpenditure == 0 || debtDataList.isEmpty) {
              childWidget = Center(
                child: Text('There are no expenses to split.'),
              );
            } else {
              childWidget = Row(
                children: [
                  Expanded(
                    child: Column(
                      children: personsOwingMoney
                          .map((e) => _buildContributorName(e, currentUserName,
                              contributorsVsColors[e]!, appLocalizations))
                          .toList(),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: personsOwingMoney
                          .map((e) =>
                              Text(e == currentUserName ? 'Owe' : 'Owes'))
                          .toList(),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: personsOwedMoney
                          .map((e) => _buildContributorName(e, currentUserName,
                              contributorsVsColors[e]!, appLocalizations))
                          .toList(),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children:
                          allMoneyOwed.map((e) => Text(e.toString())).toList(),
                    ),
                  ),
                ],
              );
            }
            return Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5.0),
                child: childWidget,
              ),
            );
          }
          return CircularProgressIndicator();
        },
      ),
    );
  }

  Widget _buildContributorName(String contributorName, String currentUserName,
      Color contributorColor, AppLocalizations appLocalizations) {
    return TextButton.icon(
        onPressed: null,
        icon: Container(
          width: 20,
          height: _heightOfContributorWidget,
          decoration: BoxDecoration(
            color: contributorColor,
            shape: BoxShape.circle,
          ),
        ),
        label: FittedBox(
            child: Text(contributorName == currentUserName
                ? appLocalizations.you
                : contributorName.split('@').first)));
  }
}
