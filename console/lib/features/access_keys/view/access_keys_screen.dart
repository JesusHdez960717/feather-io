import 'package:console/app_exporter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class AccessKeysScreenNavigator {
  String get name => RouteNames.accessKeys;

  String get path => '/keys';

  Widget builder(BuildContext context, GoRouterState state) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AccessKeyCubit(app.di.find(), app.di.find()),
        ),
        // the create/edit drawer lists the buckets
        BlocProvider(
          create: (context) => BucketCubit(app.di.find(), app.di.find()),
        ),
      ],
      child: const AccessKeysScreen(),
    );
  }
}

/// *Access keys* section: the root key of the env and the managed keys, with
/// search, create, edit, enable/disable, regenerate the secret and delete
class AccessKeysScreen extends StatefulWidget {
  static final AccessKeysScreenNavigator navigator =
      AccessKeysScreenNavigator();

  const AccessKeysScreen({super.key});

  @override
  State<AccessKeysScreen> createState() => _AccessKeysScreenState();
}

class _AccessKeysScreenState extends State<AccessKeysScreen> {
  late final AccessKeyCubit cubit;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    cubit = context.read<AccessKeyCubit>()..load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onRegenerate(AccessKeyModel key) {
    ConfirmDialog.show(
      title: app.intl.accessKeyRegenerateTitle,
      description: app.intl.accessKeyRegenerateConfirm(key.name),
      confirmTitle: app.intl.accessKeyRegenerate,
      confirmColor: app.colors.primary.purple.brighten(0.15),
      confirmAction: () => cubit.regenerateSecret(key),
      h: 270,
    );
  }

  void _onDelete(AccessKeyModel key) {
    ConfirmDialog.show(
      title: app.intl.accessKeyDeleteTitle,
      description: app.intl.accessKeyDeleteConfirm(key.name),
      confirmTitle: app.intl.delete,
      confirmColor: app.colors.primary.errorAction,
      confirmAction: () => cubit.delete(key),
      h: 290,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.build(title: app.intl.navAccessKeys),
      body: BlocConsumer<AccessKeyCubit, AccessKeyState>(
        listener: (context, state) {
          if (state is AccessKeyProcessInProgressState) {
            app.loading.show(id: loadingOverlayGlobalId);
          } else {
            app.loading.hide(id: loadingOverlayGlobalId);
          }
          if (state is AccessKeyProcessingErrorState) {
            app.snack.showError(message: state.message, context: context);
          }
          if (state is AccessKeyProcessingOKState) {
            final name = state.key.name;
            switch (state.action) {
              case AccessKeyAction.secretRegenerated:
                AccessKeySecretDialog.show(
                  key: state.key,
                  cubit: cubit,
                  created: false,
                );
              case AccessKeyAction.enabled:
                app.snack.showSuccess(
                  message: app.intl.accessKeyEnabledSuccess(name),
                  context: context,
                );
              case AccessKeyAction.disabled:
                app.snack.showSuccess(
                  message: app.intl.accessKeyDisabledSuccess(name),
                  context: context,
                );
              case AccessKeyAction.deleted:
                app.snack.showSuccess(
                  message: app.intl.accessKeyDeletedSuccess(name),
                  context: context,
                );
            }
          }
        },
        builder: (context, state) {
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: app.dimensions.padding.xl,
              vertical: app.dimensions.padding.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                app.dimensions.padding.l.gap(),
                Expanded(child: _buildContent(state)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                app.intl.accessKeysDescription,
                style: app.textTheme.bodyMedium?.copyWith(
                  color: app.colors.neutral.grey2,
                ),
              ),
              Text(
                app.intl.accessKeysSecretOnce,
                style: app.textTheme.bodySmall?.copyWith(
                  color: app.colors.neutral.grey3,
                ),
              ),
            ],
          ),
        ),
        app.dimensions.padding.l.gap(),
        SizedBox(
          width: 260,
          child: AppTextSearchField(
            controller: _searchController,
            // filters the keys already loaded: no wait
            delay: 0,
            onSearch: cubit.search,
            hint: app.intl.accessKeysSearchHint,
          ),
        ),
        app.dimensions.padding.l.gap(),
        PrimaryButton.primary(
          title: app.intl.accessKeyCreate,
          icon: app.assets.icons.actions.add,
          onPressed: () => AccessKeyForm.open(context),
          h: 42,
          w: 160,
        ),
      ],
    );
  }

  Widget _buildContent(AccessKeyState state) {
    final data = state.data;
    if (state is AccessKeyLoadingErrorState && !data.loaded) {
      return ErrorPage(message: state.exception.message, onRetry: cubit.load);
    }
    return LoadingOverlay(
      visible: !data.loaded,
      overlayWidgetBuilder: LoadingOverlayStyles.table,
      disableBackButton: false,
      child: data.loaded
          ? SingleChildScrollView(
              child: _AccessKeysTable(
                data: data,
                onEdit: (key) => AccessKeyForm.open(context, key: key),
                onRegenerate: _onRegenerate,
                onToggle: (key) => cubit.setEnabled(key, enabled: !key.enabled),
                onDelete: _onDelete,
                onCreate: () => AccessKeyForm.open(context),
              ),
            )
          : const SizedBox.expand(),
    );
  }
}

