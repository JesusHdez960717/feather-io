import 'dart:math';

import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

/// Floating panel with the transfer queue, anchored to the right of the
/// [TransfersIndicator]: progress of each upload or download, cancel, retry
/// and remove
class TransfersPanel extends StatelessWidget {
  static const double width = 420;

  /// Opens it next to the [anchor] widget, aligned with its bottom edge
  static void show(BuildContext anchor) {
    final box = anchor.findRenderObject() as RenderBox;
    final topLeft = box.localToGlobal(Offset.zero);
    final screen = MediaQuery.sizeOf(anchor);
    final gap = app.dimensions.padding.l;
    showGeneralDialog(
      context: anchor,
      barrierDismissible: true,
      barrierLabel: app.intl.close,
      barrierColor: app.colors.neutral.transparent,
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Stack(
          children: [
            Positioned(
              left: topLeft.dx + box.size.width + gap,
              bottom: max(gap, screen.height - topLeft.dy - box.size.height),
              child: const TransfersPanel._(),
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  /// Summary of the queue status, or null if it is empty
  static String? summary(TransferState state) => switch (state) {
    TransferProcessInProgressState(:final activeCount) =>
      app.intl.transfersActive(activeCount),
    TransferProcessingOKState(:final failedCount) when failedCount > 0 =>
      app.intl.transfersFailed(failedCount),
    TransferProcessingOKState() => app.intl.transfersAllDone,
    _ => null,
  };

  const TransfersPanel._();

  @override
  Widget build(BuildContext context) {
    final cubit = app.di.find<TransferCubit>();
    return Material(
      color: app.colors.primary.background2,
      elevation: 8,
      shadowColor: app.colors.neutral.black,
      shape: RoundedRectangleBorder(
        borderRadius: app.dimensions.border.borderRadius.m,
        side: BorderSide(color: app.colors.neutral.grey5),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: width,
        child: BlocBuilder<TransferCubit, TransferState>(
          bloc: cubit,
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(state, cubit),
                Divider(height: 1, color: app.colors.neutral.grey5),
                if (state.tasks.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(app.dimensions.padding.xxl),
                    child: Text(
                      app.intl.transfersEmpty,
                      textAlign: TextAlign.center,
                      style: app.textTheme.bodyMedium?.copyWith(
                        color: app.colors.neutral.grey3,
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 380),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.symmetric(
                        vertical: app.dimensions.padding.xs,
                      ),
                      itemCount: state.tasks.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        indent: app.dimensions.padding.l,
                        endIndent: app.dimensions.padding.l,
                        color: app.colors.neutral.grey5.withValues(alpha: 0.5),
                      ),
                      itemBuilder: (context, index) =>
                          _TransferRow(task: state.tasks[index], cubit: cubit),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(TransferState state, TransferCubit cubit) {
    final text = summary(state);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        app.dimensions.padding.l,
        app.dimensions.padding.m,
        app.dimensions.padding.xs,
        app.dimensions.padding.m,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.intl.transfersTitle,
                  style: app.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (text != null)
                  Text(
                    text,
                    style: app.textTheme.bodySmall?.copyWith(
                      color: app.colors.neutral.grey3,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: state.finishedCount > 0 ? cubit.clearFinished : null,
            child: Text(app.intl.transfersClearFinished),
          ),
          IconButton(
            tooltip: app.intl.close,
            onPressed: () => app.navigator.pop(),
            icon: app.assets.icons.actions.close.build(
              size: 18,
              color: app.colors.neutral.grey3,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransferRow extends StatelessWidget {
  final TransferTask task;
  final TransferCubit cubit;

  const _TransferRow({required this.task, required this.cubit});

  (String, Color) get _status {
    final size = app.storageFormatter.formatSize(task.size);
    return switch (task.status) {
      TransferStatus.queued => (
        app.intl.transferStatusQueued,
        app.colors.neutral.grey3,
      ),
      // a download without a size yet: the service is building the zip
      TransferStatus.running when !task.isUpload && task.size == 0 => (
        app.intl.transferStatusPreparing,
        app.colors.neutral.grey3,
      ),
      TransferStatus.running => (
        app.intl.transferStatusProgress(
          app.storageFormatter.formatSize(task.transferred),
          size,
          (task.progress * 100).floor(),
        ),
        app.colors.neutral.grey3,
      ),
      TransferStatus.done => (
        task.isUpload
            ? app.intl.transferStatusUploaded(size)
            : app.intl.transferStatusDownloaded(size),
        app.colors.primary.green,
      ),
      TransferStatus.failed => (
        app.intl.transferStatusFailed(task.error?.message ?? ''),
        app.colors.primary.error,
      ),
      TransferStatus.cancelled => (
        app.intl.transferStatusCancelled,
        app.colors.neutral.grey4,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (status, color) = _status;
    final running = task.status == TransferStatus.running;
    final retryable =
        task.status == TransferStatus.failed ||
        task.status == TransferStatus.cancelled;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        app.dimensions.padding.l,
        app.dimensions.padding.s,
        app.dimensions.padding.xs,
        app.dimensions.padding.s,
      ),
      child: Row(
        children: [
          Tooltip(
            message: task.isUpload
                ? app.intl.transferUpload
                : app.intl.transferDownload,
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: app.colors.primary.background3,
                borderRadius: app.dimensions.border.borderRadius.s,
              ),
              child:
                  (task.isUpload
                          ? app.assets.icons.actions.upload
                          : app.assets.icons.actions.download)
                      .build(size: 16, color: app.colors.neutral.grey2),
            ),
          ),
          app.dimensions.padding.m.gap(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: app.textTheme.bodyMedium,
                ),
                // the folder opens the browser in it
                InkWell(
                  onTap: () {
                    app.navigator.pop();
                    RouteNames.openBrowserFolder(task.bucket, task.folder);
                  },
                  child: Text(
                    '/${task.bucket}/${task.folder}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: app.textTheme.bodySmall?.copyWith(
                      color: app.colors.neutral.grey4,
                    ),
                  ),
                ),
                if (running) ...[
                  app.dimensions.padding.xs.gap(),
                  LinearProgressIndicator(
                    // no size, indeterminate bar
                    value: !task.isUpload && task.size == 0
                        ? null
                        : task.progress,
                    minHeight: 3,
                    borderRadius: BorderRadius.circular(2),
                    color: app.colors.primary.primaryFaded,
                    backgroundColor: app.colors.neutral.grey5,
                  ),
                ],
                app.dimensions.padding.xs.gap(),
                Text(
                  status,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: app.textTheme.bodySmall?.copyWith(color: color),
                ),
              ],
            ),
          ),
          app.dimensions.padding.s.gap(),
          if (task.status.isActive)
            _action(
              tooltip: app.intl.transferCancel,
              icon: app.assets.icons.actions.close,
              onPressed: () => cubit.cancel(task.id),
            ),
          if (retryable)
            _action(
              tooltip: app.intl.tryAgain,
              icon: app.assets.icons.actions.refresh,
              onPressed: () => cubit.retry(task.id),
            ),
          if (!task.status.isActive)
            _action(
              tooltip: app.intl.transferRemove,
              icon: app.assets.icons.actions.close,
              onPressed: () => cubit.remove(task.id),
            ),
        ],
      ),
    );
  }

  Widget _action({
    required String tooltip,
    required SvgAsset icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: icon.build(size: 16, color: app.colors.neutral.grey2),
    );
  }
}
