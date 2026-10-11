import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

/// Drawer to create an access key or edit one ([key]): name, expiration,
/// scope (every bucket or some) and the level on each
class AccessKeyForm extends StatefulWidget {
  /// Opens the drawer with its own [AccessKeyFormCubit]. On save it reloads the
  /// screen's [AccessKeyCubit] and, after creating, shows the secret
  static Future<void> open(BuildContext context, {AccessKeyModel? key}) async {
    final formKey = GlobalKey<_AccessKeyFormState>();
    final keysCubit = context.read<AccessKeyCubit>();
    final bucketCubit = context.read<BucketCubit>();
    if (bucketCubit.state is! BucketLoadingSuccessState) bucketCubit.load();
    final formCubit = AccessKeyFormCubit(app.di.find(), app.di.find());

    await FormDrawerTemplate.showAsDialog(
      title: key == null
          ? app.intl.accessKeyFormCreateTitle
          : app.intl.accessKeyFormEditTitle,
      description: key == null
          ? app.intl.accessKeyFormCreateDescription
          : app.intl.accessKeyFormEditDescription(key.id),
      icon: app.assets.icons.actions.key,
      loadingId: loadingId,
      footerActions: [
        _AccessKeyFormFooter(
          editing: key != null,
          onSubmit: () => formKey.currentState?.submit(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: keysCubit),
          BlocProvider.value(value: bucketCubit),
          BlocProvider.value(value: formCubit),
        ],
        child: AccessKeyForm(key: formKey, keyModel: key),
      ),
    );
    await formCubit.close();
  }

  /// Id of the drawer's [LoadingOverlay]
  static const String loadingId = 'access-key-form';

  /// The key being edited; null to create one
  final AccessKeyModel? keyModel;

  const AccessKeyForm({this.keyModel, super.key});

  @override
  State<AccessKeyForm> createState() => _AccessKeyFormState();
}

/// Expiration choices; [keep] only when editing a key that already has a date
enum _Expiry { keep, never, days30, days90, year }

class _AccessKeyFormState extends State<AccessKeyForm> {
  static const int _nameMaxLength = 64;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _nameFocus = FocusNode();

  late _Expiry _expiry;
  late bool _allBuckets;
  late AccessKeyLevel _allLevel;

  /// Level of each checked bucket
  late final Map<String, AccessKeyLevel> _checked;

  /// Level a bucket gets when checked (and keeps while unchecked)
  final Map<String, AccessKeyLevel> _levels = {};

  /// After the first submit attempt it validates on every change
  bool _submitted = false;

  /// API errors per field; cleared when that field is edited
  Map<String, String> _serverErrors = const {};

  /// API error that doesn't belong to the name
  String? _formError;

  late final AccessKeyFormCubit cubit;

  AccessKeyModel? get _editing => widget.keyModel;

  @override
  void initState() {
    super.initState();
    cubit = context.read<AccessKeyFormCubit>();
    final key = _editing;
    _nameController = TextEditingController(text: key?.name ?? '');
    _expiry = key?.expiresAt != null ? _Expiry.keep : _Expiry.never;
    _allBuckets = key?.allBuckets != null;
    _allLevel = key?.allBuckets ?? AccessKeyLevel.readOnly;
    _checked = {for (final g in key?.grants ?? const []) g.bucket: g.access};
    _levels.addAll(_checked);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  bool get _busy => cubit.state is AccessKeyFormProcessInProgressState;

  bool get _missingBuckets => !_allBuckets && _checked.isEmpty;

  DateTime? get _expiresAt {
    final now = DateTime.now();
    return switch (_expiry) {
      _Expiry.keep => _editing?.expiresAt,
      _Expiry.never => null,
      _Expiry.days30 => now.add(const Duration(days: 30)),
      _Expiry.days90 => now.add(const Duration(days: 90)),
      _Expiry.year => DateTime(now.year + 1, now.month, now.day, now.hour),
    };
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return app.intl.accessKeyNameRequired;
    }
    return null;
  }

