import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wandrr/blocs/trip_management_bloc/bloc.dart';
import 'package:wandrr/blocs/trip_management_bloc/events.dart';
import 'package:wandrr/contracts/communicators.dart';
import 'package:wandrr/contracts/location.dart';
import 'package:wandrr/platform_elements/date_picker.dart';
import 'package:wandrr/platform_elements/text.dart';
import 'package:wandrr/repositories/platform_data_repository.dart';

import 'home_page.dart';

class TripCreatorFragment implements HomePageContent {
  TripCreatorFragment(
      {required BuildContext context,
      VoidCallback? callback,
      required this.maxWidth})
      : _fragmentData =
            ValueNotifier<_FragmentData>(_FragmentData(context: context)) {
    _floatingActionButton = _buildFloatingActionButton(callback);
    _body = _buildBody();
    _textEditingController.addListener(() {
      var currentTripName = _textEditingController.text;
      if (currentTripName.isEmpty || currentTripName.length == 1) {
        var fragmentData = _fragmentData.value;
        _fragmentData.value = fragmentData.copyWith(name: currentTripName);
      }
    });
  }

  final ValueNotifier<_FragmentData> _fragmentData;

  Widget? _floatingActionButton;

  Widget? _body;

  final TextEditingController _textEditingController = TextEditingController();
  final double maxWidth;

  @override
  void updateContext(BuildContext context) {
    var oldFragmentData = _fragmentData.value;
    _fragmentData.value = oldFragmentData.copyWith(context: context);
  }

  void _updateLocation(Location location) {
    var oldFragmentData = _fragmentData.value;
    _fragmentData.value = oldFragmentData.copyWith(location: location);
  }

  void _updateTripName(String newTripName) {
    var oldFragmentData = _fragmentData.value;
    _fragmentData.value = oldFragmentData.copyWith(name: newTripName);
  }

  @override
  Widget? get floatingActionButton {
    return _floatingActionButton;
  }

  @override
  Widget? get body {
    return _body;
  }

  Widget _createFABFromParameters(
      bool keyboardIsOpened, VoidCallback? callback, bool isEnabled) {
    return Visibility(
      visible: !keyboardIsOpened,
      child: FloatingActionButton(
        backgroundColor: isEnabled ? Colors.black : Colors.white54,
        onPressed: isEnabled
            ? () {
                callback?.call();
                var fragmentData = _fragmentData.value;
                if (_isTripCreateRequestValid(fragmentData)) {
                  var userName = RepositoryProvider.of<PlatformDataRepository>(
                          fragmentData.context)
                      .appLevelData
                      .activeUser!
                      .userName;
                  var tripManagement =
                      BlocProvider.of<TripManagementBloc>(fragmentData.context);
                  tripManagement.add(UpdateTripMetadata.create(
                      tripMetadataUpdator: TripMetadataUpdator.create(
                          startDate: fragmentData.startDate!,
                          endDate: fragmentData.endDate!,
                          name: fragmentData.name!,
                          contributors: [userName],
                          location: fragmentData.location!)));
                }
              }
            : null,
        child: Icon(
          Icons.check,
          color: isEnabled ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  bool _isTripCreateRequestValid(_FragmentData fragmentData) {
    var hasValidName =
        fragmentData.name != null && fragmentData.name!.isNotEmpty;
    var hasValidDateRange =
        fragmentData.startDate != null && fragmentData.endDate != null;
    var hasValidLocation = fragmentData.location != null;
    return hasValidName && hasValidDateRange && hasValidLocation;
  }

  Widget _buildFloatingActionButton(VoidCallback? callback) {
    bool keyboardIsOpened =
        MediaQuery.of(_fragmentData.value.context).viewInsets.bottom != 0.0;
    return ValueListenableBuilder<_FragmentData>(
      valueListenable: _fragmentData,
      builder: (context, fragmentData, widget) {
        var canEnableFAB = _isTripCreateRequestValid(fragmentData);
        bool keyboardIsOpened =
            MediaQuery.of(_fragmentData.value.context).viewInsets.bottom != 0.0;
        if (canEnableFAB) {
          return _createFABFromParameters(keyboardIsOpened, callback, true);
        } else {
          if (widget != null) {
            return widget;
          }
          return _createFABFromParameters(keyboardIsOpened, callback, false);
        }
      },
      child: _createFABFromParameters(keyboardIsOpened, callback, false),
    );
  }

  Widget _buildBody() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        var width =
            constraints.minWidth / 2 >= 500.0 ? 500.0 : constraints.maxWidth;
        return Center(
          child: SizedBox(
            width: width,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: PlatformTextElements.createHeader(
                      context: context,
                      text: AppLocalizations.of(context)!.planTrip),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: _buildLocationAutoComplete(context),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: InkWell(
                          splashColor: Colors.white,
                          child: Container(
                              color: Colors.black12,
                              child: _buildTripNameField(context)),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: PlatformDateRangePicker(
                          callback: (startDate, endDate) {
                            var currentFragmentData = _fragmentData.value;
                            _fragmentData.value = currentFragmentData.copyWith(
                                startDate: startDate, endDate: endDate);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTripNameField(BuildContext context) {
    return PlatformTextElements.createTextField(
        context: context,
        labelText: AppLocalizations.of(context)!.tripName,
        onTextChanged: _updateTripName,
        border: OutlineInputBorder(),
        controller: _textEditingController);
  }

  Widget _buildLocationAutoComplete(BuildContext context) {
    return ValueListenableBuilder<_FragmentData>(
      valueListenable: _fragmentData,
      builder: (context, fragmentData, widget) {
        var initialText = fragmentData.location?.toString();
        return PlatformGeoLocationAutoComplete(
          initialText: initialText,
          onLocationSelected: _updateLocation,
        );
      },
      child: PlatformGeoLocationAutoComplete(
        initialText: null,
        onLocationSelected: _updateLocation,
      ),
    );
  }

  @override
  FloatingActionButtonLocation get floatingActionButtonLocation =>
      FloatingActionButtonLocation.centerFloat;
}

class _FragmentData {
  DateTime? startDate;
  DateTime? endDate;
  String? name;
  BuildContext context;
  Location? location;

  _FragmentData({required this.context});

  _FragmentData copyWith(
      {DateTime? startDate,
      DateTime? endDate,
      String? name,
      BuildContext? context,
      Location? location}) {
    _FragmentData fragmentData = context == null
        ? _FragmentData(context: this.context)
        : _FragmentData(context: context);
    fragmentData.name = name ?? this.name;
    fragmentData.endDate = endDate ?? this.endDate;
    fragmentData.startDate = startDate ?? this.startDate;
    fragmentData.location = location ?? this.location;
    return fragmentData;
  }
}
