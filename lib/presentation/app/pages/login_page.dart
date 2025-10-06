import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/asset_manager/assets.gen.dart';
import 'package:wandrr/blocs/app/master_page_bloc.dart';
import 'package:wandrr/blocs/app/master_page_events.dart';
import 'package:wandrr/blocs/app/master_page_states.dart';
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
      onAuthStateChangeBuilder: (state, {required bool canEnable}) =>
          PlatformSubmitterFAB.form(
        icon: Icons.login_rounded,
        formState: _formKey,
        isEnabledInitially: canEnable,
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
        onAuthStateChangeBuilder: (state, {required bool canEnable}) =>
            Material(
          shape: const CircleBorder(),
          clipBehavior: Clip.hardEdge,
          color: Colors.transparent,
          child: InkWell(
            onTap: canEnable
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
              )
            ],
          ),
        ),
      );
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
          }
        },
        onAuthStateChangeBuilder: (state, {required bool canEnable}) =>
            PlatformTextElements.createUsernameFormField(
          context: context,
          controller: widget.textEditingController,
          textInputAction: widget.textInputAction,
          readonly: !canEnable,
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
          }
        },
        onAuthStateChangeBuilder: (state, {required bool canEnable}) =>
            TextFormField(
          readOnly: !canEnable,
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
              if (password.length <= 6) {
                return context.localizations.password_short;
              }
            }
            return null;
          },
        ),
      );
}

class _AuthStateObserver extends StatelessWidget {
  final void Function(AuthStateChanged state)? onAuthStateChangeListener;
  final Widget Function(MasterPageState state, {required bool canEnable})
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
          return onAuthStateChangeBuilder(state, canEnable: canEnable);
        },
        buildWhen: (previousState, currentState) =>
            currentState is AuthStateChanged,
      );
}
