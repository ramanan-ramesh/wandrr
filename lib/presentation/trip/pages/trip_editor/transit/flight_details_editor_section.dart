import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/app/widgets/auto_complete.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

import 'airline_data.dart';

class FlightDetailsEditor extends StatefulWidget {
  final String? initialOperator;
  final Function(String?) onOperatorChanged;

  const FlightDetailsEditor(
      {required this.initialOperator, required this.onOperatorChanged});

  @override
  State<FlightDetailsEditor> createState() => _FlightDetailsEditorState();
}

class _FlightDetailsEditorState extends State<FlightDetailsEditor>
    with SingleTickerProviderStateMixin {
  // UI styling constants (reused only)
  static const double _kListTileBorderRadius = 6.0;
  static const double _kListTileHorizontalPadding = 8.0;
  static const double _kListTileVerticalPadding = 4.0;
  static const double _kFlightNumberFontSize = 16.0;
  static const double _kSeparatorFontSize = 18.0;
  static const double _kFlightNumberLetterSpacing = 1.2;
  static const double _kFlightNumberInputHorizontalPadding = 12.0;
  static const double _kFlightNumberInputVerticalPadding = 10.0;
  static const double _kFlightNumberSectionSpacing = 8.0;
  static const Duration _kAnimationDuration = Duration(milliseconds: 400);

  late final AirlineData airlineData;
  late final TextEditingController flightNumberEditingController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: _kAnimationDuration,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );
    _initializeFromOperator();
    _updateAnimation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    flightNumberEditingController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FlightDetailsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialOperator != widget.initialOperator) {
      _initializeFromOperator();
      _updateAnimation();
      setState(() {});
    }
  }

  void _updateAnimation() {
    if (_isAirlineValid()) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  bool _isAirlineValid() {
    return airlineData.airLineName != null &&
        airlineData.airLineName!.isNotEmpty &&
        airlineData.airLineCode != null &&
        airlineData.airLineCode!.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _createAirlineEditor(context),
        AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          child: _isAirlineValid()
              ? Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildFlightNumberSection(context),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  void _initializeFromOperator() {
    if (widget.initialOperator != null && widget.initialOperator!.isNotEmpty) {
      airlineData = AirlineData(widget.initialOperator!);
    } else {
      airlineData = AirlineData.empty();
    }
    flightNumberEditingController =
        TextEditingController(text: airlineData.airLineNumber ?? '');
  }

  Widget _createAirlineEditor(BuildContext context) {
    final autoComplete =
        PlatformAutoComplete<(String airLineName, String airLineCode)>(
      labelText: context.localizations.flightCarrierName,
      selectedItem:
          (airlineData.airLineName != null && airlineData.airLineCode != null)
              ? (airlineData.airLineName!, airlineData.airLineCode!)
              : null,
      displayTextCreator: (airlineData) => airlineData.$1,
      optionsBuilder:
          context.apiServicesRepository.airlinesDataService.queryData,
      onSelected: (selectedAirlineData) {
        airlineData.airLineName = selectedAirlineData.$1;
        airlineData.airLineCode = selectedAirlineData.$2;
        _updateAnimation();
        if (airlineData.airLineNumber != null &&
            airlineData.airLineName != null &&
            airlineData.airLineCode != null) {
          widget.onOperatorChanged(airlineData.toString());
        }
        setState(() {});
      },
      listItem: (airlineData) {
        return ListTile(
          selected: this.airlineData.airLineName == airlineData.$1,
          leading: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: _kListTileHorizontalPadding,
              vertical: _kListTileVerticalPadding,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_kListTileBorderRadius),
            ),
            child: Text(
              airlineData.$2,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          title: Text(
            airlineData.$1,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        );
      },
    );
    return SizedBox(width: double.infinity, child: autoComplete);
  }

  Widget _buildFlightNumberSection(BuildContext context) {
    final isLightTheme = context.isLightTheme;
    final textColor =
        isLightTheme ? AppColors.brandSecondary : AppColors.neutral100;
    final labelColor =
        isLightTheme ? AppColors.neutral600 : AppColors.neutral400;
    final separatorColor =
        isLightTheme ? AppColors.neutral500 : AppColors.neutral500;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  airlineData.airLineCode ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: _kFlightNumberFontSize,
                    color: textColor,
                    letterSpacing: _kFlightNumberLetterSpacing,
                  ),
                ),
                const SizedBox(width: _kFlightNumberSectionSpacing),
                Text(
                  '-',
                  style: TextStyle(
                    color: separatorColor,
                    fontSize: _kSeparatorFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: _kFlightNumberSectionSpacing),
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    maxLines: 1,
                    minLines: 1,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: _kFlightNumberFontSize,
                      color: textColor,
                      letterSpacing: _kFlightNumberLetterSpacing,
                    ),
                    decoration: InputDecoration(
                      labelText: context.localizations.flightNumber,
                      labelStyle: TextStyle(color: labelColor),
                      hintText: '0000',
                      hintStyle: TextStyle(
                        color: labelColor,
                        letterSpacing: _kFlightNumberLetterSpacing,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: _kFlightNumberInputHorizontalPadding,
                        vertical: _kFlightNumberInputVerticalPadding,
                      ),
                    ),
                    controller: flightNumberEditingController,
                    onChanged: (newFlightNumber) {
                      airlineData.airLineNumber = newFlightNumber;
                      if (airlineData.airLineNumber != null &&
                          airlineData.airLineNumber!.isNotEmpty &&
                          airlineData.airLineName != null &&
                          airlineData.airLineCode != null) {
                        widget.onOperatorChanged(airlineData.toString());
                      } else {
                        widget.onOperatorChanged(null);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