  void submit() {
    if (_busy) return;
    setState(() {
      _submitted = true;
      _formError = null;
    });
    final validName = _formKey.currentState?.validate() ?? false;
    if (!validName) {
      _nameFocus.requestFocus();
      return;
    }
    if (_missingBuckets) return;
    cubit.save(
      id: _editing?.id,
      draft: AccessKeyDraft(
        name: _nameController.text.trim(),
        enabled: _editing?.enabled ?? true,
        allBuckets: _allBuckets ? _allLevel : null,
        grants: _allBuckets
            ? const []
            : [
                for (final entry in _checked.entries)
                  AccessKeyGrantModel(bucket: entry.key, access: entry.value),
              ],
        expiresAt: _expiresAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AccessKeyFormCubit, AccessKeyFormState>(
      listener: (context, state) {
        if (state is AccessKeyFormProcessInProgressState) {
          app.loading.show(id: AccessKeyForm.loadingId);
          return;
        }
        app.loading.hide(id: AccessKeyForm.loadingId);
        if (state is AccessKeyFormProcessingOKState) {
          final keysCubit = context.read<AccessKeyCubit>();
          Navigator.of(context).pop();
          keysCubit.load();
          if (state.created) {
            AccessKeySecretDialog.show(
              key: state.key,
              cubit: keysCubit,
              created: true,
            );
          } else {
            app.snack.showSuccess(
              message: app.intl.accessKeySavedSuccess(state.key.name),
              context: app.context,
            );
          }
        } else if (state is AccessKeyFormProcessingErrorState) {
          final nameError = state.fieldErrors[AccessKeyFormField.name];
          final others = state.fieldErrors.entries
              .where((e) => e.key != AccessKeyFormField.name)
              .map((e) => e.value);
          setState(() {
            _serverErrors = {AccessKeyFormField.name: ?nameError};
            _formError = state.fieldErrors.isEmpty
                ? state.exception.message
                : others.isEmpty
                ? null
                : others.join('\n');
          });
          if (nameError != null) _nameFocus.requestFocus();
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
                title: app.intl.accessKeyFormErrorTitle,
                message: _formError!,
              ),
              app.dimensions.padding.xl.gap(),
            ],
            _sectionTitle(app.intl.accessKeyFormSectionIdentity),
            app.dimensions.padding.l.gap(),
            _buildIdentity(),
            app.dimensions.padding.xl.gap(),
            _sectionTitle(app.intl.accessKeyFormSectionScope),
            app.dimensions.padding.l.gap(),
            _buildScope(),
            app.dimensions.padding.xl.gap(),
            _buildPermissionsTitle(),
            app.dimensions.padding.l.gap(),
            _allBuckets ? _buildAllLevels() : _buildBucketLevels(),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentity() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AppFormInput(
            controller: _nameController,
            focusNode: _nameFocus,
            autofocus: _editing == null,
            label: app.intl.accessKeyNameLabel,
            hint: app.intl.accessKeyNameHint,
            errorText: _serverErrors[AccessKeyFormField.name],
            showCounter: true,
            maxLength: _nameMaxLength,
            height: _ExpiryField.height,
            validator: _validateName,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => submit(),
            onChange: (_) {
              if (_serverErrors.isEmpty) return;
              setState(() => _serverErrors = const {});
            },
          ),
        ),
        app.dimensions.padding.m.gap(),
        SizedBox(
          width: 230,
          child: _ExpiryField(
            value: _expiry,
            options: [
              for (final option in _Expiry.values)
                if (option != _Expiry.keep || _editing?.expiresAt != null)
                  option,
            ],
            labelOf: _expiryLabel,
            onChanged: (value) => setState(() => _expiry = value),
          ),
        ),
      ],
    );
  }

  String _expiryLabel(_Expiry option) => switch (option) {
    _Expiry.keep => app.intl.accessKeyExpiryKeep(
      app.dateFormatter.m.format(_editing!.expiresAt!),
    ),
    _Expiry.never => app.intl.accessKeyExpiryNever,
    _Expiry.days30 => app.intl.accessKeyExpiry30Days,
    _Expiry.days90 => app.intl.accessKeyExpiry90Days,
    _Expiry.year => app.intl.accessKeyExpiryYear,
  };

