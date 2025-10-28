import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/app/widgets/auto_complete.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_theme.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

import 'airline_data.dart';

class TransitOperatorEditor extends StatelessWidget {
  final TransitOption transitOption;
  final String? initialOperator;
  final Function(String?) onOperatorChanged;

  const TransitOperatorEditor(
      {required this.transitOption,
      required this.onOperatorChanged,
      super.key,
      this.initialOperator});

  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    var icon = transitOption == TransitOption.flight
        ? Icons.flight
        : Icons.directions_bus;
    var iconColor = transitOption == TransitOption.flight
        ? (isLightTheme ? AppColors.info : AppColors.infoLight)
        : (isLightTheme ? AppColors.brandPrimary : AppColors.brandPrimaryLight);
    var title =
        transitOption == TransitOption.flight ? 'Flight Details' : 'Carrier';
    var editor = transitOption == TransitOption.flight
        ? _FlightDetailsEditor(
            initialOperator: initialOperator,
            onOperatorChanged: onOperatorChanged,
          )
        : _createTransitOperatorEditingField(context);

    return EditorTheme.buildSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EditorTheme.buildSectionHeader(
            context,
            icon: icon,
            title: title,
            iconColor: iconColor,
            useLargeText: true,
          ),
          const SizedBox(height: 12),
          editor,
        ],
      ),
    );
  }

  Widget _createTransitOperatorEditingField(BuildContext context) {
    final theme = Theme.of(context);
    final isLightTheme = theme.brightness == Brightness.light;
    final textColor =
        isLightTheme ? AppColors.brandSecondary : AppColors.neutral100;
    final borderColor =
        isLightTheme ? AppColors.neutral400 : AppColors.neutral600;
    final iconColor =
        isLightTheme ? AppColors.brandPrimary : AppColors.brandPrimaryLight;

    var transitOperatorEditingController =
        TextEditingController(text: initialOperator ?? '');

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: TextField(
        minLines: 1,
        maxLines: 1,
        style: theme.textTheme.labelLarge?.copyWith(
          color: textColor,
        ),
        controller: transitOperatorEditingController,
        decoration: InputDecoration(
          labelText: context.localizations.carrierName,
          labelStyle: TextStyle(color: textColor),
          prefixIcon: Icon(Icons.directions_bus, color: iconColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: onOperatorChanged,
      ),
    );
  }
}

class _FlightDetailsEditor extends StatefulWidget {
  final String? initialOperator;
  final Function(String?) onOperatorChanged;

  const _FlightDetailsEditor(
      {required this.initialOperator, required this.onOperatorChanged});

  @override
  State<_FlightDetailsEditor> createState() => _FlightDetailsEditorState();
}

class _FlightDetailsEditorState extends State<_FlightDetailsEditor>
    with SingleTickerProviderStateMixin {
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
      duration: const Duration(milliseconds: 400),
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
  void didUpdateWidget(covariant _FlightDetailsEditor oldWidget) {
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
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
                    fontSize: 16,
                    color: textColor,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '-',
                  style: TextStyle(
                    color: separatorColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
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
                      fontSize: 16,
                      color: textColor,
                      letterSpacing: 1.2,
                    ),
                    decoration: InputDecoration(
                      labelText: context.localizations.flightNumber,
                      labelStyle: TextStyle(color: labelColor),
                      hintText: '0000',
                      hintStyle: TextStyle(
                        color: labelColor,
                        letterSpacing: 1.2,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
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
