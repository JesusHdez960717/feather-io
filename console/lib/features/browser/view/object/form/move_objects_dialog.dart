import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

///Dialogo para mover uno o varios objetos: se elige el bucket y se navega
///hasta la carpeta de destino. *Mover aqui* se desactiva en la carpeta de origen
class MoveObjectsDialog extends StatefulWidget {
  static void show({
    required String bucket,
    required String prefix,
    required List<String> keys,
    required List<String> buckets,
  }) {
    DialogTemplate.open(
      title: app.intl.objectsMoveTitle(keys.length),
      w: 560,
      h: 620,
      child: MoveObjectsDialog._(
        bucket: bucket,
        prefix: prefix,
        keys: keys,
        buckets: buckets,
      ),
    );
  }

  ///Bucket y carpeta de origen
  final String bucket;
  final String prefix;
  final List<String> keys;

  ///Buckets a los que se puede mover
  final List<String> buckets;

  const MoveObjectsDialog._({
    required this.bucket,
    required this.prefix,
    required this.keys,
    required this.buckets,
  });

  @override
  State<MoveObjectsDialog> createState() => _MoveObjectsDialogState();
}

class _MoveObjectsDialogState extends State<MoveObjectsDialog> {
  late final MoveTargetCubit targetCubit = MoveTargetCubit(
    app.di.find(),
    app.di.find(),
  );
  late final ObjectActionCubit actionCubit = ObjectActionCubit(
    app.di.find(),
    app.di.find(),
  );

  @override
  void initState() {
    super.initState();
    targetCubit.open(bucket: widget.bucket, prefix: widget.prefix);
  }

  @override
  void dispose() {
    targetCubit.close();
    actionCubit.close();
    super.dispose();
  }

