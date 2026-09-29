import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BucketCreateForm extends StatefulWidget {
  ///Abre el cajon con su propio [BucketCreateCubit]: la carga y los errores se
  ///muestran dentro del formulario. Al crear, recarga el [BucketCubit] de la pantalla
  static Future<void> open(BuildContext context) async {
    final key = GlobalKey<BucketCreateFormState>();
    final bucketCubit = context.read<BucketCubit>();
    final createCubit = BucketCreateCubit(app.di.find(), app.di.find());

    await FormDrawerTemplate.showAsDialog(
      title: app.intl.bucketsCreate,
      description: app.intl.bucketCreateDescription,
      icon: app.assets.icons.storage.bucket,
      footerActions: [
        BlocProvider.value(
          value: createCubit,
          child: _BucketCreateFooter(
            onSubmit: () => key.currentState?.submit(),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: bucketCubit),
          BlocProvider.value(value: createCubit),
        ],
        child: BucketCreateForm(key: key),
      ),
    );
    await createCubit.close();
  }

  const BucketCreateForm({super.key});

  @override
  State<BucketCreateForm> createState() => BucketCreateFormState();
}

class BucketCreateFormState extends State<BucketCreateForm> {
  static const int _nameMaxLength = 63;
  static const int _descriptionMaxLength = 1024;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _nameFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  Color? _color;

  ///Tras el primer intento de envio se valida en cada cambio
  bool _submitted = false;

  ///Errores de la API por campo; se borran al editar ese campo
  Map<String, String> _serverErrors = const {};

  ///Error de la API que no es de un campo concreto
  String? _formError;

  late final BucketCreateCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = context.read<BucketCreateCubit>();
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _nameFocus.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  bool get _busy => cubit.state is BucketCreateProcessInProgressState;

