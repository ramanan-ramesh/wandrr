import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wandrr/blocs/trip_management/bloc.dart';
import 'package:wandrr/blocs/trip_management/events.dart';
import 'package:wandrr/contracts/extensions.dart';
import 'package:wandrr/contracts/trip_data.dart';
import 'package:wandrr/contracts/trip_metadata.dart';
import 'package:wandrr/layouts/constants.dart';
import 'package:wandrr/platform_elements/button.dart';
import 'package:wandrr/platform_elements/date_picker.dart';

class TripOverviewTile extends StatelessWidget {
  TripOverviewTile({Key? key}) : super(key: key);

  static const _heightOfContributorWidget = 15.0;
  static const _imageHeight = 250.0;
  static const _assetImage = 'assets/images/planning_the_trip.jpg';
  late TextEditingController _titleEditingController = TextEditingController();
  final _canUpdateTripTitleNotifier = ValueNotifier(false);
  static final _emailRegExValidator = RegExp('.*@.*.com');
  final TextEditingController _addTripMateFieldEditingController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    var activeTrip = context.getActiveTrip();
    _titleEditingController.text = activeTrip.tripMetadata.name;
    var numberOfContributors = activeTrip.tripMetadata.contributors.length;
    var isBigLayout = context.isBigLayout();
    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(
              _assetImage,
              fit: isBigLayout ? BoxFit.fill : BoxFit.contain,
              height: _imageHeight,
            ),
            Container(
              height: isBigLayout ? 200 : 180,
            ),
          ],
        ),
        Positioned(
          left: 10,
          right: 10,
          top: _calculateOverViewTileSize(isBigLayout, numberOfContributors),
          child: _buildOverviewTile(context, activeTrip, isBigLayout),
        )
      ],
    );
  }

  double _calculateOverViewTileSize(
      bool isBigLayout, int numberOfContributors) {
    var baseSize = isBigLayout ? 200 : 150;
    return baseSize + (numberOfContributors + 1) * _heightOfContributorWidget;
  }

  Padding _buildOverviewTile(
      BuildContext context, TripDataModelFacade activeTrip, bool isBigLayout) {
    var orientedWidget = !isBigLayout
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: _buildDateRangeButton(
                    context, activeTrip.tripMetadata, isBigLayout),
              ),
              Flexible(
                  child: _buildSplitByIcons(context, activeTrip.tripMetadata))
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: _buildDateRangeButton(
                    context, activeTrip.tripMetadata, isBigLayout),
              ),
              Flexible(
                  child: _buildSplitByIcons(context, activeTrip.tripMetadata))
            ],
          );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              _buildTitleEditingField(activeTrip, context),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: orientedWidget,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleEditingField(
      TripDataModelFacade activeTrip, BuildContext context) {
    return TextField(
      controller: _titleEditingController,
      onChanged: (newTitle) {
        if (newTitle.isNotEmpty && newTitle != activeTrip.tripMetadata.name) {
          _canUpdateTripTitleNotifier.value = true;
        } else {
          _canUpdateTripTitleNotifier.value = false;
        }
      },
      decoration: InputDecoration(
          suffixIcon: Padding(
        padding: const EdgeInsets.all(3.0),
        child: PlatformSubmitterFAB.conditionallyEnabled(
          valueNotifier: _canUpdateTripTitleNotifier,
          icon: Icons.check_rounded,
          context: context,
          callback: () {
            var tripManagementBloc =
                BlocProvider.of<TripManagementBloc>(context);
            var tripMetadataModelFacade = activeTrip.tripMetadata;
            tripMetadataModelFacade.name = _titleEditingController.text;
            tripManagementBloc.add(
                UpdateTripEntity<TripMetadataModelFacade>.update(
                    tripEntity: tripMetadataModelFacade));
          },
        ),
      )),
    );
  }

  Widget _buildSplitByIcons(
      BuildContext context, TripMetadataModelFacade tripMetadata) {
    var contributors = tripMetadata.contributors.toList();
    contributors.sort((a, b) => a.compareTo(b));
    var contributorsVsColors = <String, Color>{};
    for (var index = 0; index < contributors.length; index++) {
      var contributor = contributors.elementAt(index);
      contributorsVsColors[contributor] = contributorColors.elementAt(index);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: contributorsVsColors.entries
          .map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3.0),
                child: TextButton.icon(
                    onPressed: null,
                    icon: Container(
                      width: 20,
                      height: _heightOfContributorWidget,
                      decoration: BoxDecoration(
                        color: e.value,
                        shape: BoxShape.circle,
                      ),
                    ),
                    label: FittedBox(child: Text(e.key))) as Widget,
              ))
          .toList()
        ..insert(
            0,
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.0),
              child: _buildAddTripMateField(context),
            )),
    );
  }

  Widget _buildAddTripMateField(BuildContext context) {
    var addTripEditingValueNotifier = ValueNotifier<bool>(false);
    return TextFormField(
      textInputAction: TextInputAction.done,
      controller: _addTripMateFieldEditingController,
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.add_tripmate,
        suffixIcon: PlatformSubmitterFAB.conditionallyEnabled(
          icon: Icons.add,
          context: context,
          valueNotifier: addTripEditingValueNotifier,
          callback: () {
            var tripManagementBloc =
                BlocProvider.of<TripManagementBloc>(context);
            var tripMetadataModelFacade = context.getActiveTrip().tripMetadata;
            var currentContributors = tripMetadataModelFacade.contributors;
            var contributorToAdd = _addTripMateFieldEditingController.text;
            if (!currentContributors.contains(contributorToAdd)) {
              currentContributors.add(contributorToAdd);
              tripManagementBloc.add(
                  UpdateTripEntity<TripMetadataModelFacade>.update(
                      tripEntity: tripMetadataModelFacade));
            }
          },
        ),
        labelText: AppLocalizations.of(context)!.userName,
        icon: Icon(Icons.person_2_rounded),
      ),
      onChanged: (username) {
        var matches = _emailRegExValidator.firstMatch(username);
        final matchedText = matches?.group(0);
        if (matchedText != username) {
          addTripEditingValueNotifier.value = false;
        } else {
          addTripEditingValueNotifier.value = true;
        }
      },
    );
  }

  Widget _buildDateRangeButton(BuildContext context,
      TripMetadataModelFacade tripMetadata, bool isBigLayout) {
    var startDate = tripMetadata.startDate;
    var endDate = tripMetadata.endDate;
    return PlatformFABDateRangePicker(
      initialStartDate: startDate,
      initialEndDate: endDate,
      callback: (startDate, endDate) {
        if (startDate != null && endDate != null) {
          tripMetadata.startDate = startDate;
          tripMetadata.endDate = endDate;
          BlocProvider.of<TripManagementBloc>(context).add(
              UpdateTripEntity<TripMetadataModelFacade>.update(
                  tripEntity: tripMetadata));
        }
      },
    );
  }
}
