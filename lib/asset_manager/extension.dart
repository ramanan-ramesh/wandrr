import 'package:wandrr/asset_manager/assets.gen.dart';

extension AssetExt on AssetGenImage {
  String get fileName => keyName.split('/').last.split('.').first;
}
