import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

///Boton de las transferencias en segundo plano, siempre visible al pie del
///rail: un anillo con el progreso total y un badge con las que quedan (o las
///que fallaron). Abre el [TransfersPanel]
class TransfersIndicator extends StatelessWidget {
  const TransfersIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransferCubit, TransferState>(
      bloc: app.di.find<TransferCubit>(),
      builder: (context, state) {
        final active = state is TransferProcessInProgressState;
        final failed = state.failedCount > 0;
        final badge = active
            ? state.activeCount
            : (failed ? state.failedCount : 0);
        return RailButton(
          tooltip: TransfersPanel.summary(state) ?? app.intl.transfersTitle,
          onPressed: TransfersPanel.show,
          badge: badge > 0 ? _Badge(count: badge, error: !active) : null,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (active)
                SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    value: state.progress,
                    strokeWidth: 2.5,
                    color: app.colors.primary.primaryFaded,
                    backgroundColor: app.colors.neutral.grey5,
                  ),
                ),
              _icon(state),
            ],
          ),
        );
      },
    );
  }

  Widget _icon(TransferState state) {
    final icon = app.assets.icons.actions.transfer;
    return switch (state) {
      TransferProcessInProgressState() => icon.build(
        size: 14,
        color: app.colors.neutral.white,
      ),
      TransferProcessingOKState(:final failedCount) when failedCount > 0 =>
        icon.build(size: 18, color: app.colors.primary.error),
      TransferProcessingOKState() => Icon(
        Icons.check_rounded,
        size: 20,
        color: app.colors.primary.green,
      ),
      _ => icon.build(size: 18, color: app.colors.neutral.grey2),
    };
  }
}

class _Badge extends StatelessWidget {
  final int count;
  final bool error;

  const _Badge({required this.count, required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: error
            ? app.colors.primary.errorAction
            : app.colors.primary.secondary,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: app.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: error
              ? app.colors.neutral.white
              : app.colors.primary.background1,
        ),
      ),
    );
  }
}
