import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

/// Details of the selected bucket: header with actions and its tabs
class BucketAdminDetail extends StatelessWidget {
  final BucketModel bucket;
  final BucketAdminTab tab;
  final ValueChanged<BucketAdminTab> onTabChanged;

  const BucketAdminDetail({
    required this.bucket,
    required this.tab,
    required this.onTabChanged,
    super.key,
  });

  void _onDelete(BuildContext context) {
    final cubit = context.read<BucketCubit>();
    ConfirmDialog.show(
      title: app.intl.bucketsDeleteTitle,
      description: app.intl.bucketsDeleteConfirm(bucket.name),
      confirmTitle: app.intl.delete,
      confirmColor: app.colors.primary.errorAction,
      confirmAction: () => cubit.deleteBucket(bucket: bucket),
    );
  }

  void _onEmpty(BuildContext context) {
    final cubit = context.read<BucketCubit>();
    BucketEmptyDialog.show(
      bucket: bucket,
      onConfirm: () => cubit.emptyBucket(bucket: bucket),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        app.dimensions.padding.xl,
        app.dimensions.padding.xl,
        app.dimensions.padding.xl,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          app.dimensions.padding.xl.gap(),
          _BucketAdminTabs(tab: tab, onChanged: onTabChanged),
          app.dimensions.padding.xl.gap(),
          Expanded(
            child: switch (tab) {
              BucketAdminTab.general => BucketGeneralTab(bucket: bucket),
              BucketAdminTab.access => AnonymousAccessTab(bucket: bucket.name),
              BucketAdminTab.danger => BucketDangerTab(
                bucket: bucket,
                onEmpty: () => _onEmpty(context),
                onDelete: () => _onDelete(context),
              ),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(app.dimensions.padding.m),
          decoration: BoxDecoration(
            color:
                bucket.uiColor ??
                Color.lerp(
                  app.colors.primary.purple,
                  app.colors.neutral.white,
                  0.1,
                )!.withValues(alpha: 0.2),
            borderRadius: app.dimensions.border.borderRadius.m,
          ),
          child: app.assets.icons.storage.bucket.build(
            size: 36,
            color: app.colors.neutral.white,
          ),
        ),
        app.dimensions.padding.l.gap(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bucket.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: app.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (bucket.description?.isNotEmpty == true)
                Text(
                  bucket.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: app.textTheme.bodyMedium?.copyWith(
                    color: app.colors.neutral.grey3,
                  ),
                ),
            ],
          ),
        ),
        app.dimensions.padding.l.gap(),
        PrimaryButton.primary(
          title: app.intl.bucketAdminOpenInBrowser,
          icon: app.assets.icons.storage.folder,
          color: app.colors.primary.background3,
          onPressed: () => BrowserScreen.navigator.openBucket(bucket),
          h: 42,
          w: 230,
        ),
        app.dimensions.padding.m.gap(),
        PrimaryButton.primary(
          title: app.intl.edit,
          icon: app.assets.icons.actions.edit,
          onPressed: () => BucketForm.open(context, bucket: bucket),
          h: 42,
          w: 120,
        ),
      ],
    );
  }
}

class _BucketAdminTabs extends StatelessWidget {
  final BucketAdminTab tab;
  final ValueChanged<BucketAdminTab> onChanged;

  const _BucketAdminTabs({required this.tab, required this.onChanged});

  String _label(BucketAdminTab tab) => switch (tab) {
    BucketAdminTab.general => app.intl.bucketAdminTabGeneral,
    BucketAdminTab.access => app.intl.bucketAdminTabAccess,
    BucketAdminTab.danger => app.intl.bucketAdminTabDanger,
  };

  @override
  Widget build(BuildContext context) {
    // the rule counter only shows once they are loaded
    final accessState = context.watch<AnonymousAccessCubit>().state;
    final ruleCount = accessState is AnonymousAccessLoadingSuccessState
        ? accessState.rules.length
        : null;
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: app.colors.neutral.grey5)),
      ),
      child: Row(
        children: [
          for (final item in BucketAdminTab.values)
            _TabButton(
              label: _label(item),
              count: item == BucketAdminTab.access ? ruleCount : null,
              selected: item == tab,
              onTap: () => onChanged(item),
            ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: app.dimensions.padding.l,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                width: 2,
                color: selected
                    ? app.colors.primary.primaryFaded
                    : app.colors.neutral.transparent,
              ),
            ),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: app.textTheme.bodyLarge?.copyWith(
                  color: selected
                      ? app.colors.neutral.white
                      : app.colors.neutral.grey3,
                  fontWeight: selected ? FontWeight.bold : null,
                ),
              ),
              if (count != null) ...[
                app.dimensions.padding.s.gap(),
                Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? app.colors.primary.purple
                        : app.colors.primary.background3,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: app.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 20 / 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
