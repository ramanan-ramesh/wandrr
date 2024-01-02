import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/contracts/trip_data.dart';
import 'package:wandrr/contracts/trip_metadata.dart';
import 'package:wandrr/platform_elements/date_picker.dart';
import 'package:wandrr/platform_elements/text.dart';
import 'package:wandrr/repositories/trip_management.dart';

import '../../constants.dart';

class TripOverviewTile extends StatelessWidget {
  TripOverviewTile({Key? key}) : super(key: key);

  static const _imageHeight = 250.0;
  static const _assetImage = 'assets/images/planning_the_trip.jpg';
  var _titleEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var activeTrip = RepositoryProvider.of<TripManagement>(context).activeTrip!;
    _titleEditingController.text = activeTrip.tripMetaData.name;
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
            //TODO: Remove this container, and the Column
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
          child: _buildOverviewTile(context, activeTrip),
        )
      ],
    );
  }

  Padding _buildOverviewTile(BuildContext context, TripFacade activeTrip) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: PlatformTextElements.createTextField(
                    border: OutlineInputBorder(),
                    context: context,
                    maxLines: 1,
                    controller: _titleEditingController),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDateRangeButton(context, activeTrip.tripMetaData),
                    _buildSplitByIcons(context, activeTrip.tripMetaData)
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSplitByIcons(
      BuildContext context, TripMetaDataFacade tripMetadata) {
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
      BuildContext context, TripMetaDataFacade tripMetadata) {
    var startDate = tripMetadata.startDate;
    var endDate = tripMetadata.endDate;
    return PlatformFABDateRangePicker(
      initialStartDate: startDate,
      initialEndDate: endDate,
      callback: (startDate, endDate) {},
    );
  }
}
