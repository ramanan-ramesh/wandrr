import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class PlatformNetworkImageElement extends StatefulWidget {
  final Icon? icon;
  final String networkUrl;
  final String? assetImage;

  PlatformNetworkImageElement.icon(
      {super.key, required this.icon, required this.networkUrl})
      : assetImage = null;

  PlatformNetworkImageElement.asset(
      {super.key, required this.assetImage, required this.networkUrl})
      : icon = null;

  @override
  State<PlatformNetworkImageElement> createState() =>
      _PlatformNetworkImageElementState();
}

class _PlatformNetworkImageElementState
    extends State<PlatformNetworkImageElement> {
  var _isImageLoaded = false;
  late NetworkImage _networkImage;

  @override
  void initState() {
    super.initState();
    _networkImage = NetworkImage(widget.networkUrl);
    var imageStreamListener = ImageStreamListener((image, synchronousCall) {
      if (mounted) {
        setState(() {
          _isImageLoaded = true;
        });
      }
    }, onError: (object, stackTrace) {
      print('error while loading network image: ${object.toString()}');
    });
    _networkImage
        .resolve(const ImageConfiguration())
        .addListener(imageStreamListener);
  }

  @override
  Widget build(BuildContext context) {
    return !_isImageLoaded
        ? const CircleAvatar(
            radius: 35,
            child: Icon(Icons.account_circle_rounded),
          )
        : CircleAvatar(
            radius: 35,
            backgroundImage: _networkImage,
          );
  }
}
