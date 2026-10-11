import 'package:console/app_exporter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class LoginScreenNavigator {
  String get name => RouteNames.login;

  String get path => '/login';

  Widget builder(BuildContext context, GoRouterState state) {
    return const LoginScreen();
  }
}

class LoginScreen extends StatefulWidget {
  static final LoginScreenNavigator navigator = LoginScreenNavigator();

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _accessController = TextEditingController();
  final TextEditingController _secretController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// After the first submit attempt it validates on every change, so an error
  /// goes away as soon as the field is filled
  bool _submitted = false;

  @override
  void dispose() {
    _accessController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (!_submitted) setState(() => _submitted = true);
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().login(
        access: _accessController.text,
        secret: _secretController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        // On success the router leaves the login by itself (it listens to
        // AuthCubit), to the page asked for before logging in. Closing the
        // autofill context first lets the browser offer to save the keys
        if (state is AuthProcessingOKState) {
          TextInput.finishAutofillContext();
        } else if (state is AuthProcessingErrorState) {
          app.snack.showError(message: state.message, context: context);
        }
      },
      child: Scaffold(
        backgroundColor: app.colors.primary.background1,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: ClipRRect(
              borderRadius: app.dimensions.border.borderRadius.m,
              child: BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) => LoadingOverlay(
                  visible: state is AuthProcessInProgressState,
                  overlayWidgetBuilder: LoadingOverlayStyles.form,
                  child: _buildPanel(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanel() {
    return Container(
      padding: EdgeInsets.all(app.dimensions.padding.l),
      decoration: BoxDecoration(
        color: app.colors.primary.background2,
        borderRadius: app.dimensions.border.borderRadius.m,
        border: Border.all(color: app.colors.primary.background3),
      ),
      // The keys go to the browser's password manager (it offers to save them
      // and fills them in), never to the console's own storage
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          autovalidateMode: _submitted
              ? AutovalidateMode.always
              : AutovalidateMode.disabled,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppWordmark(name: app.intl.appName, fontSize: 32),
              app.dimensions.padding.xl.gap(),
              AppFormInput(
                controller: _accessController,
                label: app.intl.loginAccessKey,
                hint: app.intl.loginAccessKeyHint,
                validator: (v) => v?.isEmpty == true ? app.intl.required : null,
                autofillHints: const [AutofillHints.username],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _onLogin(),
              ),
              app.dimensions.padding.m.gap(),
              AppFormPasswordInput(
                controller: _secretController,
                label: app.intl.loginSecretKey,
                hint: app.intl.loginSecretKeyHint,
                validator: (v) => v?.isEmpty == true ? app.intl.required : null,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _onLogin(),
              ),
              app.dimensions.padding.xl.gap(),
              PrimaryButton.primary(
                onPressed: _onLogin,
                title: app.intl.loginButton,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