  static final _nameChars = RegExp(r'^[a-z0-9-]*$');

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return app.intl.bucketNameRequired;
    }
    if (value.length < 3 || value.length > _nameMaxLength) {
      return app.intl.bucketNameLength;
    }
    if (!_nameChars.hasMatch(value)) {
      return app.intl.bucketNameChars;
    }
    if (value.startsWith('-') || value.endsWith('-')) {
      return app.intl.bucketNameHyphenEdges;
    }
    return null;
  }

  ///Lo que ya no se arregla escribiendo mas (caracteres, guion al inicio) falla
  ///al momento; la longitud y el guion final solo tras intentar enviar
  List<AppValidationRule> get _nameRules {
    final name = _nameController.text;
    final lengthOk = name.length >= 3 && name.length <= _nameMaxLength;

    AppRuleState state({required bool ok, required bool failNow}) {
      if (ok) return AppRuleState.ok;
      return failNow || _submitted ? AppRuleState.fail : AppRuleState.pending;
    }

    return [
      AppValidationRule(
        label: app.intl.bucketNameLength,
        state: state(ok: lengthOk, failNow: false),
      ),
      AppValidationRule(
        label: app.intl.bucketRuleChars,
        state: name.isEmpty
            ? AppRuleState.pending
            : state(ok: _nameChars.hasMatch(name), failNow: true),
      ),
      AppValidationRule(
        label: app.intl.bucketRuleHyphenEdges,
        state: name.isEmpty
            ? AppRuleState.pending
            : state(
                ok: !name.startsWith('-') && !name.endsWith('-'),
                failNow: name.startsWith('-'),
              ),
      ),
    ];
  }

  void _clearServerError(String field) {
    if (!_serverErrors.containsKey(field)) return;
    setState(() => _serverErrors = {..._serverErrors}..remove(field));
  }

  void submit() {
    if (_busy) return;
    setState(() {
      _submitted = true;
      _formError = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) {
      _nameFocus.requestFocus();
      return;
    }
    cubit.create(
      name: _nameController.text,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      color: _color?.toARGB32(),
    );
  }

  void _onState(BuildContext context, BucketCreateState state) {
    if (state is BucketCreateProcessingOKState) {
      final bucketCubit = context.read<BucketCubit>();
      Navigator.of(context).pop();
      bucketCubit.load();
      app.snack.showSuccess(
        message: app.intl.bucketCreatedSuccess(state.name),
        context: app.context,
      );
    } else if (state is BucketCreateProcessingErrorState) {
      const fields = {BucketCreateField.name, BucketCreateField.description};
      final unmatched = state.fieldErrors.entries
          .where((e) => !fields.contains(e.key))
          .map((e) => e.value);
      setState(() {
        _serverErrors = {
          for (final e in state.fieldErrors.entries)
            if (fields.contains(e.key)) e.key: e.value,
        };
        _formError = state.fieldErrors.isEmpty
            ? state.exception.message
            : unmatched.isEmpty
            ? null
            : unmatched.join('\n');
      });
      if (_serverErrors.containsKey(BucketCreateField.name)) {
        _nameFocus.requestFocus();
      } else if (_serverErrors.containsKey(BucketCreateField.description)) {
        _descriptionFocus.requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BucketCreateCubit, BucketCreateState>(
      listener: _onState,
      builder: (context, state) {
        final busy = state is BucketCreateProcessInProgressState;
        return PopScope(
          canPop: !busy,
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
                    title: app.intl.bucketCreateErrorTitle,
                    message: _formError!,
                  ),
                  app.dimensions.padding.xl.gap(),
                ],
                _buildSection(
                  title: app.intl.bucketCreateSectionGeneral,
                  child: _buildGeneral(busy),
                ),
                app.dimensions.padding.xl.gap(),
                _buildSection(
                  title: app.intl.bucketCreateSectionAdditional,
                  child: _buildAdditional(busy),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGeneral(bool busy) {
    final name = _nameController.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppFormInput(
          controller: _nameController,
          focusNode: _nameFocus,
          autofocus: true,
          enabled: !busy,
          label: app.intl.bucketCreateNameLabel,
          hint: app.intl.bucketCreateNameHint,
          helperText: app.intl.bucketNamePathHint(
            name.isEmpty ? app.intl.bucketCreateNameHint : name,
          ),
          errorText: _serverErrors[BucketCreateField.name],
          showCounter: true,
          maxLength: _nameMaxLength,
          validator: _validateName,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => submit(),
          onChange: (_) => _clearServerError(BucketCreateField.name),
        ),
        app.dimensions.padding.m.gap(),
        AppValidationRules(rules: _nameRules),
      ],
    );
  }

  Widget _buildAdditional(bool busy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppFormInput(
          controller: _descriptionController,
          focusNode: _descriptionFocus,
          enabled: !busy,
          label: app.intl.bucketCreateDescriptionLabel,
          hint: app.intl.bucketCreateDescriptionHint,
          errorText: _serverErrors[BucketCreateField.description],
          maxLines: 3,
          showCounter: true,
          maxLength: _descriptionMaxLength,
          height: 120,
          onChange: (_) => _clearServerError(BucketCreateField.description),
        ),
        app.dimensions.padding.l.gap(),
        Text(
          app.intl.bucketCreateColorLabel,
          style: app.textTheme.bodyMedium!.copyWith(
            color: app.colors.neutral.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        app.dimensions.padding.s.gap(),
        AppColorPicker(
          value: _color,
          enabled: !busy,
          onChanged: (color) => setState(() => _color = color),
          contrastAgainst: app.colors.neutral.white,
          previewIcon: app.assets.icons.storage.bucket,
        ),
      ],
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: app.textTheme.labelLarge?.copyWith(
            color: app.colors.primary.primaryFaded,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        app.dimensions.padding.l.gap(),
        Container(
          padding: EdgeInsets.all(app.dimensions.padding.l),
          decoration: BoxDecoration(
            color: app.colors.primary.background2,
            borderRadius: app.dimensions.border.borderRadius.m,
            border: Border.all(
              color: app.colors.neutral.grey5.withValues(alpha: 0.3),
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}

///Pie del cajon: *Cancelar* y *Crear bucket*, que pasa a carga mientras se envia
class _BucketCreateFooter extends StatelessWidget {
  final VoidCallback onSubmit;

  const _BucketCreateFooter({required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BucketCreateCubit, BucketCreateState>(
      builder: (context, state) {
        final busy = state is BucketCreateProcessInProgressState;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton.secondary(
              onPressed: busy ? null : () => Navigator.of(context).maybePop(),
              title: app.intl.cancel,
              h: 40,
              w: 100,
            ),
            app.dimensions.padding.m.gap(),
            PrimaryButton.primary(
              onPressed: onSubmit,
              isLoading: busy,
              title: busy ? app.intl.bucketsCreating : app.intl.bucketsCreate,
              h: 40,
              w: 160,
              icon: app.assets.icons.actions.add,
            ),
          ],
        );
      },
    );
  }
}
