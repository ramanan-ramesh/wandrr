import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/lodging.dart';

class LodgingCardBase extends StatelessWidget {
  final LodgingFacade lodgingFacade;
  final Widget location;
  final Widget dateTime;
  final Widget notes;
  final Widget confirmationId;
  final Widget expense;
  final bool isEditable;

  const LodgingCardBase({
    super.key,
    required this.lodgingFacade,
    required this.location,
    required this.dateTime,
    required this.notes,
    required this.confirmationId,
    required this.expense,
    required this.isEditable,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _createAdaptiveLayout(context),
          const SizedBox(height: 12.0),
          if (!isEditable) Divider(),
          notes,
        ],
      ),
    );
  }

  Widget _createAdaptiveLayout(BuildContext context) {
    if (context.isBigLayout) {
      return Row(
        children: [
          Expanded(
            flex: 3,
            child: _createLocationTimeBox(context),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                confirmationId,
                const SizedBox(height: 4.0),
                expense,
              ],
            ),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.center,
            child: _createLocationTimeBox(context),
          ),
          const SizedBox(height: 4.0),
          confirmationId,
          const SizedBox(height: 4.0),
          expense,
        ],
      );
    }
  }

  Container _createLocationTimeBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: context.isLightTheme ? Colors.teal : Colors.grey.shade700,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          location,
          const SizedBox(height: 4.0),
          dateTime,
        ],
      ),
    );
  }
}
