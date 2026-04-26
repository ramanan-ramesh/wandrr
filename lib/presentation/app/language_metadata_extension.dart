import 'package:wandrr/asset_manager/assets.gen.dart';
import 'package:wandrr/data/app/models/language_metadata.dart';

extension LanguageMetadataExtension on LanguageMetadata {
  String get flagAssetLocation {
    switch (locale) {
      case 'ta':
      case 'hi':
        return Assets.images.flags.india.path;
      case 'en':
        return Assets.images.flags.britain.path;
      default:
        return Assets.images.flags.britain.path; // Default to Britain
    }
  }
}
