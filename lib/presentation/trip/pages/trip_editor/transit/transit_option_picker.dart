import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/transit_option_metadata.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';

class TransitOptionPicker extends StatefulWidget {
  final Iterable<TransitOptionMetadata> options;
  final TransitOption? initialTransitOption;
  final ValueChanged<TransitOption>? onChanged;

  const TransitOptionPicker({
    required this.options,
    Key? key,
    this.initialTransitOption,
    this.onChanged,
  }) : super(key: key);

  @override
  _TransitOptionPickerState createState() => _TransitOptionPickerState();
}

class _TransitOptionPickerState extends State<TransitOptionPicker> {
  static const double _kIconSize = 24.0;
  static const double _kBorderRadius = 12.0;
  static const double _kBorderWidth = 1.5;
  static const EdgeInsets _kHorizontalPadding =
      EdgeInsets.symmetric(horizontal: 12.0);

  TransitOption? _selectedValue;
  late final List<TransitOptionMetadata> transitOptionMetadatas;

  @override
  void initState() {
    super.initState();
    transitOptionMetadatas = widget.options.toList();
    _selectedValue = widget.initialTransitOption ??
        transitOptionMetadatas.first.transitOption;
  }

  @override
  void didUpdateWidget(covariant TransitOptionPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedValue != widget.initialTransitOption) {
      setState(() {
        _selectedValue = widget.initialTransitOption;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final borderColor = isLightTheme
        ? AppColors.brandPrimary.withValues(alpha: 0.4)
        : AppColors.brandPrimaryLight.withValues(alpha: 0.4);
    final textColor =
        isLightTheme ? AppColors.brandSecondary : AppColors.neutral100;
    final iconColor =
        isLightTheme ? AppColors.brandPrimary : AppColors.brandPrimaryLight;
    final triggerBgColor = isLightTheme
        ? AppColors.lightSurface.withValues(alpha: 0.95)
        : AppColors.darkSurfaceVariant.withValues(alpha: 0.8);

    return Container(
      padding: _kHorizontalPadding,
      decoration: BoxDecoration(
        color: triggerBgColor,
        borderRadius: BorderRadius.circular(_kBorderRadius),
        border: Border.all(
          color: borderColor,
          width: _kBorderWidth,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TransitOption>(
          value: _selectedValue,
          icon: Icon(Icons.arrow_drop_down_rounded, color: iconColor),
          items: transitOptionMetadatas.map((metadata) {
            return DropdownMenuItem<TransitOption>(
              value: metadata.transitOption,
              child: Row(
                children: [
                  Icon(metadata.icon, color: iconColor, size: _kIconSize),
                  SizedBox(width: 12.0),
                  Text(
                    metadata.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedValue = newValue;
            });
            if (newValue != null) {
              widget.onChanged?.call(newValue);
            }
          },
        ),
      ),
    );
  }
}
