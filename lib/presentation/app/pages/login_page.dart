import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/asset_manager/assets.gen.dart';
import 'package:wandrr/blocs/app/bloc.dart';
import 'package:wandrr/blocs/app/events.dart';
import 'package:wandrr/blocs/app/states.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/data/auth/models/auth_type.dart';
import 'package:wandrr/data/auth/models/status.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/widgets/button.dart';
import 'package:wandrr/presentation/app/widgets/card.dart';
import 'package:wandrr/presentation/app/widgets/text.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late final TabController _tabController;
  static const double _roundedCornerRadius = 25.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: PlatformCard(
            child: FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _createTabBar(),
                  const SizedBox(height: 16.0),
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(1),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _createUserNamePasswordForm(),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(2),
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: 200, minWidth: 150),
                      child: _createSubmitButton(context),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(3),
                    child: _ResendVerificationMailButton(
                      userNameController: _usernameController,
                      passwordController: _passwordController,
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  _createAlternateLoginMethods(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _createSubmitButton(BuildContext context) {
    return _AuthStateObserver(
      onAuthStateChangeBuilder: (state, canEnableFormElement) =>
          PlatformSubmitterFAB.form(
        child: Icon(Icons.login_rounded),
        formState: _formKey,
        isEnabledInitially: canEnableFormElement,
        validationSuccessCallback: () {
          var username = _usernameController.text;
          var password = _passwordController.text;

          context.addAuthenticationEvent(AuthenticateWithUsernamePassword(
              userName: username,
              password: password,
              shouldRegister: _tabController.index == 1));
        },
      ),
    );
  }

  Widget _createAlternateLoginMethods(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            context.localizations.alternativeLogin,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16.0),
          _createAlternateAuthProviderButton(
              AuthenticationType.google, Assets.images.googleLogo, context),
        ],
      );

  Widget _createAlternateAuthProviderButton(AuthenticationType thirdParty,
          AssetGenImage thirdPartyLogoAsset, BuildContext context) =>
      _AuthStateObserver(
        onAuthStateChangeBuilder: (state, canEnableFormElement) => Material(
          shape: const CircleBorder(),
          clipBehavior: Clip.hardEdge,
          color: Colors.transparent,
          child: InkWell(
            onTap: canEnableFormElement
                ? () {
                    context.addAuthenticationEvent(
                        AuthenticateWithThirdParty(thirdParty));
                  }
                : null,
            child: Ink.image(
              image: thirdPartyLogoAsset.provider(),
              fit: BoxFit.cover,
              height: 60,
              width: 60,
            ),
          ),
        ),
      );

  Widget _createTabBar() => ClipRRect(
        borderRadius: BorderRadius.circular(_roundedCornerRadius),
        clipBehavior: Clip.hardEdge,
        child: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: context.localizations.login),
            Tab(text: context.localizations.register),
          ],
        ),
      );

  Widget _createUserNamePasswordForm() => Form(
        key: _formKey,
        child: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: Column(
            children: [
              FocusTraversalOrder(
                order: const NumericFocusOrder(1),
                child: _UserNameField(
                  textEditingController: _usernameController,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 16.0),
              FocusTraversalOrder(
                order: const NumericFocusOrder(2),
                child: _PasswordField(
                  controller: _passwordController,
                  textInputAction: TextInputAction.done,
                ),
              ),
              _EmailVerificationStatusMessage(tabController: _tabController),
            ],
          ),
        ),
      );
}

class _EmailVerificationStatusMessage extends StatelessWidget {
  final TabController tabController;

  const _EmailVerificationStatusMessage({required this.tabController});

  @override
  Widget build(BuildContext context) {
    return _AuthStateObserver(
      onAuthStateChangeBuilder: (state, canEnableFormElement) {
        if (state is AuthStateChanged &&
            (state.authStatus == AuthStatus.verificationPending ||
                state.authStatus == AuthStatus.verificationResent)) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              context.localizations.verificationPending,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: Colors.red),
            ),
          );
        }
        return SizedBox.shrink();
      },
    );
  }
}

class _ResendVerificationMailButton extends StatelessWidget {
  final TextEditingController userNameController;
  final TextEditingController passwordController;

  const _ResendVerificationMailButton(
      {required this.userNameController, required this.passwordController});

