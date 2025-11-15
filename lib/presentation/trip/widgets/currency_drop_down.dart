import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/budgeting/currency_data.dart';
import 'package:wandrr/l10n/extension.dart';

/// Controller for managing currency dropdown state and overlay lifecycle.
/// Handles opening/closing dropdown overlay and managing layer link positioning.
class CurrencyDropdownController {
  OverlayEntry? _overlayEntry;
  final LayerLink layerLink = LayerLink();

  bool get isOpen => _overlayEntry != null;

  void open(BuildContext context, OverlayEntry entry) {
    if (_overlayEntry == null) {
      _overlayEntry = entry;
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  void close() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void dispose() {
    close();
  }
}

/// Standalone currency selector dropdown.
class PlatformCurrencyDropDown extends StatefulWidget {
  final CurrencyData selectedCurrency;
  final Iterable<CurrencyData> allCurrencies;
  final Function(CurrencyData) onCurrencySelected;

  const PlatformCurrencyDropDown({
    required this.selectedCurrency,
    required this.allCurrencies,
    required this.onCurrencySelected,
    super.key,
  });

  @override
  State<PlatformCurrencyDropDown> createState() =>
      _PlatformCurrencyDropDownState();
}

class _PlatformCurrencyDropDownState extends State<PlatformCurrencyDropDown> {
  late CurrencyDropdownController _controller;
  late CurrencyData _selectedCurrency;

  @override
  void initState() {
    super.initState();
    _controller = CurrencyDropdownController();
    _selectedCurrency = widget.selectedCurrency;
  }

  @override
  void didUpdateWidget(covariant PlatformCurrencyDropDown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCurrency != oldWidget.selectedCurrency) {
      _selectedCurrency = widget.selectedCurrency;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_controller.isOpen) {
      _controller.close();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;

    final entry = OverlayEntry(
      builder: (context) => _CurrencyDropdownOverlay(
        controller: _controller,
        allCurrencies: widget.allCurrencies,
        selectedCurrency: _selectedCurrency,
        onCurrencySelected: (currency) {
          setState(() {
            _selectedCurrency = currency;
          });
          widget.onCurrencySelected(currency);
        },
        onClose: () {
          _controller.close();
          setState(() {});
        },
        layerLink: _controller.layerLink,
        triggerSize: size,
        prefix: _CurrencyButton(
          selectedCurrency: _selectedCurrency,
          onPressed: _toggleDropdown,
          layerLink: _controller.layerLink,
        ),
      ),
    );

    _controller.open(context, entry);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _controller.layerLink,
      child: InkWell(
        onTap: _toggleDropdown,
        child: _CurrencyListTile(
          currency: _selectedCurrency,
          selectedCurrency: _selectedCurrency,
          width: 100,
          isDropDownButton: true,
          onTap: _toggleDropdown,
        ),
      ),
    );
  }
}

/// Button widget for toggling currency dropdown.
class _CurrencyButton extends StatelessWidget {
  final CurrencyData selectedCurrency;
  final VoidCallback onPressed;
  final LayerLink layerLink;

