import 'package:flutter/material.dart';

//TODO: Should the two fragments need buildContext injected?
abstract class HomePageContent {
  Widget? get floatingActionButton;

  Widget? get body;

  FloatingActionButtonLocation get floatingActionButtonLocation;
}
