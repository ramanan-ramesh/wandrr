import 'package:flutter/material.dart';
import 'package:wandrr/asset_manager/assets.gen.dart';
import 'package:wandrr/asset_manager/extension.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/widgets/dialog.dart';

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
      _selectedTag = thumbnails.first.fileName;
    }
    _pageController = PageController(
      initialPage: initialIndex < 0 ? 0 : initialIndex,
      viewportFraction: context.isBigLayout ? 0.35 : 0.5,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var isBigLayout = context.isBigLayout;
    double unselectedImageSize = isBigLayout ? 120 : 80;
    return SizedBox(
      height: unselectedImageSize * 1.25 + 32,
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.horizontal,
        itemCount: thumbnails.length,
        onPageChanged: onPageChanged,
        itemBuilder: (context, index) {
          final selected = thumbnails[index].fileName == _selectedTag;
          final scale = selected ? 1.18 : 1.0;
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
    var horizontalSpacing = context.isBigLayout ? 32 : 16;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.symmetric(
          horizontal: horizontalSpacing / 2, vertical: selected ? 0 : 12),
      decoration: _createImageDecoration(selected),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
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
      borderRadius: BorderRadius.circular(18),
      boxShadow: isSelected
          ? [
              BoxShadow(
                  color: borderColor.withValues(alpha: 0.18), blurRadius: 10)
            ]
          : [],
    );
  }

  void onPageChanged(int index) {
    final keyName = thumbnails[index].fileName;
    setState(() {
      _selectedTag = keyName;
    });
    widget.onChanged(keyName);
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
          PlatformDialogElements.showGeneralDialog<String>(context,
              (dialogContext) {
            final isBig = dialogContext.isBigLayout;
            return AlertDialog(
              title: Text(dialogContext.localizations.chooseTripThumbnail),
              content: SizedBox(
                width: isBig ? 500 : 350,
                height: isBig ? 200 : 150,
                child: TripThumbnailCarouselSelector(
                  selectedThumbnailTag: selectedThumbnailTag,
                  onChanged: (thumbnailTag) {
                    selectedThumbnailTag = thumbnailTag;
                    (dialogContext as Element).markNeedsBuild();
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(dialogContext.localizations.cancel),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(selectedThumbnailTag),
                  child: Text(dialogContext.localizations.select),
                ),
              ],
            );
          }, onDialogResult: (selectedThumbnailTag) {
            if (selectedThumbnailTag != null &&
                selectedThumbnailTag != tripMetaDataFacade.thumbnailTag) {
              var clonedTripMetadataFacade = tripMetaDataFacade.clone();
              clonedTripMetadataFacade.thumbnailTag = selectedThumbnailTag;
              context.addTripManagementEvent(
                UpdateTripEntity<TripMetadataFacade>.update(
                    tripEntity: clonedTripMetadataFacade),
              );
            }
          });
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
}
