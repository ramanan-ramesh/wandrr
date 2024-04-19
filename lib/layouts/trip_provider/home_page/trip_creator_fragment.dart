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

import 'home_page_content.dart';

class TripCreatorFragment implements HomePageContent {
  TripCreatorFragment({required BuildContext context, VoidCallback? callback})
      : _tripCreationMetadataNotifier =
            ValueNotifier<_TripCreationMetadata>(_TripCreationMetadata()),
        _context = context {
    _floatingActionButton = _buildFloatingActionButton(callback);
    _body = _buildBody();
  }

  @override
  Widget? get floatingActionButton => _floatingActionButton;
  Widget? _floatingActionButton;

  @override
  Widget? get body => _body;
  Widget? _body;

  final ValueNotifier<_TripCreationMetadata> _tripCreationMetadataNotifier;

  final BuildContext _context;

  final TextEditingController _tripNameEditingController =
      TextEditingController();

  void _updateLocation(Location location) {
    var currentMetadata = _tripCreationMetadataNotifier.value;
    _tripCreationMetadataNotifier.value =
        currentMetadata.copyWith(location: location);
  }

  void _updateTripName(String newTripName) {
    var currentMetadata = _tripCreationMetadataNotifier.value;
    _tripCreationMetadataNotifier.value =
        currentMetadata.copyWith(name: newTripName);
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
                var currentMetadata = _tripCreationMetadataNotifier.value;
                if (_isTripCreateRequestValid(currentMetadata)) {
                  var userName =
                      RepositoryProvider.of<PlatformDataRepository>(_context)
                          .appLevelData
                          .activeUser!
                          .userName;
                  var tripManagement =
                      BlocProvider.of<TripManagementBloc>(_context);
                  tripManagement.add(UpdateTripMetadata.create(
                      tripMetadataUpdator: TripMetadataUpdator.create(
                          startDate: currentMetadata.startDate!,
                          endDate: currentMetadata.endDate!,
                          name: currentMetadata.name!,
                          contributors: [userName],
                          location: currentMetadata.location!)));
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

  bool _isTripCreateRequestValid(_TripCreationMetadata tripCreationMetadata) {
    var hasValidName = tripCreationMetadata.name != null &&
        tripCreationMetadata.name!.isNotEmpty;
    var hasValidDateRange = tripCreationMetadata.startDate != null &&
        tripCreationMetadata.endDate != null;
    var hasValidLocation = tripCreationMetadata.location != null;
    return hasValidName && hasValidDateRange && hasValidLocation;
  }

  Widget _buildFloatingActionButton(VoidCallback? callback) {
    bool keyboardIsOpened = MediaQuery.of(_context).viewInsets.bottom != 0.0;
    return ValueListenableBuilder<_TripCreationMetadata>(
      valueListenable: _tripCreationMetadataNotifier,
      builder: (context, tripCreationMetadata, widget) {
        var canEnableFAB = _isTripCreateRequestValid(tripCreationMetadata);
        bool keyboardIsOpened =
            MediaQuery.of(_context).viewInsets.bottom != 0.0;
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: PlatformTextElements.createHeader(
              context: _context, text: AppLocalizations.of(_context)!.planTrip),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: _buildLocationAutoComplete(_context),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: InkWell(
                  splashColor: Colors.white,
                  child: Container(
                      color: Colors.black12,
                      child: _buildTripNameField(_context)),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: PlatformDateRangePicker(
                  callback: (startDate, endDate) {
                    var currentMetadata = _tripCreationMetadataNotifier.value;
                    _tripCreationMetadataNotifier.value = currentMetadata
                        .copyWith(startDate: startDate, endDate: endDate);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTripNameField(BuildContext context) {
    return PlatformTextElements.createTextField(
        context: context,
        labelText: AppLocalizations.of(context)!.tripName,
        onTextChanged: _updateTripName,
        border: OutlineInputBorder(),
        controller: _tripNameEditingController);
  }

  Widget _buildLocationAutoComplete(BuildContext context) {
    return ValueListenableBuilder<_TripCreationMetadata>(
      valueListenable: _tripCreationMetadataNotifier,
      builder: (context, tripCreationMetadata, widget) {
        var initialText = tripCreationMetadata.location?.toString();
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

class _TripCreationMetadata {
  DateTime? startDate;
  DateTime? endDate;
  String? name;
  Location? location;

  _TripCreationMetadata copyWith(
      {DateTime? startDate,
      DateTime? endDate,
      String? name,
      BuildContext? context,
      Location? location}) {
    var tripCreationMetadata = _TripCreationMetadata();
    tripCreationMetadata.name = name ?? this.name;
    tripCreationMetadata.endDate = endDate ?? this.endDate;
    tripCreationMetadata.startDate = startDate ?? this.startDate;
    tripCreationMetadata.location = location ?? this.location;
    return tripCreationMetadata;
  }

  bool isValid() {
    var isNameValid = name != null && name!.isNotEmpty;
    var isDateRangeValid = startDate != null && endDate != null;
    var isLocationValid = location != null;
    return isNameValid && isDateRangeValid && isLocationValid;
  }
}
