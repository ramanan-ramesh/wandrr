class TripEditorPageConstants {
  static const double fabSize = 80.0;

  /// Extra bottom padding to keep content above the FAB in the small (phone)
  /// layout.  The FAB (80 px, centerDocked) sits with its centre on the nav-bar
  /// top edge, so it protrudes fabSize/2 = 40 px upward into the body.
  /// An 8 px comfort margin is added on top.
  static const double fabContentPaddingSmall = fabSize / 2 + 8.0; // 48 px

  /// Extra bottom padding for the big (tablet/web) layout.  The FAB widget
  /// rendered by _createAddButton is fabSize (80) + Padding.bottom (24) = 104 px
  /// tall; centerDocked places its top edge exactly that far above contentBottom.
  static const double fabContentPaddingBig = fabSize + 24.0; // 104 px
}
