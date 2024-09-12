import 'package:flutter/material.dart';

import 'database_connectors/data_states.dart';

class UiElement<K> {
  K element;
  DataState dataState;
  GlobalKey? key;

  UiElement({required this.element, required this.dataState, this.key});

  UiElement<K> clone() {
    return UiElement(element: element, dataState: dataState, key: key);
  }
}

class UiElementWithMetadata<K, V> extends UiElement<K> {
  V metadata;

  UiElementWithMetadata(
      {required K element,
      required DataState dataState,
      required this.metadata,
      GlobalKey? key})
      : super(element: element, dataState: dataState, key: key);

  @override
  UiElementWithMetadata<K, V> clone() {
    return UiElementWithMetadata(
        element: element, dataState: dataState, key: key, metadata: metadata);
  }
}
