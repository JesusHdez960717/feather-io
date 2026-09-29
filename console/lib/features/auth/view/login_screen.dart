import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class LoginScreenNavigator {
  String get name => 'login';

  String get path => '/login';

  Widget builder(BuildContext context, GoRouterState state) {
    return const LoginScreen();
  }

  void neglectGo() {
    Router.neglect(app.context, () {
      app.navigator.go(name);
    });
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

  @override
  void dispose() {
    _accessController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  void _onLogin() {
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
        if (state is AuthProcessingOKState) {
          BrowserScreen.navigator.neglectGo();
        } else if (state is AuthProcessingErrorState) {
          app.snack.showError(message: state.message, context: context);
        }
      },
      child: Scaffold(
        backgroundColor: app.colors.primary.background1,
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: EdgeInsets.all(app.dimensions.padding.l),
            decoration: BoxDecoration(
              color: app.colors.primary.background2,
              borderRadius: app.dimensions.border.borderRadius.m,
              border: Border.all(color: app.colors.primary.background3),
            ),
            child: Form(
              key: _formKey,
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
                    validator: (v) =>
                        v?.isEmpty == true ? app.intl.required : null,
                  ),
                  app.dimensions.padding.m.gap(),
                  AppFormPasswordInput(
                    controller: _secretController,
                    label: app.intl.loginSecretKey,
                    hint: app.intl.loginSecretKeyHint,
                    validator: (v) =>
                        v?.isEmpty == true ? app.intl.required : null,
                  ),
                  app.dimensions.padding.xl.gap(),
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthProcessInProgressState;
                      return PrimaryButton.primary(
                        onPressed: isLoading ? () {} : _onLogin,
                        title: isLoading
                            ? app.intl.loginInProgress
                            : app.intl.loginButton,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