class _AccessKeysTable extends StatelessWidget {
  static const double _nameWidth = 250;
  static const double _idWidth = 270;
  static const double _lastUsedWidth = 130;
  static const double _statusWidth = 185;
  static const double _actionsWidth = 56;

  final AccessKeyData data;
  final ValueChanged<AccessKeyModel> onEdit;
  final ValueChanged<AccessKeyModel> onRegenerate;
  final ValueChanged<AccessKeyModel> onToggle;
  final ValueChanged<AccessKeyModel> onDelete;
  final VoidCallback onCreate;

  const _AccessKeysTable({
    required this.data,
    required this.onEdit,
    required this.onRegenerate,
    required this.onToggle,
    required this.onDelete,
    required this.onCreate,
  });

  BorderSide get _divider =>
      BorderSide(color: app.colors.neutral.white.withValues(alpha: 0.08));

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: app.colors.primary.background2,
        borderRadius: app.dimensions.border.borderRadius.m,
        border: Border.all(color: app.colors.neutral.grey5),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildRootRow(),
          if (data.keys.isEmpty)
            _EmptyKeys(onCreate: onCreate)
          else if (data.visibleKeys.isEmpty)
            Padding(
              padding: EdgeInsets.all(app.dimensions.padding.xl),
              child: Text(
                app.intl.accessKeysNoMatch,
                style: app.textTheme.bodyMedium?.copyWith(
                  color: app.colors.neutral.grey3,
                ),
              ),
            )
          else
            for (final key in data.visibleKeys) _buildKeyRow(context, key),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    Widget header(String text, double? width) => _cell(
      Text(
        text,
        style: app.textTheme.bodyMedium?.copyWith(
          color: app.colors.neutral.grey3,
        ),
      ),
      width,
    );
    return Container(
      height: 42,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: app.colors.neutral.white.withValues(alpha: 0.16),
          ),
        ),
      ),
      child: Row(
        children: [
          header(app.intl.accessKeyColumnName, _nameWidth),
          header(app.intl.accessKeyColumnId, _idWidth),
          Expanded(child: header(app.intl.accessKeyColumnPermissions, null)),
          header(app.intl.accessKeyColumnLastUsed, _lastUsedWidth),
          header(app.intl.accessKeyColumnStatus, _statusWidth),
          const SizedBox(width: _actionsWidth),
        ],
      ),
    );
  }

  Widget _buildRootRow() {
    return _row(
      name: Row(
        children: [
          Text(
            app.intl.accessKeyRootName,
            style: app.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          app.dimensions.padding.s.gap(),
          AccessKeyPill(
            text: app.intl.accessKeyRootBadge,
            background: app.colors.primary.purple,
            foreground: app.colors.neutral.white,
          ),
        ],
      ),
      id: _KeyId(id: data.rootAccessKeyId ?? ''),
      permissions: Text(
        app.intl.accessKeyRootPermissions,
        style: app.textTheme.bodyMedium?.copyWith(
          color: app.colors.neutral.grey2,
        ),
      ),
      lastUsed: Text(
        '—',
        style: app.textTheme.bodyMedium?.copyWith(
          color: app.colors.neutral.grey3,
        ),
      ),
      status: const AccessKeyStatusBadge(status: AccessKeyStatus.active),
      actions: Tooltip(
        message: app.intl.accessKeyRootLocked,
        child: app.assets.icons.actions.lock.build(
          size: 18,
          color: app.colors.neutral.grey4,
        ),
      ),
    );
  }

  Widget _buildKeyRow(BuildContext context, AccessKeyModel key) {
    final dimmed = key.status != AccessKeyStatus.active;
    return _row(
      name: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            key.name,
            overflow: TextOverflow.ellipsis,
            style: app.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: dimmed ? app.colors.neutral.grey3 : null,
            ),
          ),
          Text(
            app.intl.accessKeyCreatedOn(
              app.dateFormatter.m.format(key.createdAt),
            ),
            style: app.textTheme.bodySmall?.copyWith(
              color: app.colors.neutral.grey3,
            ),
          ),
        ],
      ),
      id: _KeyId(id: key.id, dimmed: dimmed),
      permissions: AccessKeyPermissions(keyModel: key),
      lastUsed: Text(
        key.lastUsedLabel,
        style: app.textTheme.bodyMedium?.copyWith(
          color: app.colors.neutral.grey2,
        ),
      ),
      status: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AccessKeyStatusBadge(status: key.status),
          if (key.expiresAt != null)
            Text(
              key.expired
                  ? app.intl.accessKeyExpiredOn(
                      app.dateFormatter.m.format(key.expiresAt!),
                    )
                  : app.intl.accessKeyExpiresOn(
                      app.dateFormatter.m.format(key.expiresAt!),
                    ),
              style: app.textTheme.bodySmall?.copyWith(
                color: app.colors.neutral.grey3,
              ),
            ),
        ],
      ),
      actions: _KeyMenu(
        keyModel: key,
        onEdit: () => onEdit(key),
        onRegenerate: () => onRegenerate(key),
        onToggle: () => onToggle(key),
        onDelete: () => onDelete(key),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: EdgeInsets.all(app.dimensions.padding.l),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 14, color: app.colors.neutral.grey3),
          app.dimensions.padding.s.gap(),
          Expanded(
            child: Text(
              app.intl.accessKeysFooterHint,
              style: app.textTheme.bodySmall?.copyWith(
                color: app.colors.neutral.grey3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row({
    required Widget name,
    required Widget id,
    required Widget permissions,
    required Widget lastUsed,
    required Widget status,
    required Widget actions,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: EdgeInsets.symmetric(vertical: app.dimensions.padding.s),
      decoration: BoxDecoration(border: Border(bottom: _divider)),
      child: Row(
        children: [
          _cell(name, _nameWidth),
          _cell(id, _idWidth),
          Expanded(child: _cell(permissions, null)),
          _cell(lastUsed, _lastUsedWidth),
          _cell(status, _statusWidth),
          SizedBox(
            width: _actionsWidth,
            child: Center(child: actions),
          ),
        ],
      ),
    );
  }

  Widget _cell(Widget child, double? width) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: app.dimensions.padding.l),
        child: Align(alignment: Alignment.centerLeft, child: child),
      ),
    );
  }
}

