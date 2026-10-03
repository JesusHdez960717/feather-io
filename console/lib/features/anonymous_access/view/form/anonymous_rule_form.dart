import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

/// Drawer to add an anonymous access rule to a bucket
class AnonymousRuleForm extends StatefulWidget {
  /// Opens the drawer with its own [AnonymousRuleFormCubit]. On save, it reloads
  /// the screen's [AnonymousAccessCubit]
  static Future<void> open(BuildContext context, {required String bucket}) async {
    final key = GlobalKey<_AnonymousRuleFormState>();
    final accessCubit = context.read<AnonymousAccessCubit>();
    final formCubit = AnonymousRuleFormCubit(app.di.find(), app.di.find());

    await FormDrawerTemplate.showAsDialog(
      title: app.intl.anonymousRuleFormTitle,
      description: app.intl.anonymousRuleFormDescription(bucket),
      icon: app.assets.icons.actions.lock,
      loadingId: loadingId,
      footerActions: [
        _AnonymousRuleFormFooter(onSubmit: () => key.currentState?.submit()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: accessCubit),
          BlocProvider.value(value: formCubit),
        ],
        child: AnonymousRuleForm(key: key, bucket: bucket),
      ),
    );
    await formCubit.close();
  }

  /// Id of the drawer's [LoadingOverlay]
  static const String loadingId = 'anonymous-rule-form';

  final String bucket;

  const AnonymousRuleForm({required this.bucket, super.key});

  @override
  State<AnonymousRuleForm> createState() => _AnonymousRuleFormState();
}

class _AnonymousRuleFormState extends State<AnonymousRuleForm> {
  static const int _prefixMaxLength = 128;

  final _formKey = GlobalKey<FormState>();
  final _prefixController = TextEditingController();
  final _prefixFocus = FocusNode();
  AnonymousAccessType _access = AnonymousAccessType.readOnly;

  /// After the first submit attempt it validates on every change
  bool _submitted = false;

  /// API errors per field; cleared when that field is edited
  Map<String, String> _serverErrors = const {};

  /// API error that doesn't belong to a specific field
  String? _formError;

