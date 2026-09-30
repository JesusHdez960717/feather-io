import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

///Cajon para crear un bucket o, con [bucket], editar su descripcion y color
class BucketForm extends StatefulWidget {
  ///Abre el cajon con su propio [BucketFormCubit]: mientras se envia, el cajon
  ///muestra su velo de carga y los errores se muestran dentro del formulario.
  ///Al guardar, recarga el [BucketCubit] de la pantalla
  static Future<void> open(BuildContext context, {BucketModel? bucket}) async {
    final key = GlobalKey<_BucketFormState>();
    final bucketCubit = context.read<BucketCubit>();
    final formCubit = BucketFormCubit(app.di.find(), app.di.find());
    final isEdit = bucket != null;

    await FormDrawerTemplate.showAsDialog(
      title: isEdit ? app.intl.bucketsEdit : app.intl.bucketsCreate,
      description: isEdit
          ? app.intl.bucketEditDescription(bucket.name)
          : app.intl.bucketCreateDescription,
      icon: app.assets.icons.storage.bucket,
      loadingId: loadingId,
      footerActions: [
        _BucketFormFooter(
          isEdit: isEdit,
          onSubmit: () => key.currentState?.submit(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: bucketCubit),
          BlocProvider.value(value: formCubit),
        ],
        child: BucketForm(key: key, bucket: bucket),
      ),
    );
    await formCubit.close();
  }

  ///Id del [LoadingOverlay] del cajon
  static const String loadingId = 'bucket-form';

  ///Bucket a editar; si es null, el cajon crea uno nuevo
  final BucketModel? bucket;

  const BucketForm({super.key, this.bucket});

  @override
  State<BucketForm> createState() => _BucketFormState();
}

class _BucketFormState extends State<BucketForm> {
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

  late final BucketFormCubit cubit;

  ///Al editar, el nombre no se puede cambiar
  bool get _isEdit => widget.bucket != null;

  @override
  void initState() {
    super.initState();
    cubit = context.read<BucketFormCubit>();
    final bucket = widget.bucket;
    if (bucket != null) {
      _nameController.text = bucket.name;
      _descriptionController.text = bucket.description ?? '';
      _color = bucket.uiColor;
    }
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

  bool get _busy => cubit.state is BucketFormProcessInProgressState;

  static final _nameChars = RegExp(r'^[a-z0-9-]*$');

  String? _validateName(String? value) {
    if (_isEdit) return null;
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
      (_isEdit ? _descriptionFocus : _nameFocus).requestFocus();
      return;
    }
    final description = _descriptionController.text.isEmpty
        ? null
        : _descriptionController.text;
    if (_isEdit) {
      cubit.update(
        name: widget.bucket!.name,
        description: description,
        color: _color?.toARGB32(),
      );
    } else {
      cubit.create(
        name: _nameController.text,
        description: description,
        color: _color?.toARGB32(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BucketFormCubit, BucketFormState>(
      listener: (BuildContext context, BucketFormState state) {
        if (state is BucketFormProcessInProgressState) {
          app.loading.show(id: BucketForm.loadingId);
          return;
        }
        app.loading.hide(id: BucketForm.loadingId);
        if (state is BucketFormProcessingOKState) {
          final bucketCubit = context.read<BucketCubit>();
          Navigator.of(context).pop();
          bucketCubit.load();
          app.snack.showSuccess(
            message: _isEdit
                ? app.intl.bucketUpdatedSuccess(state.name)
                : app.intl.bucketCreatedSuccess(state.name),
            context: app.context,
          );
        } else if (state is BucketFormProcessingErrorState) {
          const fields = {BucketFormField.name, BucketFormField.description};
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
          if (_serverErrors.containsKey(BucketFormField.name)) {
            _nameFocus.requestFocus();
          } else if (_serverErrors.containsKey(BucketFormField.description)) {
            _descriptionFocus.requestFocus();
          }
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
                title: _isEdit
                    ? app.intl.bucketEditErrorTitle
                    : app.intl.bucketCreateErrorTitle,
                message: _formError!,
              ),
              app.dimensions.padding.xl.gap(),
            ],
            _buildSection(
              title: app.intl.bucketCreateSectionGeneral,
              child: _buildGeneral(),
            ),
            app.dimensions.padding.xl.gap(),
            _buildSection(
              title: app.intl.bucketCreateSectionAdditional,
              child: _buildAdditional(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneral() {
    final name = _nameController.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppFormInput(
          controller: _nameController,
          focusNode: _nameFocus,
          autofocus: !_isEdit,
          enabled: !_isEdit,
          label: app.intl.bucketCreateNameLabel,
          hint: app.intl.bucketCreateNameHint,
          helperText: app.intl.bucketNamePathHint(
            name.isEmpty ? app.intl.bucketCreateNameHint : name,
          ),
          errorText: _serverErrors[BucketFormField.name],
          showCounter: !_isEdit,
          maxLength: _nameMaxLength,
          validator: _validateName,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => submit(),
          onChange: (_) => _clearServerError(BucketFormField.name),
        ),
        if (!_isEdit) ...[
          app.dimensions.padding.m.gap(),
          AppValidationRules(rules: _nameRules),
        ],
      ],
    );
  }

  Widget _buildAdditional() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppFormInput(
          controller: _descriptionController,
          focusNode: _descriptionFocus,
          autofocus: _isEdit,
          label: app.intl.bucketCreateDescriptionLabel,
          hint: app.intl.bucketCreateDescriptionHint,
          errorText: _serverErrors[BucketFormField.description],
          maxLines: 3,
          showCounter: true,
          maxLength: _descriptionMaxLength,
          height: 120,
          onChange: (_) => _clearServerError(BucketFormField.description),
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

///Pie del cajon: *Cancelar* y *Crear bucket* (o *Guardar cambios* al editar).
///Mientras se envia, el velo de carga del cajon los cubre
class _BucketFormFooter extends StatelessWidget {
  final bool isEdit;
  final VoidCallback onSubmit;

  const _BucketFormFooter({required this.isEdit, required this.onSubmit});

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
          title: isEdit ? app.intl.bucketEditSave : app.intl.bucketsCreate,
          h: 40,
          w: 160,
          icon: isEdit ? null : app.assets.icons.actions.add,
        ),
      ],
    );
  }
}
