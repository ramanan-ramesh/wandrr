import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wandrr/data/app/models/app_data.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/app/widgets/dialog.dart';
import 'package:wandrr/presentation/app/widgets/text.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_theme.dart';

const _kSectionSpacing = SizedBox(height: 12);
const _kChipSpacing = 8.0;
const _kBorderRadiusLarge = BorderRadius.all(Radius.circular(20));
const _kBorderRadiusMedium = BorderRadius.all(Radius.circular(12));
const _kIconSizeSmall = 16.0;
const _kIconSizeXLarge = 24.0;
const _kCircleAvatarRadius = 12.0;
const _kAnimationDurationShort = Duration(milliseconds: 300);

class TripContributorsEditorSection extends StatefulWidget {
  final Iterable<String> contributors;
  final ValueChanged<Iterable<String>> onContributorsChanged;

  const TripContributorsEditorSection({
    super.key,
    required this.contributors,
    required this.onContributorsChanged,
  });

  @override
  State<TripContributorsEditorSection> createState() =>
      _TripContributorsEditorSectionState();
}

class _TripContributorsEditorSectionState
    extends State<TripContributorsEditorSection> {
  final GlobalKey<FormState> _userNameFieldFormKey = GlobalKey<FormState>();
  late TextEditingController _contributorController;
  late List<String> _contributors;
  bool _isAddContributorFieldVisible = false;
  bool _isCheckingUserExistence = false;
  String? _userExistenceError;

  @override
  void initState() {
    super.initState();
    _contributorController = TextEditingController();
    _contributors = List.from(widget.contributors);

    // Clear error when user starts typing
    _contributorController.addListener(() {
      if (_userExistenceError != null) {
        setState(() {
          _userExistenceError = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _contributorController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TripContributorsEditorSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(
        oldWidget.contributors.toList(), widget.contributors.toList())) {
      setState(() {
        _contributors = List.from(widget.contributors);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return EditorTheme.createSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              EditorTheme.createSectionHeader(
                context,
                icon: Icons.people_rounded,
                title: 'Trip Mates',
                iconColor: context.isLightTheme
                    ? AppColors.success
                    : AppColors.successLight,
              ),
              _buildAddContributorButton(context),
            ],
          ),
          _kSectionSpacing,
          _buildContributorsList(context),
          AnimatedSize(
            duration: _kAnimationDurationShort,
            curve: Curves.easeInOut,
            child: _isAddContributorFieldVisible
                ? _buildAddContributorField(context)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddContributorButton(BuildContext context) {
    return AnimatedContainer(
      duration: _kAnimationDurationShort,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: TextButton.icon(
        onPressed: () {
          setState(() {
            _isAddContributorFieldVisible = !_isAddContributorFieldVisible;
          });
        },
        label: Text(_isAddContributorFieldVisible ? 'Close' : 'Add'),
        icon: Icon(_isAddContributorFieldVisible ? Icons.close : Icons.add),
      ),
    );
  }

  Widget _buildContributorsList(BuildContext context) {
    return Wrap(
      spacing: _kChipSpacing,
      runSpacing: _kChipSpacing,
      children: _contributors.map((contributor) {
        return _buildContributorChip(context, contributor);
      }).toList(),
    );
  }

  Widget _buildContributorChip(BuildContext context, String contributor) {
    final isLightTheme = context.isLightTheme;
    var canRemoveContributor = contributor != context.activeUser!.userName;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              isLightTheme
                  ? AppColors.brandPrimaryLight.withValues(alpha: 0.2)
                  : AppColors.brandPrimary.withValues(alpha: 0.3),
              isLightTheme
                  ? AppColors.brandAccent.withValues(alpha: 0.15)
                  : AppColors.brandPrimaryDark.withValues(alpha: 0.2),
            ],
          ),
          borderRadius: _kBorderRadiusLarge,
          border: Border.all(
            color: isLightTheme
                ? AppColors.brandPrimary.withValues(alpha: 0.3)
                : AppColors.brandPrimaryLight.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: _kCircleAvatarRadius,
              backgroundColor: isLightTheme
                  ? AppColors.brandPrimary
                  : AppColors.brandPrimaryLight,
              child: Text(
                contributor.isNotEmpty ? contributor[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              contributor,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (canRemoveContributor) const SizedBox(width: 8),
            if (canRemoveContributor)
              InkWell(
                onTap: () => _removeContributor(contributor),
                borderRadius: _kBorderRadiusMedium,
                child: Icon(
                  Icons.close,
                  size: _kIconSizeSmall,
                  color: isLightTheme ? AppColors.error : AppColors.errorLight,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddContributorField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Form(
        key: _userNameFieldFormKey,
        child: Row(
          children: [
            Expanded(
              child: PlatformTextElements.createUsernameFormField(
                context: context,
                controller: _contributorController,
                textInputAction: TextInputAction.done,
                inputDecoration: InputDecoration(
                  icon: const Icon(Icons.person_2_rounded),
                  labelText: context.localizations.userName,
                  errorText: _userExistenceError,
                ),
                onFieldSubmitted: (_) => _validateAndAddContributor(),
                validator: _validateContributor,
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isCheckingUserExistence
                    ? null
                    : _validateAndAddContributor,
                borderRadius: _kBorderRadiusMedium,
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isCheckingUserExistence
                          ? [AppColors.neutral500, AppColors.neutral400]
                          : [AppColors.success, AppColors.successLight],
                    ),
                    borderRadius: _kBorderRadiusMedium,
                    boxShadow: [
                      BoxShadow(
                        color: (_isCheckingUserExistence
                                ? AppColors.neutral500
                                : AppColors.success)
                            .withValues(alpha: 0.3),
                        blurRadius: 8.0,
                      ),
                    ],
                  ),
                  child: _isCheckingUserExistence
                      ? const SizedBox(
                          width: _kIconSizeXLarge,
                          height: _kIconSizeXLarge,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: _kIconSizeXLarge,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _validateAndAddContributor() async {
    // Clear any previous error
    setState(() {
      _userExistenceError = null;
    });

    if (_userNameFieldFormKey.currentState?.validate() != true) {
      return;
    }
    final name = _contributorController.text.trim();
    if (name.isEmpty || _contributors.contains(name)) {
      return;
    }

    setState(() {
      _isCheckingUserExistence = true;
    });

    try {
      final userManagement =
          (context.appDataRepository as AppDataModifier).userManagement;

      final results = await Future.wait([
        userManagement.doesUserNameExist(name),
        Future.delayed(const Duration(seconds: 1)),
      ]);

      final userExists = results[0] as bool;

      setState(() {
        _isCheckingUserExistence = false;
      });

      if (!userExists) {
        // Set error and trigger validation
        setState(() {
          _userExistenceError = context.localizations.tripMateNotFound(name);
        });
        return;
      }

      if (mounted) {
        PlatformDialogElements.showAlertDialog(context, (dialogContext) {
          return AlertDialog(
            title:
                Text(context.localizations.splitExpensesWithNewTripMateMessage),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: Text(context.localizations.no),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _contributors.add(name);
                    _contributorController.clear();
                    _isAddContributorFieldVisible = false;
                    _userExistenceError = null;
                    widget.onContributorsChanged(_contributors);
                  });
                  Navigator.of(dialogContext).pop();
                },
                child: Text(context.localizations.yes),
              ),
            ],
          );
        });
      }
    } catch (e) {
      // Set error and trigger validation
      setState(() {
        _isCheckingUserExistence = false;
        _userExistenceError = 'Error checking user: ${e.toString()}';
      });
      _userNameFieldFormKey.currentState?.validate();
    }
  }

  String? _validateContributor(String? name) {
    if (_contributors.contains(name?.trim())) {
      return 'This name is already added.';
    }
    // Return the user existence error if it exists
    if (_userExistenceError != null) {
      return _userExistenceError;
    }
    return null;
  }

  void _removeContributor(String contributor) {
    setState(() {
      _contributors.remove(contributor);
      widget.onContributorsChanged(_contributors);
    });
  }
}
