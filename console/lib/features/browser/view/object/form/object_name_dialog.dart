import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

/// Dialog with a name: create a folder or rename an object. It validates the
/// name on the client (empty, characters, repeated in the folder) and runs the
/// action with its own [ObjectActionCubit]
class ObjectNameDialog extends StatefulWidget {
  /// Creates a folder in [prefix] of [bucket]
  static void createFolder({
    required String bucket,
    required String prefix,
    required Set<String> existingNames,
  }) {
    DialogTemplate.open(
      title: app.intl.objectsNewFolder,
      w: 460,
      h: 330,
      child: ObjectNameDialog._(
        label: app.intl.objectsFolderNameLabel,
        hint: app.intl.objectsFolderNameHint,
        action: app.intl.objectsNewFolderCreate,
        existingNames: existingNames,
        existsMessage: app.intl.objectsFolderExists,
        helper: (name) => app.intl.objectsFolderPathHelper(
          '/$bucket/$prefix${name.isEmpty ? app.intl.objectsFolderNameHint : name}/',
        ),
        success: (name) => app.intl.objectsFolderCreated(name),
        onSubmit: (cubit, name) =>
            cubit.createFolder(bucket: bucket, prefix: prefix, name: name),
      ),
    );
  }

  /// Renames the object [key] of [bucket] inside its folder
  static void rename({
    required String bucket,
    required String key,
    required Set<String> existingNames,
  }) {
    final folder = key.substring(0, key.lastIndexOf('/') + 1);
    final name = key.substring(folder.length);
    DialogTemplate.open(
      title: app.intl.objectsRename,
      w: 520,
      h: 330,
      child: ObjectNameDialog._(
        label: app.intl.objectsRenameLabel,
        initialValue: name,
        action: app.intl.objectsRename,
        existingNames: existingNames,
        existsMessage: app.intl.objectsNameExists,
        helper: (value) =>
            app.intl.objectsRenamePathHelper('/$bucket/$folder$value'),
        success: (value) => app.intl.objectsRenamed(value),
        onSubmit: (cubit, value) =>
            cubit.rename(bucket: bucket, key: key, newName: value),
      ),
    );
  }

  final String label;
  final String? hint;
  final String? initialValue;
  final String action;
  final Set<String> existingNames;
  final String existsMessage;
  final String Function(String name) helper;
  final String Function(String name) success;
  final void Function(ObjectActionCubit cubit, String name) onSubmit;

  const ObjectNameDialog._({
    required this.label,
    required this.action,
    required this.existingNames,
    required this.existsMessage,
    required this.helper,
    required this.success,
    required this.onSubmit,
    this.hint,
    this.initialValue,
  });

  @override
  State<ObjectNameDialog> createState() => _ObjectNameDialogState();
}

class _ObjectNameDialogState extends State<ObjectNameDialog> {
  late final ObjectActionCubit cubit = ObjectActionCubit(
    app.di.find(),
    app.di.find(),
  );
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );
  final _focus = FocusNode();

  /// After the first submit attempt it validates on every change
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    // when renaming, the name without the extension is selected
    final value = widget.initialValue;
    if (value != null) {
      final dot = value.lastIndexOf('.');
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: dot > 0 ? dot : value.length,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    cubit.close();
    super.dispose();
  }

  String get _name => _controller.text.trim();

  String? get _error {
    final error = ObjectName.validate(
      _name,
      existing: widget.existingNames,
      current: widget.initialValue,
    );
    return switch (error) {
      null => null,
      ObjectNameError.empty => app.intl.objectsNameRequired,
      ObjectNameError.invalid => app.intl.objectsNameInvalid,
      ObjectNameError.exists => widget.existsMessage,
      ObjectNameError.unchanged => app.intl.objectsNameUnchanged,
    };
  }

  void _submit() {
    if (cubit.state is ObjectActionProcessInProgressState) return;
    setState(() => _submitted = true);
    if (_error != null) {
      _focus.requestFocus();
      return;
    }
    widget.onSubmit(cubit, _name);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ObjectActionCubit, ObjectActionState>(
      bloc: cubit,
      listener: (context, state) {
        if (state is ObjectActionProcessingOKState) {
          app.navigator.pop();
          app.snack.showSuccess(
            message: widget.success(_name),
            context: app.context,
          );
        }
      },
      builder: (context, state) {
        return LoadingOverlay(
          visible: state is ObjectActionProcessInProgressState,
          overlayWidgetBuilder: LoadingOverlayStyles.form,
          disableBackButton: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: app.dimensions.padding.xl,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state is ObjectActionProcessingErrorState) ...[
                  AppFormAlert(
                    title: app.intl.objectsActionErrorTitle,
                    message: state.exception.message,
                  ),
                  app.dimensions.padding.l.gap(),
                ],
                AppFormInput(
                  controller: _controller,
                  focusNode: _focus,
                  autofocus: true,
                  label: widget.label,
                  hint: widget.hint,
                  helperText: widget.helper(_name),
                  errorText: _submitted ? _error : null,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
                app.dimensions.padding.xl.gap(),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton.primary(
                        onPressed: () => app.navigator.pop(),
                        title: app.intl.cancel,
                        color: app.colors.primary.background3,
                      ),
                    ),
                    app.dimensions.padding.l.gap(),
                    Expanded(
                      child: PrimaryButton.primary(
                        onPressed: _submit,
                        title: widget.action,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
