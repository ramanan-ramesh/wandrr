import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/budgeting/currency_data.dart';
import 'package:wandrr/l10n/extension.dart';

import 'expense_amount_edit_field.dart';

/// Editable money field with integrated currency selection.
/// Transforms between expense editing and currency search modes.
class PlatformMoneyEditField extends StatefulWidget {
  final CurrencyData selectedCurrency;
  final Iterable<CurrencyData> allCurrencies;
  final Function(CurrencyData) onCurrencySelected;
  final Function(double) onAmountUpdated;
  final double? initialAmount;
  final bool isAmountEditable;
  final TextInputAction textInputAction;

  const PlatformMoneyEditField({
    required this.selectedCurrency,
    required this.allCurrencies,
    required this.onCurrencySelected,
    required this.onAmountUpdated,
    required this.isAmountEditable,
    this.initialAmount,
    this.textInputAction = TextInputAction.next,
    super.key,
  });

  @override
  State<PlatformMoneyEditField> createState() => _PlatformMoneyEditFieldState();
}

class _PlatformMoneyEditFieldState extends State<PlatformMoneyEditField> {
  late CurrencyData _selectedCurrency;
  bool _isSearchingCurrency = false;
  late TextEditingController _searchController;
  late TextEditingController _amountController;
  late List<CurrencyData> _filteredCurrencies;
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _amountFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.selectedCurrency;
    final initialAmount = widget.initialAmount?.toStringAsFixed(2) ?? '0';
    _searchController = TextEditingController();
    _amountController =
        TextEditingController(text: initialAmount == '0' ? '0' : initialAmount);
    _filteredCurrencies = widget.allCurrencies.toList();
  }

  @override
  void didUpdateWidget(covariant PlatformMoneyEditField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCurrency != oldWidget.selectedCurrency) {
      _selectedCurrency = widget.selectedCurrency;
    }
    if (widget.initialAmount != oldWidget.initialAmount) {
      final newAmount = widget.initialAmount?.toStringAsFixed(2) ?? '0';
      final currentValue = double.tryParse(_amountController.text) ?? 0.0;
      final newValue = double.tryParse(newAmount) ?? 0.0;

      if ((currentValue - newValue).abs() > 0.01) {
        _amountController.text = newAmount == '0' ? '0' : newAmount;
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _amountController.dispose();
    _searchFocusNode.dispose();
    _amountFocusNode.dispose();
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
      _selectedCurrency = currency;
      _isSearchingCurrency = false;
    });
    widget.onCurrencySelected(currency);
  }

  @override
  Widget build(BuildContext context) {
    if (_isSearchingCurrency) {
      return _buildCurrencySearchMode();
    } else {
      return _buildAmountEditMode();
    }
  }

  Widget _buildAmountEditMode() {
    return PlatformExpenseAmountEditField(
      textInputAction: widget.textInputAction,
      isReadonly: !widget.isAmountEditable,
      controller: _amountController,
      focusNode: _amountFocusNode,
      onExpenseAmountChanged: (newValue) {
        widget.onAmountUpdated(newValue);
      },
      inputDecoration: InputDecoration(
        prefixIcon: Material(
          shape: const CircleBorder(),
          child: IconButton(
            key: Key('PlatformMoneyEditField_CurrencyPickerButton'),
            onPressed: _toggleMode,
            icon: Text(
              _selectedCurrency.symbol,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencySearchMode() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          key: Key('PlatformMoneyEditField_TextField'),
          controller: _searchController,
          focusNode: _searchFocusNode,
          autofocus: true,
          onChanged: _updateSearch,
          decoration: InputDecoration(
            hintText: context.localizations.searchForCurrency,
            prefixIcon: Material(
              shape: const CircleBorder(),
              child: IconButton(
                onPressed: _toggleMode,
                icon: Text(
                  _selectedCurrency.symbol,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
          ),
          textInputAction: TextInputAction.done,
        ),
        if (_filteredCurrencies.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: Material(
              elevation: 4.0,
              child: ListView.builder(
                padding: EdgeInsets.all(8.0),
                shrinkWrap: true,
                itemCount: _filteredCurrencies.length,
                itemBuilder: (context, index) {
                  final currency = _filteredCurrencies[index];
                  final isSelected = currency == _selectedCurrency;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3.0),
                    child: ListTile(
                      key: Key('PlatformMoneyEditField_CurrencyListTile_' +
                          currency.code),
                      selected: isSelected,
                      onTap: () => _selectCurrency(currency),
                      leading: Text(
                        currency.symbol,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      title: Text(currency.name),
                      subtitle: Text(currency.code),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