  late final AnonymousRuleFormCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = context.read<AnonymousRuleFormCubit>();
  }

  @override
  void dispose() {
    _prefixController.dispose();
    _prefixFocus.dispose();
    super.dispose();
  }

  bool get _busy => cubit.state is AnonymousRuleFormProcessInProgressState;

  String? _validatePrefix(String? value) {
    if (value == null || value.trim().isEmpty) {
      return app.intl.anonymousRulePrefixRequired;
    }
    return null;
  }

  void submit() {
    if (_busy) return;
    setState(() {
      _submitted = true;
      _formError = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) {
      _prefixFocus.requestFocus();
      return;
    }
    cubit.create(
      bucket: widget.bucket,
      rule: AnonymousRuleModel(
        prefix: _prefixController.text.trim(),
        access: _access,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AnonymousRuleFormCubit, AnonymousRuleFormState>(
      listener: (context, state) {
        if (state is AnonymousRuleFormProcessInProgressState) {
          app.loading.show(id: AnonymousRuleForm.loadingId);
          return;
        }
        app.loading.hide(id: AnonymousRuleForm.loadingId);
        if (state is AnonymousRuleFormProcessingOKState) {
          final accessCubit = context.read<AnonymousAccessCubit>();
          Navigator.of(context).pop();
          accessCubit.load(bucket: widget.bucket);
          app.snack.showSuccess(
            message: app.intl.anonymousRuleCreatedSuccess(state.prefix),
            context: app.context,
          );
        } else if (state is AnonymousRuleFormProcessingErrorState) {
          final prefixError = state.fieldErrors[AnonymousRuleFormField.prefix];
          final others = state.fieldErrors.entries
              .where((e) => e.key != AnonymousRuleFormField.prefix)
              .map((e) => e.value);
          setState(() {
            _serverErrors = {AnonymousRuleFormField.prefix: ?prefixError};
            _formError = state.fieldErrors.isEmpty
                ? state.exception.message
                : others.isEmpty
                ? null
                : others.join('\n');
          });
          if (prefixError != null) _prefixFocus.requestFocus();
        }
      },
      child: Form(
        key: _formKey,
        autovalidateMode: _submitted
            ? AutovalidateMode.always
            : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_formError != null) ...[
              AppFormAlert(
                title: app.intl.anonymousRuleFormErrorTitle,
                message: _formError!,
              ),
              app.dimensions.padding.xl.gap(),
            ],
            _buildSectionTitle(app.intl.anonymousRuleFormSectionPrefix),
            app.dimensions.padding.l.gap(),
            _buildPrefix(),
            app.dimensions.padding.xl.gap(),
            _buildSectionTitle(app.intl.anonymousRuleFormSectionAccess),
            app.dimensions.padding.l.gap(),
            _buildAccess(),
          ],
        ),
      ),
    );
  }

  Widget _buildPrefix() {
    return _card(
      AppFormInput(
        controller: _prefixController,
        focusNode: _prefixFocus,
        autofocus: true,
        label: app.intl.anonymousRulePrefixLabel,
        hint: app.intl.anonymousRulePrefixHint,
        helperText: app.intl.anonymousRulePrefixHelper,
        errorText: _serverErrors[AnonymousRuleFormField.prefix],
        prefix: Padding(
          padding: EdgeInsets.only(left: app.dimensions.padding.m),
          child: Text(
            '/${widget.bucket}/',
            style: app.textTheme.bodyLarge?.copyWith(
              fontFamily: 'monospace',
              color: app.colors.neutral.grey4,
            ),
          ),
        ),
        showCounter: true,
        maxLength: _prefixMaxLength,
        validator: _validatePrefix,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => submit(),
        onChange: (_) {
          if (_serverErrors.isEmpty) return;
          setState(() => _serverErrors = const {});
        },
      ),
    );
  }

  Widget _buildAccess() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, access) in AnonymousAccessType.values.indexed) ...[
          if (index > 0) app.dimensions.padding.m.gap(),
          Expanded(
            child: _AccessOption(
              access: access,
              selected: access == _access,
              onTap: () => setState(() => _access = access),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: app.textTheme.labelLarge?.copyWith(
        color: app.colors.primary.primaryFaded,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _card(Widget child) {
    return Container(
      padding: EdgeInsets.all(app.dimensions.padding.l),
      decoration: BoxDecoration(
        color: app.colors.primary.background2,
        borderRadius: app.dimensions.border.borderRadius.m,
        border: Border.all(
          color: app.colors.neutral.grey5.withValues(alpha: 0.3),
        ),
      ),
      child: child,
    );
  }
}

/// Selectable card with an access type, its description and its typical use
class _AccessOption extends StatelessWidget {
  final AnonymousAccessType access;
  final bool selected;
  final VoidCallback onTap;

  const _AccessOption({
    required this.access,
    required this.selected,
    required this.onTap,
  });

  String get _description => switch (access) {
    AnonymousAccessType.readOnly => app.intl.anonymousAccessReadOnlyDescription,
    AnonymousAccessType.writeOnly =>
      app.intl.anonymousAccessWriteOnlyDescription,
    AnonymousAccessType.readWrite =>
      app.intl.anonymousAccessReadWriteDescription,
  };

  String get _useCase => switch (access) {
    AnonymousAccessType.readOnly => app.intl.anonymousAccessReadOnlyUseCase,
    AnonymousAccessType.writeOnly => app.intl.anonymousAccessWriteOnlyUseCase,
    AnonymousAccessType.readWrite => app.intl.anonymousAccessReadWriteUseCase,
  };

  @override
  Widget build(BuildContext context) {
    final accent = app.colors.primary.primaryFaded;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: app.dimensions.border.borderRadius.m,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.all(app.dimensions.padding.l),
          decoration: BoxDecoration(
            color: selected
                ? app.colors.palette.violet.withValues(alpha: 0.18)
                : app.colors.primary.background2,
            borderRadius: app.dimensions.border.borderRadius.m,
            border: Border.all(
              color: selected ? accent : app.colors.neutral.grey5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 18,
                    color: selected ? accent : app.colors.neutral.grey3,
                  ),
                  app.dimensions.padding.s.gap(),
                  Expanded(
                    child: Text(
                      access.label,
                      style: app.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              app.dimensions.padding.s.gap(),
              Text(
                _description,
                style: app.textTheme.bodySmall?.copyWith(
                  color: app.colors.neutral.grey2,
                ),
              ),
              app.dimensions.padding.s.gap(),
              Text(
                _useCase,
                style: app.textTheme.bodySmall?.copyWith(
                  color: access == AnonymousAccessType.readWrite
                      ? app.colors.primary.secondary
                      : app.colors.neutral.grey3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Drawer footer: *Cancel* and *Add rule*
class _AnonymousRuleFormFooter extends StatelessWidget {
  final VoidCallback onSubmit;

  const _AnonymousRuleFormFooter({required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PrimaryButton.secondary(
          onPressed: () => Navigator.of(context).maybePop(),
          title: app.intl.cancel,
          h: 40,
          w: 100,
        ),
        app.dimensions.padding.m.gap(),
        PrimaryButton.primary(
          onPressed: onSubmit,
          title: app.intl.anonymousRuleAdd,
          h: 40,
          w: 170,
          icon: app.assets.icons.actions.add,
        ),
      ],
    );
  }
}
