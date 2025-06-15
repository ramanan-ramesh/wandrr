import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/data/app/app_data_repository_extensions.dart';
import 'package:wandrr/data/app/models/auth_type.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/blocs/authentication/auth_bloc.dart';
import 'package:wandrr/presentation/app/blocs/authentication/auth_events.dart';
import 'package:wandrr/presentation/app/blocs/authentication/auth_states.dart';
import 'package:wandrr/presentation/app/blocs/bloc_extensions.dart';
import 'package:wandrr/presentation/app/blocs/master_page/master_page_events.dart';
import 'package:wandrr/presentation/app/widgets/button.dart';
import 'package:wandrr/presentation/app/widgets/card.dart';
import 'package:wandrr/presentation/app/widgets/text.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthenticationBloc>(
      create: (context) =>
          AuthenticationBloc(context.appDataRepository.googleWebClientId),
      child: const Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: _LoginPageForm(),
          ),
        ),
      ),
    );
  }
}

class _LoginPageForm extends StatefulWidget {
  const _LoginPageForm();

  @override
  State<_LoginPageForm> createState() => _LoginPageFormState();
}

class _LoginPageFormState extends State<_LoginPageForm>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late TabController _tabController;
  static const String googleLogoAsset = 'assets/images/google_logo.png';
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
    return PlatformCard(
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
                constraints: const BoxConstraints(maxWidth: 200, minWidth: 150),
                child: _createSubmitButton(context),
              ),
            ),
            const SizedBox(height: 24.0),
            _createAlternateLoginMethods(context),
          ],
        ),
      ),
    );
  }

  Widget _createSubmitButton(BuildContext context) {
    return BlocConsumer<AuthenticationBloc, AuthenticationState>(
      builder: (BuildContext context, AuthenticationState state) {
        var isSubmitted = false;
        if (state is AuthenticationFailure) {
          isSubmitted = false;
        } else if (state is Authenticating) {
          isSubmitted = true;
        }
        return PlatformSubmitterFAB.form(
          icon: Icons.login_rounded,
          isSubmitted: isSubmitted,
          context: context,
          formState: _formKey,
          isEnabledInitially: true,
          validationSuccessCallback: () {
            var username = _usernameController.text;
            var password = _passwordController.text;

            context.addAuthenticationEvent(AuthenticateWithUsernamePassword(
                userName: username,
                passWord: password,
                isLogin: _tabController.index == 0));
          },
        );
      },
      listener: (BuildContext context, AuthenticationState state) {
        if (state is AuthenticationSuccess) {
          context.addMasterPageEvent(ChangeUser.signIn(
              authProviderUser: state.authProviderUser,
              authenticationType: state.authenticationType));
        }
      },
    );
  }

  Widget _createAlternateLoginMethods(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          context.localizations.alternativeLogin,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16.0),
        _createAlternateAuthProviderButton(
            AuthenticationType.google, googleLogoAsset, context),
      ],
    );
  }

  Widget _createAlternateAuthProviderButton(AuthenticationType thirdParty,
      String thirdPartyLogoAssetName, BuildContext context) {
    return Material(
      shape: const CircleBorder(),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        splashColor: Colors.white30,
        onTap: () {
          context
              .addAuthenticationEvent(AuthenticateWithThirdParty(thirdParty));
        },
        child: Ink.image(
          image: AssetImage(thirdPartyLogoAssetName),
          fit: BoxFit.cover,
          height: 60,
          width: 60,
        ),
      ),
    );
  }

  Widget _createTabBar() {
    return ClipRRect(
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
  }

  Widget _createUserNamePasswordForm() {
    return Form(
      key: _formKey,
      child: BlocConsumer<AuthenticationBloc, AuthenticationState>(
        builder: (BuildContext context, AuthenticationState state) {
          return FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: Column(
              children: [
                FocusTraversalOrder(
                  order: const NumericFocusOrder(1),
                  child: _createUserNameField(state),
                ),
                const SizedBox(height: 16.0),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(2),
                  child: _createPasswordField(state),
                )
              ],
            ),
          );
        },
        listener: (BuildContext context, AuthenticationState state) {},
        buildWhen: (previousState, currentState) {
          return currentState is Authenticating ||
              currentState is AuthenticationFailure ||
              currentState is AuthenticationSuccess;
        },
      ),
    );
  }

  Widget _createPasswordField(AuthenticationState authState) {
    String? errorText;
    if (authState is AuthenticationFailure) {
      if (authState.failureReason == AuthenticationFailureCode.wrongPassword) {
        errorText = context.localizations.wrong_password_entered;
      }
    }
    return _PasswordField(
      controller: _passwordController,
      textInputAction: TextInputAction.done,
      labelText: context.localizations.password,
      errorText: errorText,
      validator: (password) {
        if (password != null) {
          if (password.length <= 6) {
            return context.localizations.password_short;
          }
        }
        return null;
      },
    );
  }

  Widget _createUserNameField(AuthenticationState authState) {
    String? errorText;
    if (authState is AuthenticationFailure) {
      if (authState.failureReason ==
          AuthenticationFailureCode.usernameAlreadyExists) {
        errorText = context.localizations.userNameAlreadyExists;
      } else if (authState.failureReason ==
          AuthenticationFailureCode.noSuchUsernameExists) {
        errorText = context.localizations.noSuchUserExists;
      }
    }
    return PlatformTextElements.createUsernameFormField(
      context: context,
      textInputAction: TextInputAction.next,
      controller: _usernameController,
      readonly:
          authState is Authenticating || authState is AuthenticationSuccess,
      inputDecoration: InputDecoration(
        icon: const Icon(Icons.person_2_rounded),
        labelText: context.localizations.userName,
        errorText: errorText,
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  _PasswordField(
      {TextEditingController? controller,
      this.labelText,
      this.errorText,
      this.textInputAction,
      this.validator})
      : controller = controller ?? TextEditingController();

  final TextInputAction? textInputAction;
  final TextEditingController? controller;
  final String? labelText, errorText;
  final FormFieldValidator<String>? validator;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscurePassword = true;
  late FocusNode focusNode;

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
  Widget build(BuildContext context) {
    return TextFormField(
      focusNode: focusNode,
      controller: widget.controller,
      obscureText: _obscurePassword,
      textInputAction: widget.textInputAction,
      decoration: InputDecoration(
        icon: const Icon(Icons.password_rounded),
        labelText: widget.labelText,
        suffixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3.0),
          child: IconButton(
            icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility),
            onPressed: _togglePasswordVisibility,
          ),
        ),
        errorText: widget.errorText,
      ),
      validator: widget.validator,
    );
  }
}