  String _names() {
    final names = widget.keys.map((k) => k.split('/').last).toList();
    return names.length <= 3
        ? names.join(', ')
        : '${names.take(3).join(', ')}…';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ObjectActionCubit, ObjectActionState>(
      bloc: actionCubit,
      listener: (context, state) {
        if (state is ObjectActionProcessingOKState) {
          app.navigator.pop();
          app.snack.showSuccess(
            message: app.intl.objectsMoved(widget.keys.length),
            context: app.context,
          );
        }
      },
      builder: (context, actionState) {
        return BlocBuilder<MoveTargetCubit, MoveTargetState>(
          bloc: targetCubit,
          builder: (context, target) {
            final targetBucket = target.bucket ?? widget.bucket;
            final isSource =
                targetBucket == widget.bucket && target.prefix == widget.prefix;
            return LoadingOverlay(
              visible: actionState is ObjectActionProcessInProgressState,
              overlayWidgetBuilder: LoadingOverlayStyles.form,
              disableBackButton: false,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: app.dimensions.padding.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _names(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: app.textTheme.bodyMedium?.copyWith(
                        color: app.colors.neutral.grey3,
                      ),
                    ),
                    if (actionState is ObjectActionProcessingErrorState) ...[
                      app.dimensions.padding.m.gap(),
                      AppFormAlert(
                        title: app.intl.objectsActionErrorTitle,
                        message: actionState.exception.message,
                      ),
                    ],
                    app.dimensions.padding.l.gap(),
                    _label(app.intl.objectsMoveBucket),
                    app.dimensions.padding.s.gap(),
                    _buildBucketSelector(targetBucket),
                    app.dimensions.padding.l.gap(),
                    _label(app.intl.objectsMoveFolder),
                    app.dimensions.padding.s.gap(),
                    _buildBreadcrumbs(targetBucket, target.prefix),
                    app.dimensions.padding.s.gap(),
                    Expanded(child: _buildFolders(target, targetBucket)),
                    app.dimensions.padding.m.gap(),
                    Text(
                      isSource
                          ? app.intl.objectsMoveSameFolder
                          : app.intl.objectsMoveHelper(
                              '/$targetBucket/${target.prefix}',
                            ),
                      style: app.textTheme.bodySmall?.copyWith(
                        color: isSource
                            ? app.colors.primary.secondary
                            : app.colors.neutral.grey3,
                      ),
                    ),
                    app.dimensions.padding.l.gap(),
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
                            onPressed:
                                isSource ||
                                    target is! MoveTargetLoadingSuccessState
                                ? null
                                : () => actionCubit.move(
                                    bucket: widget.bucket,
                                    keys: widget.keys,
                                    targetBucket: targetBucket,
                                    targetPrefix: target.prefix,
                                  ),
                            title: app.intl.objectsMoveHere,
                          ),
                        ),
                      ],
                    ),
                    app.dimensions.padding.xl.gap(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: app.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildBucketSelector(String targetBucket) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: app.dimensions.padding.m),
      decoration: BoxDecoration(
        color: app.colors.primary.background1,
        borderRadius: app.dimensions.border.borderRadius.s,
        border: Border.all(color: app.colors.neutral.grey3),
      ),
      child: DropdownButton<String>(
        value: targetBucket,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        dropdownColor: app.colors.primary.background2,
        style: app.textTheme.bodyLarge,
        onChanged: (bucket) {
          if (bucket != null) targetCubit.open(bucket: bucket, prefix: '');
        },
        items: [
          for (final bucket in widget.buckets)
            DropdownMenuItem(value: bucket, child: Text(bucket)),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs(String bucket, String prefix) {
    final parts = prefix.split('/').where((s) => s.isNotEmpty).toList();
    Widget crumb(String label, String target, {required bool current}) {
      return InkWell(
        onTap: current
            ? null
            : () => targetCubit.open(bucket: bucket, prefix: target),
        borderRadius: app.dimensions.border.borderRadius.s,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: app.colors.primary.background2,
            borderRadius: app.dimensions.border.borderRadius.s,
          ),
          child: Text(
            label,
            style: app.textTheme.bodyMedium?.copyWith(
              fontWeight: current ? null : FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: app.colors.primary.background3,
        borderRadius: app.dimensions.border.borderRadius.s,
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Center(child: crumb(bucket, '', current: parts.isEmpty)),
          for (var i = 0; i < parts.length; i++) ...[
            Center(
              child: app.assets.icons.navigation.next.build(
                size: 14,
                color: app.colors.neutral.grey3,
              ),
            ),
            Center(
              child: crumb(
                parts[i],
                '${parts.take(i + 1).join('/')}/',
                current: i == parts.length - 1,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFolders(MoveTargetState target, String bucket) {
    Widget body;
    if (target is MoveTargetLoadingErrorState) {
      body = Center(
        child: Text(
          target.exception.message,
          textAlign: TextAlign.center,
          style: app.textTheme.bodyMedium?.copyWith(
            color: app.colors.primary.error,
          ),
        ),
      );
    } else if (target.folders.isEmpty &&
        target is MoveTargetLoadingSuccessState) {
      body = Center(
        child: Text(
          app.intl.objectsMoveNoFolders,
          style: app.textTheme.bodyMedium?.copyWith(
            color: app.colors.neutral.grey3,
          ),
        ),
      );
    } else {
      body = ListView(
        children: [
          for (final folder in target.folders)
            InkWell(
              onTap: () => targetCubit.open(bucket: bucket, prefix: folder),
              child: Container(
                height: 44,
                padding: EdgeInsets.symmetric(
                  horizontal: app.dimensions.padding.m,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: app.colors.neutral.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    app.assets.icons.storage.folder.build(
                      size: 18,
                      color: app.colors.neutral.grey2,
                    ),
                    app.dimensions.padding.m.gap(),
                    Expanded(
                      child: Text(
                        folder.substring(0, folder.length - 1).split('/').last,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    app.assets.icons.navigation.next.build(
                      size: 18,
                      color: app.colors.neutral.grey3,
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: app.colors.primary.background2,
        borderRadius: app.dimensions.border.borderRadius.s,
        border: Border.all(color: app.colors.neutral.grey5),
      ),
      child: LoadingOverlay(
        visible: target is MoveTargetLoadingInProgressState,
        overlayWidgetBuilder: LoadingOverlayStyles.table,
        disableBackButton: false,
        child: body,
      ),
    );
  }
}
