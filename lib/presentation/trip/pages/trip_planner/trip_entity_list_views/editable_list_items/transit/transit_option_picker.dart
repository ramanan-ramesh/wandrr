import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/transit_option_metadata.dart';

class TransitOptionPicker extends StatefulWidget {
  final Iterable<TransitOptionMetadata> options;
  final TransitOption? initialTransitOption;
  final ValueChanged<TransitOption>? onChanged;

  const TransitOptionPicker({
    Key? key,
    required this.options,
    this.initialTransitOption,
    this.onChanged,
  }) : super(key: key);

  @override
  _TransitOptionPickerState createState() => _TransitOptionPickerState();
}

class _TransitOptionPickerState extends State<TransitOptionPicker>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isDropdownOpen = false;
  TransitOption? _selectedValue;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  double? _triggerWidth;
  int? _selectedIndex;
  final double _itemHeight = 48.0;
  late final List<TransitOptionMetadata> transitOptionMetadatas;

  @override
  void initState() {
    super.initState();
    transitOptionMetadatas = widget.options.toList();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _calculateMaxTriggerWidth();
    _selectedValue = widget.initialTransitOption;
    _shuffleMetadataListOnSelection();
    _updateSelectedIndex(_selectedValue);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  void _shuffleMetadataListOnSelection() {
    var indexOfCurrentTransitOption = transitOptionMetadatas.indexWhere(
      (option) => option.transitOption == _selectedValue,
    );
    var currentTransitOptionMetadata =
        transitOptionMetadatas[indexOfCurrentTransitOption];
    var listWithoutCurrentTransitOption = transitOptionMetadatas
        .where((option) => option.transitOption != _selectedValue)
        .toList();
    transitOptionMetadatas.clear();
    transitOptionMetadatas.addAll(listWithoutCurrentTransitOption.take(3));
    transitOptionMetadatas.add(currentTransitOptionMetadata);
    transitOptionMetadatas.addAll(
      listWithoutCurrentTransitOption.skip(3),
    );
  }

  void _updateSelectedIndex(TransitOption? value) {
    if (value == null) {
      _selectedIndex = 0;
      _selectedValue = transitOptionMetadatas.first.transitOption;
      return;
    }
    final index = transitOptionMetadatas.indexWhere(
      (option) => option.transitOption == value,
    );
    if (index != -1) {
      _selectedIndex = index;
      _selectedValue = value;
    } else {
      _selectedIndex = 0;
      _selectedValue = transitOptionMetadatas.first.transitOption;
    }
  }

  void _calculateMaxTriggerWidth() {
    double maxWidth = 0;
    const TextStyle textStyle = TextStyle(fontWeight: FontWeight.w500);
    const double iconWidth = 24.0 + 12.0;
    const double arrowWidth = 24.0 + 8.0;

    for (final option in transitOptionMetadatas) {
      final TextPainter textPainter = TextPainter(
        text: TextSpan(text: option.name, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      maxWidth = maxWidth > textPainter.width ? maxWidth : textPainter.width;
    }

    setState(() {
      _triggerWidth = maxWidth + iconWidth + arrowWidth + 32.0;
    });
  }

  void _toggleDropdown() {
    setState(() {
      _isDropdownOpen = !_isDropdownOpen;
      if (_isDropdownOpen) {
        _showOverlay();
        _animationController.forward();
      } else {
        _animationController.reverse();
        _hideOverlay();
      }
    });
  }

  void _showOverlay() {
    if (_triggerWidth == null || _selectedIndex == null) {
      return;
    }

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final triggerOffset = renderBox.localToGlobal(Offset.zero);
    final double dropdownHeight = 7 * _itemHeight;
    final double selectedItemOffset = _selectedIndex! * _itemHeight;
    var listScrollController = ScrollController();
    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: () {
          if (_isDropdownOpen) {
            _toggleDropdown();
          }
        },
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned(
              width: _triggerWidth!,
              left: triggerOffset.dx,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0, -(triggerOffset.dy - selectedItemOffset)),
                child: ScaleTransition(
                  scale: _animationController.drive(
                    CurveTween(curve: Curves.fastOutSlowIn),
                  ),
                  alignment: Alignment.center,
                  child: Material(
                    elevation: 4.0,
                    child: ClipRect(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: dropdownHeight),
                        child: Scrollbar(
                          controller: listScrollController,
                          thumbVisibility: true,
                          child: ListView.builder(
                            controller: listScrollController,
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: transitOptionMetadatas.length,
                            itemBuilder: (context, index) {
                              final option = transitOptionMetadatas[index];
                              final isSelected =
                                  option.transitOption == _selectedValue;
                              return _buildDropdownItem(option, isSelected,
                                  onTap: () {
                                _handleOptionSelected(option.transitOption);
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _handleOptionSelected(TransitOption option) {
    _selectedValue = option;
    _shuffleMetadataListOnSelection();
    _updateSelectedIndex(option);
    _toggleDropdown();
    if (widget.onChanged != null) {
      widget.onChanged!(option);
    }
  }

  Widget _buildDropdownItem(
    TransitOptionMetadata metadata,
    bool isSelected, {
    VoidCallback? onTap,
  }) {
    return SizedBox(
      height: _itemHeight,
      width: _triggerWidth,
      child: ListTile(
        onTap: onTap,
        selected: isSelected,
        leading: Icon(metadata.icon),
        title: Text(
          metadata.name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTrigger() {
    final selectedOption = transitOptionMetadatas.firstWhere(
      (option) => option.transitOption == _selectedValue,
      orElse: () => transitOptionMetadatas.first,
    );

    return CompositedTransformTarget(
      link: _layerLink,
      child: SizedBox(
        width: _triggerWidth,
        height: _itemHeight,
        child: InkWell(
          onTap: _toggleDropdown,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  selectedOption.icon,
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      selectedOption.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                RotationTransition(
                  turns: _animationController,
                  child: const Icon(Icons.arrow_drop_down_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_buildTrigger()],
    );
  }
}
