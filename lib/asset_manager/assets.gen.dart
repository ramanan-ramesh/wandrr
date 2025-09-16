// dart format width=80

/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: deprecated_member_use,directives_ordering,implicit_dynamic_list_literal,unnecessary_import

import 'package:flutter/widgets.dart';

class $AssetsImagesGen {
  const $AssetsImagesGen();

  /// Directory path: assets/images/flags
  $AssetsImagesFlagsGen get flags => const $AssetsImagesFlagsGen();

  /// File path: assets/images/google_logo.png
  AssetGenImage get googleLogo =>
      const AssetGenImage('assets/images/google_logo.png');

  /// File path: assets/images/logo.jpg
  AssetGenImage get logo => const AssetGenImage('assets/images/logo.jpg');

  /// File path: assets/images/plan_itinerary.jpg
  AssetGenImage get planItinerary =>
      const AssetGenImage('assets/images/plan_itinerary.jpg');

  /// File path: assets/images/planning_the_trip.jpg
  AssetGenImage get planningTheTrip =>
      const AssetGenImage('assets/images/planning_the_trip.jpg');

  /// Directory path: assets/images/tripThumbnails
  $AssetsImagesTripThumbnailsGen get tripThumbnails =>
      const $AssetsImagesTripThumbnailsGen();

  /// List of all assets
  List<AssetGenImage> get values =>
      [googleLogo, logo, planItinerary, planningTheTrip];
}

class $AssetsImagesFlagsGen {
  const $AssetsImagesFlagsGen();

  /// File path: assets/images/flags/britain.png
  AssetGenImage get britain =>
      const AssetGenImage('assets/images/flags/britain.png');

  /// File path: assets/images/flags/india.png
  AssetGenImage get india =>
      const AssetGenImage('assets/images/flags/india.png');

  /// List of all assets
  List<AssetGenImage> get values => [britain, india];
}

class $AssetsImagesTripThumbnailsGen {
  const $AssetsImagesTripThumbnailsGen();

  /// File path: assets/images/tripThumbnails/beach.png
  AssetGenImage get beach =>
      const AssetGenImage('assets/images/tripThumbnails/beach.png');

  /// File path: assets/images/tripThumbnails/hills.png
  AssetGenImage get hills =>
      const AssetGenImage('assets/images/tripThumbnails/hills.png');

  /// File path: assets/images/tripThumbnails/mountains.png
  AssetGenImage get mountains =>
      const AssetGenImage('assets/images/tripThumbnails/mountains.png');

  /// File path: assets/images/tripThumbnails/roadTrip.png
  AssetGenImage get roadTrip =>
      const AssetGenImage('assets/images/tripThumbnails/roadTrip.png');

  /// File path: assets/images/tripThumbnails/urban.png
  AssetGenImage get urban =>
      const AssetGenImage('assets/images/tripThumbnails/urban.png');

  /// File path: assets/images/tripThumbnails/work.png
  AssetGenImage get work =>
      const AssetGenImage('assets/images/tripThumbnails/work.png');

  /// List of all assets
  List<AssetGenImage> get values =>
      [beach, hills, mountains, roadTrip, urban, work];
}

class Assets {
  const Assets._();

  static const $AssetsImagesGen images = $AssetsImagesGen();
  static const String supportedCurrencies = 'assets/supported_currencies.json';
  static const String walkAnimation = 'assets/walk_animation.riv';

  /// List of all assets
  static List<String> get values => [supportedCurrencies, walkAnimation];
}

class AssetGenImage {
  const AssetGenImage(
    this._assetName, {
    this.size,
    this.flavors = const {},
    this.animation,
  });

  final String _assetName;

  final Size? size;
  final Set<String> flavors;
  final AssetGenImageAnimation? animation;

  Image image({
    Key? key,
    AssetBundle? bundle,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? scale,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = true,
    bool isAntiAlias = false,
    String? package,
    FilterQuality filterQuality = FilterQuality.medium,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return Image.asset(
      _assetName,
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      package: package,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  ImageProvider provider({
    AssetBundle? bundle,
    String? package,
  }) {
    return AssetImage(
      _assetName,
      bundle: bundle,
      package: package,
    );
  }

  String get path => _assetName;

  String get keyName => _assetName;
}

class AssetGenImageAnimation {
  const AssetGenImageAnimation({
    required this.isAnimation,
    required this.duration,
    required this.frames,
  });

  final bool isAnimation;
  final Duration duration;
  final int frames;
}
