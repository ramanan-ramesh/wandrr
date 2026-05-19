import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/presentation/app/widgets/option_grid_picker.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/transit/transit_option_metadata.dart';

class TransitOptionPicker extends StatefulWidget {
  final Iterable<TransitOptionMetadata> options;
  final TransitOption? initialTransitOption;
  final ValueChanged<TransitOption>? onChanged;
  final String? overlayTitle;

  const TransitOptionPicker({
    required this.options,
    Key? key,
    this.initialTransitOption,
    this.onChanged,
    this.overlayTitle,
  }) : super(key: key);

  @override
  State<TransitOptionPicker> createState() => _TransitOptionPickerState();
}

class _TransitOptionPickerState extends State<TransitOptionPicker> {
  TransitOption? _selectedValue;
  late final List<TransitOptionMetadata> _metadatas;

  @override
  void initState() {
    super.initState();
    _metadatas = widget.options.toList();
    _selectedValue =
        widget.initialTransitOption ?? _metadatas.first.transitOption;
  }

  @override
  void didUpdateWidget(covariant TransitOptionPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedValue != widget.initialTransitOption) {
      setState(() => _selectedValue = widget.initialTransitOption);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('TransitEditor_TransitOptionPicker_DropdownButton'),
      child: OptionGridPicker<TransitOption>(
        items: _metadatas
            .map((m) => OptionGridItem<TransitOption>(
                  value: m.transitOption,
                  icon: m.icon,
                  label: m.name,
                ))
            .toList(),
        selectedValue: _selectedValue,
        overlayTitle: widget.overlayTitle,
        onChanged: widget.onChanged == null
            ? null
            : (value) {
                setState(() => _selectedValue = value);
                widget.onChanged!(value);
              },
      ),
    );
  }
}
