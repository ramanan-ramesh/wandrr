import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/budgeting/currency_data.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';

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
    if (renderBox == null) {
      return;
    }

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
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final accentColor =
        isLight ? AppColors.brandPrimary : AppColors.brandPrimaryLight;
    return Material(
      color: accentColor.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            selectedCurrency.symbol,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
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
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
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
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * -6),
                    child: child,
                  ),
                ),
                child: Material(
                  elevation: 8.0,
                  shadowColor: (isLight ? AppColors.neutral900 : Colors.black)
                      .withValues(alpha: 0.18),
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context),
                      child: SizedBox(
                        width: triggerSize.width,
                        child: ConstrainedBox(
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
          scrollPadding: const EdgeInsets.only(top: 24.0, bottom: 50),
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
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final accentColor =
        isLight ? AppColors.brandPrimary : AppColors.brandPrimaryLight;
    final selectedBg = accentColor.withValues(alpha: 0.10);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: width,
      decoration: BoxDecoration(
        color:
            isSelected && !isDropDownButton ? selectedBg : Colors.transparent,
        border: !isDropDownButton
            ? Border(
                left: BorderSide(
                  color: isSelected ? accentColor : Colors.transparent,
                  width: 3,
                ),
              )
            : null,
      ),
      child: InkWell(
        onTap: isDropDownButton ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              // Symbol badge
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accentColor.withValues(
                      alpha: isSelected || isDropDownButton ? 0.25 : 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    currency.symbol,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Name + code
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currency.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isSelected || isDropDownButton
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: isSelected || isDropDownButton
                            ? accentColor
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      currency.code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              if (isDropDownButton)
                Icon(Icons.arrow_drop_down_rounded,
                    color: accentColor, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
