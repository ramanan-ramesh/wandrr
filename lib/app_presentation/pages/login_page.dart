import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/app_data/models/auth_type.dart';
import 'package:wandrr/app_data/platform_data_repository_extensions.dart';
import 'package:wandrr/app_presentation/blocs/authentication/auth_bloc.dart';
import 'package:wandrr/app_presentation/blocs/authentication/auth_events.dart';
import 'package:wandrr/app_presentation/blocs/authentication/auth_states.dart';
import 'package:wandrr/app_presentation/blocs/bloc_extensions.dart';
import 'package:wandrr/app_presentation/blocs/master_page/master_page_events.dart';
import 'package:wandrr/app_presentation/extensions.dart';
import 'package:wandrr/app_presentation/widgets/button.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthenticationBloc>(
      create: (context) => AuthenticationBloc(context.getAppLevelData()),
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _LoginPageForm(),
          ),
        ),
      ),
    );
  }
}

class _LoginPageForm extends StatefulWidget {
  const _LoginPageForm({super.key});

  @override
  State<_LoginPageForm> createState() => _LoginPageFormState();
}

class _LoginPageFormState extends State<_LoginPageForm>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  TabController? _tabController;
  static const String googleLogoAsset = 'assets/images/google_logo.png';
  static final _emailRegExValidator = RegExp('.*@.*.com');
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
    _tabController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(_roundedCornerRadius)),
      ),
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _createTabBar(),
            const SizedBox(height: 16.0),
            FocusTraversalOrder(
              order: NumericFocusOrder(1),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildUserNamePasswordForm(),
              ),
            ),
            const SizedBox(height: 24.0),
            FocusTraversalOrder(
              order: NumericFocusOrder(2),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200, minWidth: 150),
                child: _buildSubmitButton(context),
              ),
            ),
            const SizedBox(height: 24.0),
            _buildAlternateLoginMethods(context),
          ],
        ),
      ),
    );
  }

  StatefulWidget _buildSubmitButton(BuildContext context) {
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
            String username = _usernameController.text;
            String password = _passwordController.text;

            context.addAuthenticationEvent(AuthenticateWithUsernamePassword(
                userName: username,
                passWord: password,
                isLogin: _tabController!.index == 0));
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

  Column _buildAlternateLoginMethods(BuildContext context) {
    return Column(
      children: [
        Text(
          context.withLocale().alternativeLogin,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAlternateLoginProviderButton(
                AuthenticationType.Google, googleLogoAsset, context),
          ],
        ),
      ],
    );
  }

  Widget _buildAlternateLoginProviderButton(AuthenticationType thirdParty,
      String thirdPartyLogoAssetName, BuildContext context) {
    return Material(
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAliasWithSaveLayer,
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
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_roundedCornerRadius),
          border: Border.all(color: Colors.green),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: Theme.of(context).tabBarTheme.indicatorColor,
            borderRadius: BorderRadius.circular(_roundedCornerRadius),
          ),
          tabs: [
            Tab(text: context.withLocale().login),
            Tab(text: context.withLocale().register),
          ],
        ),
      ),
    );
  }

  Widget _buildUserNamePasswordForm() {
    return Form(
      key: _formKey,
      child: BlocConsumer<AuthenticationBloc, AuthenticationState>(
        builder: (BuildContext context, AuthenticationState state) {
          return FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: Column(
              children: [
                FocusTraversalOrder(
                  order: NumericFocusOrder(1),
                  child: _createUserNameField(state),
                ),
                const SizedBox(height: 16.0),
                FocusTraversalOrder(
                  order: NumericFocusOrder(2),
                  child: _createPasswordField(state),
                )
              ],
            ),
          );
        },
        listener: (BuildContext context, AuthenticationState state) {},
      ),
    );
  }

  Widget _createPasswordField(AuthenticationState authState) {
    String? errorText;
    if (authState is AuthenticationFailure) {
      if (authState.failureReason == AuthenticationFailures.WrongPassword) {
        errorText = context.withLocale().wrong_password_entered;
      }
    }
    return _PasswordField(
      controller: _passwordController,
      textInputAction: TextInputAction.done,
      labelText: context.withLocale().password,
      errorText: errorText,
      validator: (password) {
        if (password != null) {
          if (password.length <= 6) {
            return context.withLocale().password_short;
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
          AuthenticationFailures.UsernameAlreadyExists) {
        errorText = context.withLocale().userNameAlreadyExists;
      } else if (authState.failureReason ==
          AuthenticationFailures.NoSuchUsernameExists) {
        errorText = context.withLocale().noSuchUserExists;
      }
    }
    return TextFormField(
      textInputAction: TextInputAction.next,
      controller: _usernameController,
      decoration: InputDecoration(
        icon: const Icon(Icons.person_2_rounded),
        labelText: context.withLocale().userName,
        errorText: errorText,
      ),
      validator: (username) {
        if (username != null) {
          var matches = _emailRegExValidator.firstMatch(username);
          final matchedText = matches?.group(0);
          if (matchedText != username) {
            return context.withLocale().enterValidEmail;
          }
        }
        return null;
      },
    );
  }
}

class _PasswordField extends StatefulWidget {
  _PasswordField(
      {super.key,
      TextEditingController? controller,
      this.labelText,
      this.errorText,
      this.helperText,
      this.textInputAction,
      this.validator})
      : controller = controller ?? TextEditingController();

  final TextInputAction? textInputAction;
  final TextEditingController? controller;
  final String? labelText, errorText, helperText;
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
        icon: Icon(Icons.password_rounded),
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
