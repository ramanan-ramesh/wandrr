import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/trip_management_bloc/bloc.dart';
import 'package:wandrr/blocs/trip_management_bloc/events.dart';
import 'package:wandrr/contracts/communicators.dart';
import 'package:wandrr/contracts/trip_data.dart';
import 'package:wandrr/contracts/trip_metadata.dart';
import 'package:wandrr/platform_elements/button.dart';
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
                child: _TitleEditField(
                  tripMetaDataFacade: activeTrip.tripMetaData,
                ),
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

class _TitleEditField extends StatefulWidget {
  const _TitleEditField({
    required this.tripMetaDataFacade,
  });

  final TripMetaDataFacade tripMetaDataFacade;

  @override
  State<_TitleEditField> createState() => _TitleEditFieldState();
}

class _TitleEditFieldState extends State<_TitleEditField> {
  late TextEditingController _editingController = TextEditingController();
  bool _canUpdateField = false;

  @override
  void initState() {
    super.initState();
    _editingController.text = widget.tripMetaDataFacade.name;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: PlatformTextElements.createTextField(
              context: context,
              border: OutlineInputBorder(),
              onTextChanged: (newTitle) {
                if (newTitle.isNotEmpty &&
                    newTitle != widget.tripMetaDataFacade.name) {
                  setState(() {
                    _canUpdateField = true;
                  });
                } else {
                  setState(() {
                    _canUpdateField = false;
                  });
                }
              },
              maxLines: 1,
              controller: _editingController),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 3.0),
          child: PlatformSubmitterFAB(
            icon: Icons.check_rounded,
            context: context,
            backgroundColor: _canUpdateField ? Colors.black : Colors.white12,
            callback: !_canUpdateField
                ? null
                : () {
                    var tripManagementBloc =
                        BlocProvider.of<TripManagementBloc>(context);
                    var tripMetadataUpdator =
                        TripMetadataUpdator.fromTripMetadata(
                            tripMetaDataFacade: widget.tripMetaDataFacade);
                    tripMetadataUpdator.name = _editingController.text;
                    tripManagementBloc.add(UpdateTripMetadata.update(
                        tripMetadataUpdator: tripMetadataUpdator));
                  },
          ),
        ),
      ],
    );
  }
}
