import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';

class LodgingCardBase extends StatelessWidget {
  final LodgingFacade lodgingFacade;
  final Widget location;
  final Widget dateTime;
  final Widget notes;
  final Widget confirmationId;
  final Widget expense;
  final bool isEditable;

  const LodgingCardBase({
    required this.lodgingFacade,
    required this.location,
    required this.dateTime,
    required this.notes,
    required this.confirmationId,
    required this.expense,
    required this.isEditable,
    super.key,
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
          if (!isEditable) const Divider(),
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
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
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
        color: context.isLightTheme
            ? AppColors.brandPrimaryLight.withValues(alpha: 0.7)
            : AppColors.brandPrimaryDark.withValues(alpha: 0.7),
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
