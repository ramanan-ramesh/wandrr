import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/budgeting/currency_data.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';

/// Read-only total expense display with a currency picker button.
/// The amount is displayed as plain text (not editable) with a button
/// to change the currency that opens a searchable dropdown.
class TotalExpenseDisplay extends StatefulWidget {
  final double amount;
  final CurrencyData selectedCurrency;
  final Iterable<CurrencyData> allCurrencies;
  final Function(CurrencyData) onCurrencySelected;

  const TotalExpenseDisplay({
    super.key,
    required this.amount,
    required this.selectedCurrency,
    required this.allCurrencies,
    required this.onCurrencySelected,
  });

  @override
  State<TotalExpenseDisplay> createState() => _TotalExpenseDisplayState();
}

class _TotalExpenseDisplayState extends State<TotalExpenseDisplay> {
  bool _isSearchingCurrency = false;
  late TextEditingController _searchController;
  late List<CurrencyData> _filteredCurrencies;
  final FocusNode _searchFocusNode = FocusNode();
  final GlobalKey _buttonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredCurrencies = widget.allCurrencies.toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isSearchingCurrency = !_isSearchingCurrency;
      if (_isSearchingCurrency) {
        _searchController.clear();
        _filteredCurrencies = widget.allCurrencies.toList();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFocusNode.requestFocus();
        });
      }
    });
  }

  void _updateSearch(String searchText) {
    setState(() {
      if (searchText.isEmpty) {
        _filteredCurrencies = widget.allCurrencies.toList();
      } else {
        final searchLower = searchText.toLowerCase();
        final byName = widget.allCurrencies.where(
          (c) => c.name.toLowerCase().contains(searchLower),
        );
        final byCode = widget.allCurrencies.where(
          (c) => c.code.toLowerCase().contains(searchLower),
        );
        _filteredCurrencies = [
          ...byName,
          ...byCode.where((c) => !byName.contains(c))
        ];
      }
    });
  }

  void _selectCurrency(CurrencyData currency) {
    setState(() {
      _isSearchingCurrency = false;
    });
    widget.onCurrencySelected(currency);
  }

  @override
  Widget build(BuildContext context) {
    if (_isSearchingCurrency) {
      return _buildCurrencySearchMode(context);
    } else {
      return _buildDisplayMode(context);
    }
  }

  Widget _buildDisplayMode(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final formattedAmount = widget.amount.toStringAsFixed(2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isLightTheme
            ? Colors.grey.shade100
            : Colors.grey.shade800.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLightTheme ? Colors.grey.shade300 : Colors.grey.shade700,
        ),
      ),
      child: Row(
        key: _buttonKey,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Currency button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleMode,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isLightTheme
                      ? AppColors.brandPrimary.withValues(alpha: 0.1)
                      : AppColors.brandPrimaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isLightTheme
                        ? AppColors.brandPrimary.withValues(alpha: 0.3)
                        : AppColors.brandPrimaryLight.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.selectedCurrency.symbol,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isLightTheme
                                ? AppColors.brandPrimary
                                : AppColors.brandPrimaryLight,
                          ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 20,
                      color: isLightTheme
                          ? AppColors.brandPrimary
                          : AppColors.brandPrimaryLight,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Amount display (read-only)
          Text(
            formattedAmount,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencySearchMode(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return Container(
      constraints: const BoxConstraints(minWidth: 280),
      decoration: BoxDecoration(
        color: isLightTheme ? Colors.white : Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              autofocus: true,
              onChanged: _updateSearch,
              decoration: InputDecoration(
                hintText: context.localizations.searchForCurrency,
                prefixIcon: IconButton(
                  onPressed: _toggleMode,
                  icon: Icon(
                    Icons.close,
                    color: isLightTheme
                        ? Colors.grey.shade600
                        : Colors.grey.shade400,
                  ),
                ),
                suffixIcon: Icon(
                  Icons.search,
                  color: isLightTheme
                      ? Colors.grey.shade600
                      : Colors.grey.shade400,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              textInputAction: TextInputAction.done,
            ),
          ),
          // Currency list
          if (_filteredCurrencies.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shrinkWrap: true,
                itemCount: _filteredCurrencies.length,
                itemBuilder: (context, index) {
                  final currency = _filteredCurrencies[index];
                  final isSelected = currency == widget.selectedCurrency;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: ListTile(
                      dense: true,
                      selected: isSelected,
                      selectedTileColor: isLightTheme
                          ? AppColors.brandPrimary.withValues(alpha: 0.1)
                          : AppColors.brandPrimaryLight.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onTap: () => _selectCurrency(currency),
                      leading: Text(
                        currency.symbol,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      title: Text(
                        currency.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(currency.code),
                      trailing: isSelected
                          ? Icon(
                              Icons.check,
                              color: isLightTheme
                                  ? AppColors.success
                                  : AppColors.successLight,
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
