import 'package:flutter/material.dart';
import 'package:wandrr/asset_manager/assets.gen.dart';
import 'package:wandrr/asset_manager/extension.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/widgets/dialog.dart';
import 'package:wandrr/presentation/trip/pages/trip_provider/constants.dart';

const double _kSelectedImageScaleFactor = 1.18;
const double _kThumbnailBorderRadius = 14.0;
const double _kThumbnailContainerBorderRadius = 18.0;
const double _kThumbnailSelectedVerticalMargin = 0.0;
const double _kThumbnailUnselectedVerticalMargin = 12.0;

extension _SizingExt on BuildContext {
  static const double _kBigLayoutUnselectedImageSize = 120.0;
  static const double _kSmallLayoutUnselectedImageSize = 80.0;
  static const double _kCarouselHeightMultiplier = 1.25;
  static const double _kCarouselHeightExtraPadding = 32.0;
  static const double _kBigLayoutViewportFraction = 0.35;
  static const double _kSmallLayoutViewportFraction = 0.5;
  static const double _kBigLayoutHorizontalSpacing = 32.0;
  static const double _kSmallLayoutHorizontalSpacing = 16.0;

  double get unselectedImageSize => isBigLayout
      ? _kBigLayoutUnselectedImageSize
      : _kSmallLayoutUnselectedImageSize;

  double get carouselHeight =>
      unselectedImageSize * _kCarouselHeightMultiplier +
      _kCarouselHeightExtraPadding;

  double get viewportFraction =>
      isBigLayout ? _kBigLayoutViewportFraction : _kSmallLayoutViewportFraction;

  double get horizontalSpacing => isBigLayout
      ? _kBigLayoutHorizontalSpacing
      : _kSmallLayoutHorizontalSpacing;
}

class TripThumbnailCarouselSelector extends StatefulWidget {
  final String selectedThumbnailTag;
  final ValueChanged<String> onChanged;

  const TripThumbnailCarouselSelector({
    Key? key,
    required this.selectedThumbnailTag,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<TripThumbnailCarouselSelector> createState() =>
      _TripThumbnailCarouselSelectorState();
}

class _TripThumbnailCarouselSelectorState
    extends State<TripThumbnailCarouselSelector> {
  late final PageController _pageController;
  late String _selectedTag;

  List<AssetGenImage> get thumbnails => Assets.images.tripThumbnails.values;

  @override
  void initState() {
    super.initState();
    _selectedTag = widget.selectedThumbnailTag;

    var initialIndex = thumbnails
        .indexWhere((img) => img.fileName == widget.selectedThumbnailTag);
    if (initialIndex < 0) {
      if (thumbnails.isNotEmpty) {
        _selectedTag = thumbnails.first.fileName;
        initialIndex = 0;
      }
    }

    _pageController = PageController(
      initialPage: initialIndex,
      viewportFraction: context.viewportFraction,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unselectedImageSize = context.unselectedImageSize;
    return SizedBox(
      height: context.carouselHeight,
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.horizontal,
        itemCount: thumbnails.length,
        onPageChanged: onPageChanged,
        itemBuilder: (context, index) {
          final selected = thumbnails[index].fileName == _selectedTag;
          final scale = selected ? _kSelectedImageScaleFactor : 1.0;
          return GestureDetector(
            onTap: () {
              var thumbnailTag = thumbnails[index].fileName;
              setState(() {
                _selectedTag = thumbnailTag;
              });
              widget.onChanged(thumbnailTag);
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: AnimatedScale(
              scale: scale,
              duration: const Duration(milliseconds: 200),
              child: _createThumbnail(selected, index, unselectedImageSize),
            ),
          );
        },
      ),
    );
  }

  Widget _createThumbnail(
      bool selected, int index, double unselectedImageSize) {
    final horizontalSpacing = context.horizontalSpacing;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.symmetric(
          horizontal: horizontalSpacing / 2,
          vertical: selected
              ? _kThumbnailSelectedVerticalMargin
              : _kThumbnailUnselectedVerticalMargin),
      decoration: _createImageDecoration(selected),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_kThumbnailBorderRadius),
        child: thumbnails[index].image(
          width: unselectedImageSize,
          height: unselectedImageSize,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Decoration _createImageDecoration(bool isSelected) {
    var borderColor = isSelected
        ? Theme.of(context).colorScheme.onSecondary
        : Colors.transparent;
    return BoxDecoration(
      border: Border.all(
        color: borderColor,
        width: 4,
      ),
      borderRadius: BorderRadius.circular(_kThumbnailContainerBorderRadius),
      boxShadow: isSelected
          ? [
              BoxShadow(
                  color: borderColor.withValues(alpha: 0.18), blurRadius: 10)
            ]
          : [],
    );
  }

  void onPageChanged(int index) {
    if (thumbnails.isNotEmpty && index >= 0 && index < thumbnails.length) {
      final keyName = thumbnails[index].fileName;
      setState(() {
        _selectedTag = keyName;
      });
      widget.onChanged(keyName);
    }
  }
}

class ThumbnailPicker extends StatelessWidget {
  ThumbnailPicker({
    super.key,
    required this.tripMetaDataFacade,
    required this.widgetContext,
  });

  final TripMetadataFacade tripMetaDataFacade;
  final BuildContext widgetContext;
  final _circularBorderRadius = BorderRadius.circular(16);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: _circularBorderRadius,
        onTap: () async {
          var selectedThumbnailTag = tripMetaDataFacade.thumbnailTag;
          PlatformDialogElements.showGeneralDialog<String>(
            context,
            (dialogContext) {
              return Container(
                constraints: BoxConstraints(
                  maxWidth: TripProviderPageConstants.maximumPageWidth,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _createAppBar(dialogContext),
                    const SizedBox(height: 16),
                    TripThumbnailCarouselSelector(
                      selectedThumbnailTag: selectedThumbnailTag,
                      onChanged: (thumbnailTag) {
                        selectedThumbnailTag = thumbnailTag;
                        (dialogContext as Element).markNeedsBuild();
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                            },
                            child: Text(context.localizations.cancel),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(dialogContext)
                                  .pop(selectedThumbnailTag);
                            },
                            child: Text(context.localizations.select),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
            onDialogResult: _onDialogResult,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: _circularBorderRadius,
          ),
          child: const Icon(Icons.image, color: Colors.white, size: 25),
        ),
      ),
    );
  }

  void _onDialogResult(String? selectedThumbnailTag) {
    if (selectedThumbnailTag != null &&
        selectedThumbnailTag != tripMetaDataFacade.thumbnailTag) {
      var clonedTripMetadataFacade = tripMetaDataFacade.clone();
      clonedTripMetadataFacade.thumbnailTag = selectedThumbnailTag;
      widgetContext.addTripManagementEvent(
        UpdateTripEntity<TripMetadataFacade>.update(
            tripEntity: clonedTripMetadataFacade),
      );
    }
  }

  Material _createAppBar(BuildContext dialogContext) {
    return Material(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      clipBehavior: Clip.hardEdge,
      child: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: FittedBox(
          child: Text(dialogContext.localizations.chooseTripThumbnail),
        ),
      ),
    );
  }
}
