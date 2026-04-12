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
        : _TransitOperatorTextField(
            initialOperator: initialOperator,
            onOperatorChanged: onOperatorChanged,
          );

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
}

/// Stateful text field that preserves its own TextEditingController
/// across parent rebuilds, preventing focus loss and backwards text entry.
class _TransitOperatorTextField extends StatefulWidget {
  final String? initialOperator;
  final Function(String?) onOperatorChanged;

  const _TransitOperatorTextField({
    required this.initialOperator,
    required this.onOperatorChanged,
  });

  @override
  State<_TransitOperatorTextField> createState() =>
      _TransitOperatorTextFieldState();
}

class _TransitOperatorTextFieldState extends State<_TransitOperatorTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialOperator ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _TransitOperatorTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update text externally if the initial value changed AND
    // the new value differs from what the user is currently typing.
    // This prevents overwriting user input during parent rebuilds.
    if (oldWidget.initialOperator != widget.initialOperator &&
        widget.initialOperator != _controller.text) {
      _controller.text = widget.initialOperator ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const ValueKey('TransitEditor_TransitOperator_TextField'),
      minLines: 1,
      maxLines: 1,
      controller: _controller,
      decoration: InputDecoration(
        labelText: context.localizations.carrierName,
        prefixIcon: const Icon(
          Icons.directions_bus,
        ),
      ),
      onChanged: widget.onOperatorChanged,
    );
  }
}
