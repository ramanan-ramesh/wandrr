import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:wandrr/contracts/extensions.dart';
import 'package:wandrr/contracts/trip_entity_facades/location.dart';
import 'package:wandrr/repositories/api_services/geo_locator.dart';

import 'location.dart';

class PlatformTextElements {
  static const double subHeaderSize = 20;
  static const double formElementSize = 15;

  static Text createHeader(
      {required BuildContext context, required String text}) {
    return Text(
      text,
      style: const TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
    );
  }

  static Text createSubHeader(
      {required BuildContext context,
      required String text,
      bool shouldBold = false}) {
    return Text(
      text,
      softWrap: true,
      style: TextStyle(
          // color: Colors.white,
          fontSize: subHeaderSize,
          fontWeight: shouldBold ? FontWeight.bold : null),
    );
  }

  //TODO: Use PlatformTextField instead of this. Replace all usages
  static TextField createTextField(
      {required BuildContext context,
      String? labelText,
      InputBorder? border,
      TextEditingController? controller,
      Function(String)? onTextChanged,
      String? hintText,
      Widget? suffix,
      int? maxLines = 10}) {
    InputDecoration? inputDecoration;
    if (labelText != null || border != null || suffix != null) {
      inputDecoration = InputDecoration(
          labelText: labelText,
          border: border,
          suffix: suffix,
          hintText: hintText);
    }
    return TextField(
      style: TextStyle(fontSize: PlatformTextElements.formElementSize),
      minLines: 1,
      maxLines: maxLines,
      onChanged: onTextChanged,
      controller: controller,
      decoration: inputDecoration,
    );
  }
}

class PlatformGeoLocationAutoComplete extends StatelessWidget {
  final String? initialText;
  final Function(LocationFacade selectedLocation)? onLocationSelected;
  final bool shouldShowPrefix;
  final GeoLocator? geoLocator;

  const PlatformGeoLocationAutoComplete(
      {super.key,
      required this.initialText,
      this.geoLocator,
      this.onLocationSelected,
      this.shouldShowPrefix = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black12,
      child: PlatformAutoComplete<LocationFacade>(
        text: initialText,
        onSelected: onLocationSelected,
        optionsBuilder: geoLocator?.performQuery ??
            context.getPlatformDataRepository().geoLocator.performQuery,
        customPrefix: shouldShowPrefix
            ? FittedBox(
                fit: BoxFit.cover,
                child: PlatformTextElements.createSubHeader(
                    context: context, text: context.withLocale().destination),
              )
            : null,
        listItem: (location) {
          var geoLocationContext = location.context as GeoLocationApiContext;
          return Material(
            child: Container(
              color: Colors.black12,
              child: ListTile(
                leading: Icon(PlatformLocationElements
                    .locationTypesAndIcons[location.context.locationType]),
                title: Text(location.context.name,
                    style: const TextStyle(color: Colors.white)),
                trailing: Text(geoLocationContext.locationType.name,
                    style: const TextStyle(color: Colors.white)),
                subtitle: geoLocationContext.address != null
                    ? Text(
                        geoLocationContext.address!,
                        style: TextStyle(color: Colors.white),
                      )
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}

class PlatformAutoComplete<T extends Object> extends StatelessWidget {
  final FutureOr<Iterable<T>> Function(String searchValue) optionsBuilder;
  final Widget Function(T value) listItem;
  final Widget? customPrefix;
  final void Function(T)? onSelected;
  final String? text;
  final Widget? suffix;
  final String? hintText;
  final double? maxOptionWidgetWidth;
  static const _defaultAutoCompleteHintText = 'e.g. Paris, Hawaii...';

  PlatformAutoComplete(
      {Key? key,
      required this.optionsBuilder,
      required this.listItem,
      this.text,
      this.onSelected,
      this.hintText,
      this.suffix,
      this.maxOptionWidgetWidth,
      this.customPrefix})
      : super(key: key);

  T? selectedItem;

  late FocusNode? _focusNode;
  late TextEditingController _textEditingController;

  @override
  Widget build(BuildContext context) {
    var color = Theme.of(context).scaffoldBackgroundColor;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          child: Autocomplete<T>(
            optionsBuilder: (textEditingValue) async {
              return await optionsBuilder(textEditingValue.text);
            },
            onSelected: (T selection) {
              selectedItem = selection;
              _textEditingController.text = selection.toString();
              if (onSelected != null) {
                onSelected!(selection);
              }
              if (_focusNode != null) {
                _focusNode!.unfocus();
              }
            },
            fieldViewBuilder: (
              BuildContext context,
              TextEditingController textEditingController,
              FocusNode focusNode,
              VoidCallback onFieldSubmitted,
            ) {
              _focusNode = focusNode;
              _textEditingController = textEditingController;
              if (this.text != null) {
                _textEditingController.text = this.text!;
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (customPrefix != null)
                    Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: customPrefix!,
                    ),
                  Expanded(
                    child: Container(
                      color: color,
                      child: TextFormField(
                        cursorColor: Colors.white,
                        controller: _textEditingController,
                        focusNode: _focusNode,
                        style: const TextStyle(
                          fontSize: PlatformTextElements.subHeaderSize,
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                            suffix: suffix,
                            fillColor: Colors.red,
                            isDense: true,
                            hintStyle: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.white),
                            hintText: hintText ?? _defaultAutoCompleteHintText,
                            border: OutlineInputBorder()),
                      ),
                    ),
                  ),
                ],
              );
            },
            optionsViewBuilder: (BuildContext context,
                AutocompleteOnSelected<T> onSelected, Iterable<T> options) {
              return Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: maxOptionWidgetWidth ?? constraints.maxWidth,
                  child: Container(
                    color: Colors.green,
                    child: Material(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: 200),
                        child: ListView.separated(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemBuilder: (BuildContext context, int index) {
                              final T option = options.elementAt(index);
                              return InkWell(
                                onTap: () {
                                  onSelected(option);
                                },
                                child: Builder(builder: (BuildContext context) {
                                  final bool highlight =
                                      AutocompleteHighlightedOption.of(
                                              context) ==
                                          index;
                                  if (highlight) {
                                    SchedulerBinding.instance
                                        .addPostFrameCallback(
                                            (Duration timeStamp) {
                                      Scrollable.ensureVisible(context,
                                          alignment: 0.5);
                                    });
                                  }
                                  return Container(
                                    color: highlight
                                        ? Theme.of(context).focusColor
                                        : null,
                                    child: listItem(option),
                                  );
                                }),
                              );
                            },
                            separatorBuilder: (context, int) {
                              return Divider();
                            },
                            itemCount: options.length),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
