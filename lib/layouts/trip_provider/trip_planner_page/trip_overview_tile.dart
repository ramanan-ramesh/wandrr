import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/trip_management/bloc.dart';
import 'package:wandrr/blocs/trip_management/events.dart';
import 'package:wandrr/contracts/trip_data.dart';
import 'package:wandrr/contracts/trip_metadata.dart';
import 'package:wandrr/contracts/trip_repository.dart';
import 'package:wandrr/layouts/constants.dart';
import 'package:wandrr/platform_elements/button.dart';
import 'package:wandrr/platform_elements/date_picker.dart';
import 'package:wandrr/platform_elements/form.dart';

class TripOverviewTile extends StatelessWidget {
  TripOverviewTile({Key? key}) : super(key: key);

  static const _imageHeight = 250.0;
  static const _assetImage = 'assets/images/planning_the_trip.jpg';
  late TextEditingController _titleEditingController = TextEditingController();
  final _canUpdateTripTitleNotifier = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    var activeTrip =
        RepositoryProvider.of<TripRepositoryModelFacade>(context).activeTrip!;
    _titleEditingController.text = activeTrip.tripMetadata.name;
    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(
              _assetImage,
              fit: BoxFit.cover,
              height: _imageHeight,
            ),
            Container(
              height: 200,
              color: Colors.black12,
            ),
          ],
        ),
        Positioned(
          left: 10,
          right: 10,
          top: 230,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: 200,
            ),
            child: _buildOverviewTile(context, activeTrip),
          ),
        )
      ],
    );
  }

  Padding _buildOverviewTile(
      BuildContext context, TripDataModelFacade activeTrip) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildTitleEditingField(activeTrip, context),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDateRangeButton(context, activeTrip.tripMetadata),
                    _buildSplitByIcons(context, activeTrip.tripMetadata)
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PlatformTextField _buildTitleEditingField(
      TripDataModelFacade activeTrip, BuildContext context) {
    return PlatformTextField(
      controller: _titleEditingController,
      onTextChanged: (newTitle) {
        if (newTitle.isNotEmpty && newTitle != activeTrip.tripMetadata.name) {
          _canUpdateTripTitleNotifier.value = true;
        } else {
          _canUpdateTripTitleNotifier.value = false;
        }
      },
      suffix: PlatformSubmitterFAB.conditionallyEnabled(
        valueNotifier: _canUpdateTripTitleNotifier,
        icon: Icons.check_rounded,
        context: context,
        callback: () {
          var tripManagementBloc = BlocProvider.of<TripManagementBloc>(context);
          var tripMetadataModelFacade = activeTrip.tripMetadata;
          tripMetadataModelFacade.name = _titleEditingController.text;
          tripManagementBloc.add(
              UpdateTripEntity<TripMetadataModelFacade>.update(
                  tripEntity: tripMetadataModelFacade));
        },
      ),
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
      children: contributorsVsColors.entries
          .map((e) => Row(
                children: [
                  TextButton.icon(
                      onPressed: null,
                      icon: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: e.value,
                          shape: BoxShape.circle,
                        ),
                      ),
                      label: Text(e.key))
                ],
              ))
          .toList(),
    );
  }

  Widget _buildDateRangeButton(
      BuildContext context, TripMetadataModelFacade tripMetadata) {
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
