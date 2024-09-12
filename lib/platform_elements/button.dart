import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wandrr/contracts/extensions.dart';

class HoverableDeleteButton extends StatefulWidget {
  VoidCallback callBack;

  HoverableDeleteButton({super.key, required this.callBack});

  @override
  State<HoverableDeleteButton> createState() => HoverableDeleteButtonState();
}

class HoverableDeleteButtonState extends State<HoverableDeleteButton> {
  var _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
      },
      child: InkWell(
        onTap: null,
        splashFactory: NoSplash.splashFactory,
        child: IconButton(
          icon: Icon(Icons.delete_rounded),
          color: _isHovered ? Colors.black : Colors.white,
          onPressed: () {
            widget.callBack();
          },
        ),
      ),
    );
  }
}

class PlatformSubmitterFAB extends StatefulWidget {
  final IconData icon;
  final BuildContext context;
  final VoidCallback? callback;
  VoidCallback? validationFailureCallback;
  VoidCallback? validationSuccessCallback;
  final Color? iconColor;
  GlobalKey<FormState>? formState;
  bool isSubmitted;
  ValueNotifier<bool>? valueNotifier;
  bool isConditionallyVisible;
  bool isEnabledInitially;

  PlatformSubmitterFAB(
      {super.key,
      required this.icon,
      required this.context,
      this.iconColor,
      this.callback,
      this.isSubmitted = false,
      this.isEnabledInitially = false})
      : isConditionallyVisible = false;

  PlatformSubmitterFAB.form(
      {super.key,
      required this.icon,
      required this.context,
      this.iconColor,
      this.callback,
      this.formState,
      this.validationFailureCallback,
      this.validationSuccessCallback,
      this.isSubmitted = false,
      this.isEnabledInitially = false})
      : isConditionallyVisible = false;

  PlatformSubmitterFAB.conditionallyEnabled(
      {super.key,
      required this.icon,
      required this.context,
      this.iconColor,
      this.callback,
      this.formState,
      this.validationFailureCallback,
      this.validationSuccessCallback,
      required ValueNotifier<bool> this.valueNotifier,
      this.isSubmitted = false,
      this.isConditionallyVisible = false,
      this.isEnabledInitially = false});

  @override
  State<PlatformSubmitterFAB> createState() => _PlatformSubmitterFABState();
}

class _PlatformSubmitterFABState extends State<PlatformSubmitterFAB> {
  bool get _isCallbackNull => widget.formState != null
      ? (widget.validationSuccessCallback == null)
      : widget.callback == null;

  @override
  Widget build(BuildContext context) {
    if (widget.valueNotifier != null) {
      return ValueListenableBuilder(
        valueListenable: widget.valueNotifier!,
        builder: (BuildContext context, bool value, Widget? child) {
          if (widget.isConditionallyVisible) {
            return Visibility(
              visible: value,
              child: _buildFloatingActionButton(value),
            );
          }
          return _buildFloatingActionButton(value);
        },
      );
    }
    return _buildFloatingActionButton(
        !_isCallbackNull && widget.isEnabledInitially);
  }

  FloatingActionButton _buildFloatingActionButton(bool canEnable) {
    return FloatingActionButton(
      onPressed: widget.isSubmitted || !canEnable ? () {} : _onPressed,
      splashColor: !canEnable ? Colors.white30 : null,
      backgroundColor: !canEnable ? Colors.white10 : null,
      child:
          widget.isSubmitted ? CircularProgressIndicator() : Icon(widget.icon),
    );
  }

  void _onPressed() {
    if (_isCallbackNull) {
      return;
    }
    if (widget.formState != null) {
      if (widget.formState!.currentState != null) {
        if (widget.formState!.currentState!.validate()) {
          widget.validationSuccessCallback?.call();
        } else {
          widget.validationFailureCallback?.call();
          widget.isSubmitted = false;
          setState(() {});
        }
      }
      return;
    }
    setState(() {
      widget.isSubmitted = true;
      widget.callback!();
    });
  }
}

class PlatformCurrencyDropDown extends StatefulWidget {
  final List<Map<String, dynamic>> allCurrencies;
  Map<String, dynamic> currencyInfo;
  final Function(Map<String, dynamic> selectedCurrencyInfo) callBack;

  PlatformCurrencyDropDown(
      {required this.allCurrencies,
      required this.currencyInfo,
      required this.callBack});

  @override
  _PlatformCurrencyDropDownState createState() =>
      _PlatformCurrencyDropDownState();
}

class _PlatformCurrencyDropDownState extends State<PlatformCurrencyDropDown> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: _toggleDropdown,
        child: _buildCurrencyListTile(widget.currencyInfo, true),
      ),
    );
  }

  void _toggleDropdown() {
    if (_overlayEntry == null) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Size size = renderBox.size;
    Offset offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          _overlayEntry?.remove();
          _overlayEntry = null;
        },
        child: Stack(
          children: [
            Positioned(
              width: size.width,
              left: offset.dx,
              top: offset.dy + size.height,
              child: CompositedTransformFollower(
                link: _layerLink,
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
                        allCurrencies: widget.allCurrencies,
                        currencyInfo: widget.currencyInfo,
                        callBack: (Map<String, dynamic> selectedCurrencyInfo) {
                          if (widget.currencyInfo != selectedCurrencyInfo) {
                            setState(() {
                              widget.currencyInfo = selectedCurrencyInfo;
                              widget.callBack(selectedCurrencyInfo);
                            });
                          }
                        },
                        currencyListTileBuilder:
                            (Map<String, dynamic> currency) {
                          return _buildCurrencyListTile(currency, false);
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

  Widget _buildCurrencyListTile(
      Map<String, dynamic> currency, bool isDropDownButton) {
    Color textColor = Colors.white;
    var isEqualToCurrentlySelectedItem =
        mapEquals(currency, widget.currencyInfo);
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
                  if (!mapEquals(currency, widget.currencyInfo)) {
                    setState(() {
                      widget.currencyInfo = currency;
                      widget.callBack(currency);
                      _toggleDropdown();
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
                    currency['symbol'],
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
                          currency['name'],
                          style: TextStyle(
                              color:
                                  textColor), //TODO: This should also be scaled down. But it makes text center in the ListTile. How to avoid this?
                        ),
                      ),
                      Text(
                        currency['code'],
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
}

class _SearchableCurrencyDropDown extends StatefulWidget {
  final List<Map<String, dynamic>> allCurrencies;
  Map<String, dynamic> currencyInfo;
  final Function(Map<String, dynamic> selectedCurrencyInfo) callBack;
  Widget Function(Map<String, dynamic> currency) currencyListTileBuilder;

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
  late List<Map<String, dynamic>> _currencies;

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
                      (currencyInfo) => currencyInfo['name']
                          .toLowerCase()
                          .contains(searchText.toLowerCase()));
                  var searchResultsForCurrencyCode = widget.allCurrencies.where(
                      (currencyInfo) => currencyInfo['code']
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