/// Access key id in monospace, with a button to copy it
class _KeyId extends StatelessWidget {
  final String id;
  final bool dimmed;

  const _KeyId({required this.id, this.dimmed = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: app.dimensions.padding.s,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: app.colors.primary.background3,
              borderRadius: app.dimensions.border.borderRadius.s,
            ),
            child: Text(
              id,
              overflow: TextOverflow.ellipsis,
              style: app.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: dimmed ? app.colors.neutral.grey3 : null,
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: app.intl.accessKeyCopyId,
          iconSize: 16,
          onPressed: () {
            Clipboard.setData(ClipboardData(text: id));
            app.snack.showSuccess(
              message: app.intl.accessKeyIdCopied,
              context: context,
            );
          },
          icon: app.assets.icons.actions.copy.build(
            size: 16,
            color: app.colors.neutral.grey3,
          ),
        ),
      ],
    );
  }
}

/// Row menu: edit, regenerate the secret, enable/disable and delete
class _KeyMenu extends StatelessWidget {
  final AccessKeyModel keyModel;
  final VoidCallback onEdit;
  final VoidCallback onRegenerate;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _KeyMenu({
    required this.keyModel,
    required this.onEdit,
    required this.onRegenerate,
    required this.onToggle,
    required this.onDelete,
  });