  @override
  Widget build(BuildContext context) {
    return _AuthStateObserver(
      onAuthStateChangeBuilder: (state, canEnableFormElement) {
        var isVisible = state is AuthStateChanged &&
            (state.authStatus == AuthStatus.verificationPending ||
                state.authStatus == AuthStatus.verificationResent);
        return AnimatedOpacity(
          opacity: isVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 1500),
          child: TextButton(
            child: Text(context.localizations.resendVerificationMail),
            onPressed: () {
              context.addAuthenticationEvent(ResendEmailVerification(
                  userName: userNameController.text,
                  password: passwordController.text));
            },
          ),
        );
      },
    );
  }
}

class _UserNameField extends StatefulWidget {
  final TextEditingController textEditingController;
  final TextInputAction? textInputAction;

  const _UserNameField(
      {required this.textEditingController, this.textInputAction});

  @override
  State<_UserNameField> createState() => _UserNameFieldState();
}

class _UserNameFieldState extends State<_UserNameField> {
  String? _errorText;

  @override
  Widget build(BuildContext context) => _AuthStateObserver(
        onAuthStateChangeListener: (state) {
          if (state.authStatus == AuthStatus.usernameAlreadyExists) {
            _errorText = context.localizations.userNameAlreadyExists;
          } else if (state.authStatus == AuthStatus.noSuchUsernameExists) {
            _errorText = context.localizations.noSuchUserExists;
          } else {
            _errorText = null;
          }
        },
        onAuthStateChangeBuilder: (state, canEnableFormElement) =>
            PlatformTextElements.createUsernameFormField(
          context: context,
          controller: widget.textEditingController,
          textInputAction: widget.textInputAction,
          readonly: !canEnableFormElement,
          inputDecoration: InputDecoration(
            icon: const Icon(Icons.person_2_rounded),
            labelText: context.localizations.userName,
            errorText: _errorText,
          ),
          onEmailChanged: (text, {required bool isValid}) {
            if (_errorText != null) {
              setState(() {
                _errorText = null;
              });
            }
          },
        ),
      );
}

class _PasswordField extends StatefulWidget {
  const _PasswordField({
    required this.controller,
    this.textInputAction,
  });

  final TextInputAction? textInputAction;
  final TextEditingController controller;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscurePassword = true;
  String? _errorText;
  late final FocusNode focusNode;

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode();
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  @override
  Widget build(BuildContext context) => _AuthStateObserver(
        onAuthStateChangeListener: (state) {
          if (state.authStatus == AuthStatus.wrongPassword) {
            _errorText = context.localizations.wrong_password_entered;
          } else {
            _errorText = null;
          }
        },
        onAuthStateChangeBuilder: (state, canEnableFormElement) =>
            TextFormField(
          readOnly: !canEnableFormElement,
          focusNode: focusNode,
          controller: widget.controller,
          obscureText: _obscurePassword,
          textInputAction: widget.textInputAction,
          onChanged: (password) {
            if (_errorText != null) {
              setState(() {
                _errorText = null;
              });
            }
          },
          decoration: InputDecoration(
            icon: const Icon(Icons.password_rounded),
            labelText: context.localizations.password,
            suffixIcon: Padding(
              padding: const EdgeInsets.only(left: 3.0),
              child: IconButton(
                icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: _togglePasswordVisibility,
              ),
            ),
            errorText: _errorText,
          ),
          validator: (password) {
            if (password != null) {
              var passwordPolicy = context.localizations.password_policy;
              if (password.length < 8 || password.length > 20) {
                return passwordPolicy;
              }
              if (!RegExp('[A-Z]').hasMatch(password)) {
                return passwordPolicy;
              }
              if (!RegExp('[a-z]').hasMatch(password)) {
                return passwordPolicy;
              }
              if (!RegExp('[0-9]').hasMatch(password)) {
                return passwordPolicy;
              }
              if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) {
                return passwordPolicy;
              }
            }
            return null;
          },
        ),
      );
}

class _AuthStateObserver extends StatelessWidget {
  final void Function(AuthStateChanged state)? onAuthStateChangeListener;
  final Widget Function(MasterPageState state, bool canEnableFormElement)
      onAuthStateChangeBuilder;

  const _AuthStateObserver({
    required this.onAuthStateChangeBuilder,
    this.onAuthStateChangeListener,
  });

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<MasterPageBloc, MasterPageState>(
        listener: (context, state) {
          if (onAuthStateChangeListener != null && state is AuthStateChanged) {
            onAuthStateChangeListener!(state);
          }
        },
        builder: (context, state) {
          var canEnable = !(state is AuthStateChanged &&
              (state.authStatus == AuthStatus.authenticating ||
                  state.authStatus == AuthStatus.loggedIn));
          return onAuthStateChangeBuilder(state, canEnable);
        },
        buildWhen: (previousState, currentState) =>
            currentState is AuthStateChanged,
      );
}
