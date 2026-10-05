import 'package:console/app_exporter.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Shows the id and the secret of a key that was just created (or whose
/// secret was regenerated). It is the only time the secret can be seen, so the
/// dialog doesn't close by tapping outside or with Esc, and *Close* only works
/// after checking that the secret was saved
class AccessKeySecretDialog extends StatefulWidget {
  static void show({
    required AccessKeyModel key,
    required AccessKeyCubit cubit,
    required bool created,
  }) {
    app.dialog.open(
      barrierDismissible: false,
      dialog: AccessKeySecretDialog._(
        keyModel: key,
        cubit: cubit,
        created: created,
      ),
    );
  }

  final AccessKeyModel keyModel;
  final AccessKeyCubit cubit;
  final bool created;

  const AccessKeySecretDialog._({
    required this.keyModel,
    required this.cubit,
    required this.created,
  });

  @override
  State<AccessKeySecretDialog> createState() => _AccessKeySecretDialogState();
}

class _AccessKeySecretDialogState extends State<AccessKeySecretDialog> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final key = widget.keyModel;
    return PopScope(
      canPop: _saved,
      child: Dialog(
        elevation: 50,
        backgroundColor: app.colors.primary.backgroundForm,
        shape: RoundedRectangleBorder(
          borderRadius: app.dimensions.border.borderRadius.s,
        ),
        child: SizedBox(
          width: 600,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              app.dimensions.padding.xl,
              app.dimensions.padding.l,
              app.dimensions.padding.xl,
              app.dimensions.padding.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Text(
                    widget.created
                        ? app.intl.accessKeySecretCreatedTitle(key.name)
                        : app.intl.accessKeySecretRegeneratedTitle(key.name),
                    style: app.textTheme.titleMedium,
                  ),
                ),
                app.dimensions.padding.l.gap(),
                _buildWarning(),
                app.dimensions.padding.l.gap(),
                _CopyField(
                  label: app.intl.accessKeyColumnId,
                  value: key.id,
                  copyTooltip: app.intl.accessKeyCopyId,
                  copiedMessage: app.intl.accessKeyIdCopied,
                ),
                app.dimensions.padding.l.gap(),
                _CopyField(
                  label: app.intl.accessKeySecretLabel,
                  value: key.secret ?? '',
                  copyTooltip: app.intl.accessKeyCopySecret,
                  copiedMessage: app.intl.accessKeySecretCopied,
                  highlighted: true,
                ),
                app.dimensions.padding.l.gap(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => widget.cubit.saveCredentials(key),
                    icon: app.assets.icons.actions.download.build(
                      size: 16,
                      color: app.colors.neutral.grey2,
                    ),
                    label: Text(app.intl.accessKeyDownloadCsv),
                  ),
                ),
                app.dimensions.padding.m.gap(),
                CheckboxListTile(
                  value: _saved,
                  onChanged: (value) => setState(() => _saved = value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    app.intl.accessKeySecretSaved,
                    style: app.textTheme.bodyMedium,
                  ),
                ),
                app.dimensions.padding.m.gap(),
                PrimaryButton.primary(
                  onPressed: _saved ? () => Navigator.of(context).pop() : null,
                  title: app.intl.close,
                  color: app.colors.primary.background3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWarning() {
    final amber = app.colors.primary.secondary;
    return Container(
      padding: EdgeInsets.all(app.dimensions.padding.m),
      decoration: BoxDecoration(
        color: amber.withValues(alpha: 0.08),
        borderRadius: app.dimensions.border.borderRadius.s,
        border: Border.all(color: amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 18, color: amber),
          app.dimensions.padding.s.gap(),
          Expanded(
            child: Text(
              app.intl.accessKeySecretWarning,
              style: app.textTheme.bodyMedium?.copyWith(
                color: Color.lerp(amber, app.colors.neutral.white, 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A label and a monospace value with a button to copy it
class _CopyField extends StatelessWidget {
  final String label;
  final String value;
  final String copyTooltip;
  final String copiedMessage;
  final bool highlighted;

  const _CopyField({
    required this.label,
    required this.value,
    required this.copyTooltip,
    required this.copiedMessage,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: app.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        app.dimensions.padding.xs.gap(),
        Container(
          height: 48,
          padding: EdgeInsets.only(left: app.dimensions.padding.m),
          decoration: BoxDecoration(
            color: app.colors.primary.background1,
            borderRadius: app.dimensions.border.borderRadius.s,
            border: Border.all(
              color: highlighted
                  ? app.colors.primary.primaryFaded
                  : app.colors.neutral.grey5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: app.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              IconButton(
                tooltip: copyTooltip,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  app.snack.showSuccess(
                    message: copiedMessage,
                    context: context,
                  );
                },
                icon: app.assets.icons.actions.copy.build(
                  size: 18,
                  color: app.colors.neutral.grey2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
