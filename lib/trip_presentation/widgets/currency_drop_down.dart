import 'package:flutter/material.dart';
import 'package:wandrr/api_services/models/currency_data.dart';
import 'package:wandrr/app_presentation/extensions.dart';

abstract class CurrencyDropDownField extends StatefulWidget {
  CurrencyData selectedCurrencyData;
  OverlayEntry? overlayEntry;
  final Iterable<CurrencyData> allCurrencies;
  final Function(CurrencyData selectedCurrencyInfo) currencySelectedCallback;
  final LayerLink layerLink = LayerLink();

  CurrencyDropDownField(
      {super.key,
      required this.selectedCurrencyData,
      this.overlayEntry,
      required this.allCurrencies,
      required this.currencySelectedCallback});

  Widget buildCurrencyListTile(CurrencyData currency, bool isDropDownButton,
      BuildContext context, void Function(VoidCallback) setState) {
    Color textColor = Colors.white;
    var isEqualToCurrentlySelectedItem = currency == selectedCurrencyData;
    if (isDropDownButton || isEqualToCurrentlySelectedItem) {
      textColor = Colors.green;
    }
    return SizedBox(
      height: 60,
      child: Container(
        color: isEqualToCurrentlySelectedItem
            ? Colors.white10
            : Colors.transparent,
        child: InkWell(
          onTap: !isDropDownButton
              ? () {
                  if (currency != selectedCurrencyData) {
                    setState(() {
                      selectedCurrencyData = currency;
                      currencySelectedCallback(currency);
                    });
                  }
                }
              : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.0),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    currency.symbol,
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.bold, color: textColor),
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
                          style: TextStyle(
                              color:
                                  textColor), //TODO: This should also be scaled down. But it makes text center in the ListTile. How to avoid this?
                        ),
                      ),
                      Text(
                        currency.code,
                        style: TextStyle(color: textColor),
                      ),
                    ],
                  ),
                ),
              ),
              if (isDropDownButton)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                  child: Icon(Icons.arrow_drop_down),
                )
            ],
          ),
        ),
      ),
    );
  }

  void toggleDropdown(
      BuildContext context, void Function(VoidCallback) setState) {
    if (overlayEntry == null) {
      overlayEntry = _createCurrencyDropDownOverlay(context, setState);
      Overlay.of(context).insert(overlayEntry!);
    } else {
      overlayEntry?.remove();
      overlayEntry = null;
    }
  }

  void removeOverlayEntry() {
    overlayEntry?.remove();
  }

  OverlayEntry _createCurrencyDropDownOverlay(
      BuildContext context, void Function(VoidCallback) setState) {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Size size = renderBox.size;
    Offset offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          overlayEntry?.remove();
          overlayEntry = null;
        },
        child: Stack(
          children: [
            Positioned(
              width: size.width,
              left: offset.dx,
              top: offset.dy + size.height,
              child: CompositedTransformFollower(
                link: layerLink,
                showWhenUnlinked: false,
                offset: Offset(0.0, 5.0),
                child: Material(
                  elevation: 4.0,
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context),
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: 300,
                      ),
                      child: _SearchableCurrencyDropDown(
                        allCurrencies: allCurrencies,
                        currencyInfo: selectedCurrencyData,
                        callBack: (CurrencyData selectedCurrencyInfo) {
                          if (selectedCurrencyInfo != selectedCurrencyInfo) {
                            setState(() {
                              selectedCurrencyInfo = selectedCurrencyInfo;
                              currencySelectedCallback(selectedCurrencyInfo);
                            });
                          }
                        },
                        currencyListTileBuilder: (CurrencyData currency) {
                          return buildCurrencyListTile(
                              currency, false, context, setState);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class PlatformCurrencyDropDown extends CurrencyDropDownField {
  PlatformCurrencyDropDown(
      {required super.selectedCurrencyData,
      required super.allCurrencies,
      super.overlayEntry,
      super.key,
      required super.currencySelectedCallback});

  @override
  _PlatformCurrencyDropDownState createState() =>
      _PlatformCurrencyDropDownState();
}

class _PlatformCurrencyDropDownState extends State<PlatformCurrencyDropDown> {
  _PlatformCurrencyDropDownState();

  @override
  void dispose() {
    widget.removeOverlayEntry();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: widget.layerLink,
      child: InkWell(
        onTap: () => widget.toggleDropdown(context, setState),
        child: widget.buildCurrencyListTile(
            widget.selectedCurrencyData, true, context, setState),
      ),
    );
  }
}

class _SearchableCurrencyDropDown extends StatefulWidget {
  final Iterable<CurrencyData> allCurrencies;
  CurrencyData currencyInfo;
  final Function(CurrencyData selectedCurrencyInfo) callBack;
  Widget Function(CurrencyData currency) currencyListTileBuilder;

  _SearchableCurrencyDropDown(
      {super.key,
      required this.allCurrencies,
      required this.currencyInfo,
      required this.callBack,
      required this.currencyListTileBuilder});

  @override
  State<_SearchableCurrencyDropDown> createState() =>
      _SearchableCurrencyDropDownState();
}

class _SearchableCurrencyDropDownState
    extends State<_SearchableCurrencyDropDown> {
  late List<CurrencyData> _currencies;

  @override
  void initState() {
    super.initState();
    _currencies = widget.allCurrencies.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.0),
          child: _buildSearchEditor(context),
        ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: _currencies.map((item) {
                return widget.currencyListTileBuilder(item);
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchEditor(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.0),
            child: Icon(Icons.search_rounded),
          ),
          Expanded(
            child: TextField(
              //TODO: Bring focus automatically when dialog is opened
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: context.withLocale().searchForCurrency,
              ),
              onChanged: (searchText) {
                _currencies.clear();
                if (searchText.isEmpty) {
                  _currencies = widget.allCurrencies.toList();
                } else {
                  var searchResultsForCurrencyName = widget.allCurrencies.where(
                      (currencyInfo) => currencyInfo.name
                          .toLowerCase()
                          .contains(searchText.toLowerCase()));
                  var searchResultsForCurrencyCode = widget.allCurrencies.where(
                      (currencyInfo) => currencyInfo.code
                          .toLowerCase()
                          .contains(searchText.toLowerCase()));
                  _currencies.addAll(searchResultsForCurrencyName);
                  for (var currencyInfo in searchResultsForCurrencyCode) {
                    if (!_currencies.contains(currencyInfo)) {
                      _currencies.add(currencyInfo);
                    }
                  }
                }
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }
}
