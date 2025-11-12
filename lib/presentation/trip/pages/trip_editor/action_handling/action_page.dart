import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/app/widgets/button.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_theme.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_editor_constants.dart';

class TripEditorActionPage<T extends TripEntity> extends StatelessWidget {
  final void Function(BuildContext context) onClosePressed;
  final void Function(BuildContext context) onActionInvoked;
  final IconData actionIcon;
  final Widget Function(ValueNotifier<bool> validityNotifier)
      pageContentCreator;
  final String title;
  final ScrollController? scrollController;
  final ValueNotifier<bool> validityNotifier;
  final T tripEntity;

  TripEditorActionPage(
      {super.key,
      required this.tripEntity,
      required this.scrollController,
      required this.title,
      required this.onClosePressed,
      required this.onActionInvoked,
      required this.pageContentCreator,
      required this.actionIcon})
      : validityNotifier = ValueNotifier<bool>(tripEntity.validate());

  @override
  Widget build(BuildContext context) {
    const double _fabBottomMargin = 25.0;
    final double _bottomPadding =
        TripEditorPageConstants.fabSize + _fabBottomMargin + 16.0;
    return Stack(
      children: [
        Column(
          children: [
            AppBar(
              leading: IconButton(
                  icon: const Icon(Icons.close),
                  style: context.isLightTheme
                      ? ButtonStyle(
                          backgroundColor:
                              WidgetStatePropertyAll(AppColors.brandSecondary),
                        )
                      : null,
                  onPressed: () => onClosePressed(context)),
              title: Text(title),
              centerTitle: true,
              elevation: 0,
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(0, 0, 0, _bottomPadding),
                child: _AnimatedActionPage(
                  child: pageContentCreator(validityNotifier),
                ),
              ),
            ),
          ],
        ),
        Positioned(
          bottom: _fabBottomMargin,
          left: 0,
          right: 0,
          child: Center(
            child: _createActionButton(context),
          ),
        ),
      ],
    );
  }

  Widget _createActionButton(BuildContext context) {
    return SizedBox(
      height: TripEditorPageConstants.fabSize,
      width: TripEditorPageConstants.fabSize,
      child: AnimatedOpacity(
        opacity: 1.0,
        child: PlatformSubmitterFAB.conditionallyEnabled(
          child: Icon(actionIcon),
          valueNotifier: validityNotifier,
          callback: () {
            onActionInvoked(context);
            Navigator.of(context).pop();
          },
        ),
        duration: Duration(milliseconds: 3000),
      ),
    );
  }
}

class _AnimatedActionPage extends StatefulWidget {
  final Widget child;

  const _AnimatedActionPage({required this.child});

  @override
  State<_AnimatedActionPage> createState() => _AnimatedActionPageState();
}

class _AnimatedActionPageState extends State<_AnimatedActionPage>
    with TickerProviderStateMixin {
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _fadeAnimationController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 50),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimationController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: _buildEditorCard(context, widget.child),
      ),
    );
  }

  Widget _buildEditorCard(BuildContext context, Widget child) {
    final isBigLayout = context.isBigLayout;
    final cardBorderRadius = EditorTheme.getCardBorderRadius(isBigLayout);
    return Container(
      margin: EdgeInsets.all(
        isBigLayout
            ? EditorTheme.cardMarginHorizontalBig
            : EditorTheme.cardMarginHorizontalSmall,
      ),
      constraints: isBigLayout ? const BoxConstraints(maxWidth: 800) : null,
      decoration: EditorTheme.createCardDecoration(
        isLightTheme: context.isLightTheme,
        isBigLayout: isBigLayout,
        borderRadius: cardBorderRadius,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cardBorderRadius - 2),
        child: child,
      ),
    );
  }
}