  PopupMenuItem<void> _item({
    required Widget icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return PopupMenuItem(
      onTap: onTap,
      child: Row(
        children: [
          icon,
          app.dimensions.padding.m.gap(),
          Text(
            title,
            style: app.textTheme.bodyMedium?.copyWith(
              color: color ?? app.colors.neutral.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final white = app.colors.neutral.white;
    return PopupMenuButton<void>(
      tooltip: app.intl.accessKeyActions(keyModel.name),
      color: app.colors.primary.background2,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: app.dimensions.border.borderRadius.s,
        side: BorderSide(color: app.colors.neutral.grey5),
      ),
      icon: app.assets.icons.actions.more.build(
        size: 18,
        color: app.colors.neutral.grey2,
      ),
      itemBuilder: (context) => [
        _item(
          icon: app.assets.icons.actions.edit.build(size: 18, color: white),
          title: app.intl.accessKeyEditPermissions,
          onTap: onEdit,
        ),
        _item(
          icon: app.assets.icons.actions.refresh.build(size: 18, color: white),
          title: app.intl.accessKeyRegenerateSecret,
          onTap: onRegenerate,
        ),
        _item(
          icon: Icon(
            keyModel.enabled
                ? Icons.pause_circle_outline
                : Icons.play_circle_outline,
            size: 18,
            color: white,
          ),
          title: keyModel.enabled
              ? app.intl.accessKeyDisable
              : app.intl.accessKeyEnable,
          onTap: onToggle,
        ),
        const PopupMenuDivider(),
        _item(
          icon: app.assets.icons.actions.delete.build(
            size: 18,
            color: app.colors.primary.error,
          ),
          title: app.intl.delete,
          color: app.colors.primary.error,
          onTap: onDelete,
        ),
      ],
    );
  }
}

/// Empty state inside the table: only the root key exists
class _EmptyKeys extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyKeys({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: app.dimensions.padding.xxl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: app.colors.primary.primaryFaded.withValues(
                    alpha: 0.12,
                  ),
                ),
                child: app.assets.icons.actions.key.build(
                  size: 28,
                  color: app.colors.primary.primaryFaded,
                ),
              ),
              app.dimensions.padding.m.gap(),
              Text(
                app.intl.accessKeysEmptyTitle,
                style: app.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              app.dimensions.padding.s.gap(),
              Text(
                app.intl.accessKeysEmptyDescription,
                textAlign: TextAlign.center,
                style: app.textTheme.bodyMedium?.copyWith(
                  color: app.colors.neutral.grey3,
                ),
              ),
              app.dimensions.padding.l.gap(),
              PrimaryButton.primary(
                title: app.intl.accessKeysCreateFirst,
                icon: app.assets.icons.actions.add,
                onPressed: onCreate,
                h: 42,
                w: 230,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
