import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_theme.dart';

import 'flight_details_editor_section.dart';

class TransitOperatorEditorSection extends StatelessWidget {
  final TransitOption transitOption;
  final String? initialOperator;
  final Function(String?) onOperatorChanged;

  const TransitOperatorEditorSection(
      {required this.transitOption,
      required this.onOperatorChanged,
      super.key,
      this.initialOperator});

  @override
  Widget build(BuildContext context) {
    final isLightTheme = context.isLightTheme;
    var icon = transitOption == TransitOption.flight
        ? Icons.flight
        : Icons.directions_bus;
    var iconColor = transitOption == TransitOption.flight
        ? (isLightTheme ? AppColors.info : AppColors.infoLight)
        : (isLightTheme ? AppColors.brandPrimary : AppColors.brandPrimaryLight);
    var title =
        transitOption == TransitOption.flight ? 'Flight Details' : 'Carrier';
    var editor = transitOption == TransitOption.flight
        ? FlightDetailsEditor(
            initialOperator: initialOperator,
            onOperatorChanged: onOperatorChanged,
          )
        : _createTransitOperatorEditingField(context);

    return EditorTheme.createSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (transitOption == TransitOption.flight)
            EditorTheme.createSectionHeader(
              context,
              icon: icon,
              title: title,
              iconColor: iconColor,
              useLargeText: true,
            ),
          const SizedBox(height: 12),
          editor,
        ],
      ),
    );
  }

  Widget _createTransitOperatorEditingField(BuildContext context) {
    var transitOperatorEditingController =
        TextEditingController(text: initialOperator ?? '');

    return TextField(
      minLines: 1,
      maxLines: 1,
      controller: transitOperatorEditingController,
      decoration: InputDecoration(
        labelText: context.localizations.carrierName,
        prefixIcon: Icon(
          Icons.directions_bus,
        ),
      ),
      onChanged: onOperatorChanged,
    );
  }
}
