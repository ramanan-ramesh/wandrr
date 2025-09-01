import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/l10n/extension.dart';

class TransitCardBase extends StatelessWidget {
  final Widget transitOption;
  final Widget transitOperator;
  final Widget arrivalLocation;
  final Widget arrivalDateTime;
  final Widget departureLocation;
  final Widget departureDateTime;
  final Widget expenseTile;
  final Widget confirmationId;
  final TransitFacade transitFacade;
  final Widget notes;
  final bool isEditable;

  const TransitCardBase({
    required this.transitOption,
    required this.transitOperator,
    required this.arrivalLocation,
    required this.arrivalDateTime,
    required this.departureLocation,
    required this.departureDateTime,
    required this.expenseTile,
    required this.confirmationId,
    required this.transitFacade,
    required this.notes,
    required this.isEditable,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final doesTransitNeedPriorBooking = _needsPriorBooking();
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, doesTransitNeedPriorBooking),
          const SizedBox(height: 12.0),
          _buildAdaptiveLayout(context, doesTransitNeedPriorBooking),
          const SizedBox(height: 12.0),
          notes,
        ],
      ),
    );
  }

  bool _needsPriorBooking() {
    return !(transitFacade.transitOption == TransitOption.walk ||
        transitFacade.transitOption == TransitOption.vehicle ||
        transitFacade.transitOption == TransitOption.rentedVehicle);
  }

  Widget _buildHeader(BuildContext context, bool doesTransitNeedPriorBooking) {
    return context.isBigLayout
        ? _buildBigLayoutHeader(doesTransitNeedPriorBooking)
        : _buildSmallLayoutHeader(doesTransitNeedPriorBooking);
  }

  Widget _buildBigLayoutHeader(bool doesTransitNeedPriorBooking) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Row(
            children: [
              transitOption,
              if (_shouldDisplayConnectorHeader(doesTransitNeedPriorBooking))
                const Expanded(child: Divider()),
            ],
          ),
        ),
        if (doesTransitNeedPriorBooking)
          Expanded(flex: 2, child: transitOperator),
      ],
    );
  }

  Widget _buildSmallLayoutHeader(bool doesTransitNeedPriorBooking) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: transitOption),
        const SizedBox(width: 12.0),
        if (doesTransitNeedPriorBooking) Flexible(child: transitOperator),
      ],
    );
  }

  bool _shouldDisplayConnectorHeader(bool doesTransitNeedPriorBooking) {
    return (isEditable || transitFacade.operator != null) &&
        doesTransitNeedPriorBooking;
  }

  Widget _buildAdaptiveLayout(
      BuildContext context, bool doesTransitNeedPriorBooking) {
    return context.isBigLayout
        ? _buildBigLayoutBody(context, doesTransitNeedPriorBooking)
        : _buildSmallLayoutBody(context, doesTransitNeedPriorBooking);
  }

  Widget _buildBigLayoutBody(
      BuildContext context, bool doesTransitNeedPriorBooking) {
    if (!doesTransitNeedPriorBooking) {
      return _buildTransitEvents(context);
    }
    return Row(
      children: [
        Expanded(flex: 3, child: _buildTransitEvents(context)),
        Expanded(
          flex: 2,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                confirmationId,
                const SizedBox(height: 12.0),
                expenseTile,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallLayoutBody(
      BuildContext context, bool doesTransitNeedPriorBooking) {
    if (!doesTransitNeedPriorBooking) {
      return _buildTransitEvents(context);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTransitEvents(context),
        const SizedBox(height: 12.0),
        confirmationId,
        const SizedBox(height: 12.0),
        expenseTile,
      ],
    );
  }

  Widget _buildTransitEvents(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _buildTransitEvent(context, false),
              const SizedBox(height: 12.0),
              _buildTransitEvent(context, true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransitEvent(BuildContext context, bool isArrival) {
    final title =
        isArrival ? context.localizations.arrive : context.localizations.depart;
    return Container(
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: context.isLightTheme ? Colors.teal : Colors.grey.shade700,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60.0,
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                isArrival ? arrivalLocation : departureLocation,
                isArrival ? arrivalDateTime : departureDateTime,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