  Widget _buildScope() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _OptionCard(
            title: app.intl.accessKeyScopeAll,
            description: app.intl.accessKeyScopeAllDescription,
            selected: _allBuckets,
            onTap: () => setState(() => _allBuckets = true),
          ),
        ),
        app.dimensions.padding.m.gap(),
        Expanded(
          child: _OptionCard(
            title: app.intl.accessKeyScopeSome,
            description: app.intl.accessKeyScopeSomeDescription,
            selected: !_allBuckets,
            onTap: () => setState(() => _allBuckets = false),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionsTitle() {
    final buckets = context.watch<BucketCubit>().state.buckets;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _sectionTitle(app.intl.accessKeyFormSectionPermissions),
        ),
        if (!_allBuckets && buckets.isNotEmpty)
          Text(
            app.intl.accessKeyBucketsChecked(_checked.length, buckets.length),
            style: app.textTheme.bodySmall?.copyWith(
              color: app.colors.neutral.grey3,
            ),
          ),
      ],
    );
  }

  Widget _buildAllLevels() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, level) in AccessKeyLevel.values.indexed) ...[
          if (index > 0) app.dimensions.padding.m.gap(),
          Expanded(
            child: _OptionCard(
              title: level.label,
              description: level.description,
              selected: level == _allLevel,
              onTap: () => setState(() => _allLevel = level),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBucketLevels() {
    return BlocBuilder<BucketCubit, BucketState>(
      builder: (context, state) {
        final buckets = state.buckets;
        if (state is BucketLoadingErrorState && buckets.isEmpty) {
          return _message(
            state.exception.message,
            color: app.colors.primary.error,
            action: TextButton(
              onPressed: context.read<BucketCubit>().load,
              child: Text(app.intl.tryAgain),
            ),
          );
        }
        if (buckets.isEmpty) {
          return state is BucketLoadingSuccessState
              ? _message(app.intl.accessKeyBucketsEmpty)
              : const Center(child: CircularProgressIndicator());
        }
        final divider = BorderSide(
          color: app.colors.neutral.white.withValues(alpha: 0.08),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: app.colors.primary.background2,
                borderRadius: app.dimensions.border.borderRadius.m,
                border: Border.all(
                  color: _submitted && _missingBuckets
                      ? app.colors.primary.error
                      : app.colors.neutral.grey5,
                ),
              ),
              child: Column(
                children: [
                  for (final (index, bucket) in buckets.indexed)
                    Container(
                      decoration: BoxDecoration(
                        border: index == buckets.length - 1
                            ? null
                            : Border(bottom: divider),
                      ),
                      child: _BucketLevelRow(
                        bucket: bucket,
                        checked: _checked.containsKey(bucket.name),
                        level: _levels[bucket.name] ?? AccessKeyLevel.readOnly,
                        onChecked: (checked) => setState(() {
                          if (checked) {
                            _checked[bucket.name] =
                                _levels[bucket.name] ?? AccessKeyLevel.readOnly;
                          } else {
                            _checked.remove(bucket.name);
                          }
                        }),
                        onLevel: (level) => setState(() {
                          _levels[bucket.name] = level;
                          _checked[bucket.name] = level;
                        }),
                      ),
                    ),
                ],
              ),
            ),
            if (_submitted && _missingBuckets) ...[
              app.dimensions.padding.s.gap(),
              Text(
                app.intl.accessKeyBucketsRequired,
                style: app.textTheme.bodySmall?.copyWith(
                  color: app.colors.primary.error,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _message(String text, {Color? color, Widget? action}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(app.dimensions.padding.l),
      decoration: BoxDecoration(
        color: app.colors.primary.background2,
        borderRadius: app.dimensions.border.borderRadius.m,
        border: Border.all(color: app.colors.neutral.grey5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: app.textTheme.bodyMedium?.copyWith(
                color: color ?? app.colors.neutral.grey3,
              ),
            ),
          ),
          ?action,
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: app.textTheme.labelLarge?.copyWith(
        color: app.colors.primary.primaryFaded,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }
}

/// Expiration selector drawn like an [AppFormInput]: bold label on top and a
/// bordered box (hover and focus as in the inputs), with the options in a menu
class _ExpiryField extends StatefulWidget {
  /// The same as the name input next to it
  static const double height = 48;

  final _Expiry value;
  final List<_Expiry> options;
  final String Function(_Expiry) labelOf;
  final ValueChanged<_Expiry> onChanged;

  const _ExpiryField({
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  State<_ExpiryField> createState() => _ExpiryFieldState();
}

class _ExpiryFieldState extends State<_ExpiryField> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final focusColor = app.colors.primary.primaryFaded;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          app.intl.accessKeyExpiryLabel,
          style: app.textTheme.bodyMedium!.copyWith(
            color: app.colors.neutral.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        app.dimensions.padding.s.gap(),
        MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: Focus(
            onFocusChange: (focused) => setState(() => _focused = focused),
            child: Container(
              height: _ExpiryField.height,
              padding: EdgeInsets.only(
                left: app.dimensions.padding.m,
                right: app.dimensions.padding.s,
              ),
              decoration: BoxDecoration(
                color: app.colors.primary.backgroundForm,
                borderRadius: app.dimensions.border.borderRadius.s,
                border: Border.all(
                  color: _focused
                      ? focusColor
                      : _hovered
                      ? app.colors.neutral.grey2
                      : app.colors.neutral.grey3,
                  width: app.dimensions.border.width.s,
                ),
                boxShadow: _focused
                    ? [BoxShadow(color: focusColor, spreadRadius: 1)]
                    : const [],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<_Expiry>(
                  value: widget.value,
                  isExpanded: true,
                  focusColor: app.colors.neutral.transparent,
                  dropdownColor: app.colors.primary.background2,
                  borderRadius: app.dimensions.border.borderRadius.s,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                    color: app.colors.neutral.grey3,
                  ),
                  style: app.textTheme.bodyLarge?.copyWith(
                    color: app.colors.neutral.white,
                  ),
                  items: [
                    for (final option in widget.options)
                      DropdownMenuItem(
                        value: option,
                        child: Text(
                          widget.labelOf(option),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) widget.onChanged(value);
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A bucket with its checkbox and the level selector (dimmed while unchecked)
class _BucketLevelRow extends StatelessWidget {
  final BucketModel bucket;
  final bool checked;
  final AccessKeyLevel level;
  final ValueChanged<bool> onChecked;
  final ValueChanged<AccessKeyLevel> onLevel;

  const _BucketLevelRow({
    required this.bucket,
    required this.checked,
    required this.level,
    required this.onChecked,
    required this.onLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: app.dimensions.padding.m,
        vertical: app.dimensions.padding.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => onChecked(!checked),
              borderRadius: app.dimensions.border.borderRadius.s,
              child: Row(
                children: [
                  Checkbox(
                    value: checked,
                    onChanged: (value) => onChecked(value ?? false),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: bucket.uiColor ?? app.colors.palette.violet,
                      shape: BoxShape.circle,
                    ),
                  ),
                  app.dimensions.padding.m.gap(),
                  Expanded(
                    child: Text(
                      bucket.name,
                      overflow: TextOverflow.ellipsis,
                      style: app.textTheme.bodyMedium?.copyWith(
                        color: checked ? null : app.colors.neutral.grey3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Opacity(
            opacity: checked ? 1 : 0.4,
            child: SegmentedButton<AccessKeyLevel>(
              showSelectedIcon: false,
              segments: [
                for (final option in AccessKeyLevel.values)
                  ButtonSegment(
                    value: option,
                    label: Text(option.shortLabel),
                    tooltip: option.label,
                  ),
              ],
              selected: {level},
              onSelectionChanged: (selection) => onLevel(selection.first),
            ),
          ),
        ],
      ),
    );
  }
}

/// Selectable card: a title and what it means
class _OptionCard extends StatelessWidget {
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

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
                      title,
                      style: app.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              app.dimensions.padding.s.gap(),
              Text(
                description,
                style: app.textTheme.bodySmall?.copyWith(
                  color: app.colors.neutral.grey2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Drawer footer: *Cancel* and *Create key* / *Save changes*
class _AccessKeyFormFooter extends StatelessWidget {
  final bool editing;
  final VoidCallback onSubmit;

  const _AccessKeyFormFooter({required this.editing, required this.onSubmit});

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
          title: editing ? app.intl.bucketEditSave : app.intl.accessKeyCreate,
          h: 40,
          w: 170,
          icon: editing ? null : app.assets.icons.actions.add,
        ),
      ],
    );
  }
}
