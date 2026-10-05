import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

/// *Anonymous access* tab of a bucket's details: its rules, add and delete.
/// Needs an [AnonymousAccessCubit] above it
class AnonymousAccessTab extends StatefulWidget {
  final String bucket;

  const AnonymousAccessTab({required this.bucket, super.key});

  @override
  State<AnonymousAccessTab> createState() => _AnonymousAccessTabState();
}

class _AnonymousAccessTabState extends State<AnonymousAccessTab> {
  late final AnonymousAccessCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = context.read<AnonymousAccessCubit>();
    if (cubit.state.bucket != widget.bucket) cubit.load(bucket: widget.bucket);
  }

  @override
  void didUpdateWidget(covariant AnonymousAccessTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bucket != widget.bucket) cubit.load(bucket: widget.bucket);
  }

  void _onDelete(AnonymousRuleModel rule) {
    ConfirmDialog.show(
      title: app.intl.anonymousRuleDeleteTitle,
      description: app.intl.anonymousRuleDeleteConfirm(rule.prefix),
      confirmTitle: app.intl.delete,
      confirmColor: app.colors.primary.errorAction,
      confirmAction: () => cubit.deleteRule(prefix: rule.prefix),
      h: 270,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AnonymousAccessCubit, AnonymousAccessState>(
      listener: (context, state) {
        if (state is AnonymousAccessProcessInProgressState) {
          app.loading.show(id: loadingOverlayGlobalId);
        } else {
          app.loading.hide(id: loadingOverlayGlobalId);
        }
        if (state is AnonymousAccessProcessingErrorState) {
          app.snack.showError(message: state.message, context: context);
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    app.intl.anonymousAccessDescription,
                    style: app.textTheme.bodyMedium?.copyWith(
                      color: app.colors.neutral.grey2,
                    ),
                  ),
                ),
                app.dimensions.padding.l.gap(),
                PrimaryButton.primary(
                  title: app.intl.anonymousRuleAdd,
                  icon: app.assets.icons.actions.add,
                  onPressed: () =>
                      AnonymousRuleForm.open(context, bucket: widget.bucket),
                  h: 42,
                  w: 170,
                ),
              ],
            ),
            app.dimensions.padding.l.gap(),
            Expanded(child: _buildContent(state)),
          ],
        );
      },
    );
  }

  Widget _buildContent(AnonymousAccessState state) {
    if (state is AnonymousAccessLoadingErrorState) {
      return ErrorPage(
        message: state.exception.message,
        onRetry: () => cubit.load(bucket: widget.bucket),
      );
    }
    final loading =
        state is AnonymousAccessInitialState ||
        state is AnonymousAccessLoadingInProgressState;
    return LoadingOverlay(
      visible: loading,
      overlayWidgetBuilder: LoadingOverlayStyles.table,
      disableBackButton: false,
      child: state.rules.isEmpty
          ? (loading ? const SizedBox.expand() : const _PrivateBucketPage())
          : SingleChildScrollView(
              child: _RulesTable(rules: state.rules, onDelete: _onDelete),
            ),
    );
  }
}

class _RulesTable extends StatelessWidget {
  final List<AnonymousRuleModel> rules;
  final ValueChanged<AnonymousRuleModel> onDelete;

  const _RulesTable({required this.rules, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return AppSimpleTable(
      columns: [
        AppTableColumn(app.intl.anonymousRulePrefix, width: 280),
        AppTableColumn(app.intl.anonymousRuleAccess, width: 200),
        AppTableColumn(app.intl.anonymousRuleOps),
        const AppTableColumn.actions(),
      ],
      rows: [
        for (final rule in rules)
          AppTableRow([
            _PrefixChip(prefix: rule.prefix),
            AnonymousAccessBadge(access: rule.access),
            Text(
              rule.access.operations,
              style: app.textTheme.bodyMedium?.copyWith(
                color: app.colors.neutral.grey2,
              ),
            ),
            IconButton(
              tooltip: app.intl.anonymousRuleDeleteTitle,
              onPressed: () => onDelete(rule),
              icon: app.assets.icons.actions.delete.build(
                size: 18,
                color: app.colors.primary.error,
              ),
            ),
          ]),
      ],
      hint: app.intl.anonymousRuleHint,
    );
  }
}

class _PrefixChip extends StatelessWidget {
  final String prefix;

  const _PrefixChip({required this.prefix});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: app.dimensions.padding.s,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: app.colors.primary.background3,
        borderRadius: app.dimensions.border.borderRadius.s,
      ),
      child: Text(
        prefix,
        overflow: TextOverflow.ellipsis,
        style: app.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
      ),
    );
  }
}

/// Colored tag with the access type of a rule
class AnonymousAccessBadge extends StatelessWidget {
  final AnonymousAccessType access;

  const AnonymousAccessBadge({required this.access, super.key});

  @override
  Widget build(BuildContext context) {
    final color = access.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        access.label,
        style: app.textTheme.bodySmall?.copyWith(
          color: Color.lerp(color, app.colors.neutral.white, 0.45),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Empty state: no rules, the whole bucket needs credentials
class _PrivateBucketPage extends StatelessWidget {
  const _PrivateBucketPage();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.all(app.dimensions.padding.xl),
      decoration: BoxDecoration(
        color: app.colors.primary.background2,
        borderRadius: app.dimensions.border.borderRadius.m,
        border: Border.all(color: app.colors.neutral.grey5),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: app.colors.primary.primaryFaded.withValues(alpha: 0.12),
              ),
              child: Icon(
                Icons.lock_outline,
                size: 28,
                color: app.colors.primary.primaryFaded,
              ),
            ),
            app.dimensions.padding.m.gap(),
            Text(
              app.intl.anonymousAccessPrivateTitle,
              style: app.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            app.dimensions.padding.s.gap(),
            Text(
              app.intl.anonymousAccessPrivateDescription,
              textAlign: TextAlign.center,
              style: app.textTheme.bodyMedium?.copyWith(
                color: app.colors.neutral.grey3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension AnonymousAccessTypeView on AnonymousAccessType {
  String get label => switch (this) {
    AnonymousAccessType.readOnly => app.intl.anonymousAccessReadOnly,
    AnonymousAccessType.writeOnly => app.intl.anonymousAccessWriteOnly,
    AnonymousAccessType.readWrite => app.intl.anonymousAccessReadWrite,
  };

  /// What can be done without credentials
  String get operations => switch (this) {
    AnonymousAccessType.readOnly => app.intl.anonymousAccessReadOnlyOps,
    AnonymousAccessType.writeOnly => app.intl.anonymousAccessWriteOnlyOps,
    AnonymousAccessType.readWrite => app.intl.anonymousAccessReadWriteOps,
  };

  Color get color => switch (this) {
    AnonymousAccessType.readOnly => app.colors.palette.blue,
    AnonymousAccessType.writeOnly => app.colors.palette.amber,
    AnonymousAccessType.readWrite => app.colors.primary.primaryFaded,
  };
}