  const _CurrencyButton({
    required this.selectedCurrency,
    required this.onPressed,
    required this.layerLink,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        icon: Text(
          selectedCurrency.symbol,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}

/// Dropdown overlay containing the searchable currency menu.
class _CurrencyDropdownOverlay extends StatelessWidget {
  final CurrencyDropdownController controller;
  final Iterable<CurrencyData> allCurrencies;
  final CurrencyData selectedCurrency;
  final Function(CurrencyData) onCurrencySelected;
  final VoidCallback onClose;
  final LayerLink layerLink;
  final Size triggerSize;
  final Widget? prefix;

  const _CurrencyDropdownOverlay({
    required this.controller,
    required this.allCurrencies,
    required this.selectedCurrency,
    required this.onCurrencySelected,
    required this.onClose,
    required this.layerLink,
    required this.triggerSize,
    this.prefix,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onClose,
      child: Stack(
        children: [
          CompositedTransformFollower(
            link: layerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            child: GestureDetector(
              onTap: () {},
              child: Material(
                elevation: 4.0,
                color: Theme.of(context).dialogTheme.backgroundColor,
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context),
                  child: SizedBox(
                    width: triggerSize.width,
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: _CurrencySearchableDropdown(
                        allCurrencies: allCurrencies,
                        selectedCurrency: selectedCurrency,
                        onCurrencySelected: onCurrencySelected,
                        onClose: onClose,
                        prefix: prefix,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Searchable dropdown menu for currency selection.
class _CurrencySearchableDropdown extends StatefulWidget {
  final Iterable<CurrencyData> allCurrencies;
  final CurrencyData selectedCurrency;
  final Function(CurrencyData) onCurrencySelected;
  final VoidCallback onClose;
  final Widget? prefix;

  const _CurrencySearchableDropdown({
    required this.allCurrencies,
    required this.selectedCurrency,
    required this.onCurrencySelected,
    required this.onClose,
    this.prefix,
    super.key,
  });

  @override
  State<_CurrencySearchableDropdown> createState() =>
      _CurrencySearchableDropdownState();
}

class _CurrencySearchableDropdownState
    extends State<_CurrencySearchableDropdown> {
  late List<CurrencyData> _filteredCurrencies;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _filteredCurrencies = widget.allCurrencies.toList();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateSearch(String searchText) {
    _filteredCurrencies.clear();
    if (searchText.isEmpty) {
      _filteredCurrencies.addAll(widget.allCurrencies);
    } else {
      final searchLower = searchText.toLowerCase();
      final byName = widget.allCurrencies.where(
        (c) => c.name.toLowerCase().contains(searchLower),
      );
      final byCode = widget.allCurrencies.where(
        (c) => c.code.toLowerCase().contains(searchLower),
      );

      _filteredCurrencies.addAll(byName);
      _filteredCurrencies.addAll(
        byCode.where((c) => !_filteredCurrencies.contains(c)),
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: _updateSearch,
          decoration: InputDecoration(
            hintText: context.localizations.searchForCurrency,
            prefixIcon: widget.prefix ?? const Icon(Icons.search_rounded),
          ),
          textInputAction: TextInputAction.done,
        ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: ListView(
              // padding: EdgeInsets.all(8.0),
              shrinkWrap: true,
              children: _filteredCurrencies
                  .map(
                    (currency) => _CurrencyListTile(
                      currency: currency,
                      selectedCurrency: widget.selectedCurrency,
                      width: double.infinity,
                      onTap: () {
                        widget.onCurrencySelected(currency);
                        widget.onClose();
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

/// Builds a currency list tile with consistent styling.
class _CurrencyListTile extends StatelessWidget {
  final CurrencyData currency;
  final CurrencyData selectedCurrency;
  final VoidCallback onTap;
  final double width;
  final bool isDropDownButton;

  const _CurrencyListTile({
    required this.currency,
    required this.selectedCurrency,
    required this.onTap,
    required this.width,
    this.isDropDownButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currency == selectedCurrency;
    final textColor = isSelected || isDropDownButton
        ? Theme.of(context).listTileTheme.selectedColor
        : Theme.of(context).listTileTheme.textColor;
    final backgroundColor = isSelected
        ? Theme.of(context).listTileTheme.selectedTileColor
        : Theme.of(context).listTileTheme.tileColor;

    return SizedBox(
      height: 30,
      width: width,
      child: Container(
        color: backgroundColor,
        child: InkWell(
          onTap: isDropDownButton ? null : onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.0),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    currency.symbol,
                    style: TextStyle(
                      fontSize:
                          Theme.of(context).textTheme.titleLarge!.fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          currency.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: textColor),
                        ),
                      ),
                      Text(
                        currency.code,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: textColor),
                      ),
                    ],
                  ),
                ),
              ),
              if (isDropDownButton)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3.0),
                  child: Icon(Icons.arrow_drop_down),
                )
            ],
          ),
        ),
      ),
    );
  }
}
