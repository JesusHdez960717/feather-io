import 'package:console/app_exporter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

///Dialogo para compartir un objeto con un enlace que caduca (URL prefirmada).
///Genera el enlace al abrirse y al cambiar la caducidad
class ShareLinkDialog extends StatefulWidget {
  static void show({required String bucket, required String key}) {
    DialogTemplate.open(
      title: app.intl.objectsShareLink,
      w: 560,
      h: 360,
      child: ShareLinkDialog._(bucket: bucket, objectKey: key),
    );
  }

  final String bucket;
  final String objectKey;

  const ShareLinkDialog._({required this.bucket, required this.objectKey});

  @override
  State<ShareLinkDialog> createState() => _ShareLinkDialogState();
}

class _ShareLinkDialogState extends State<ShareLinkDialog> {
  late final ShareLinkCubit cubit = ShareLinkCubit(
    app.di.find(),
    app.di.find(),
  );

  @override
  void initState() {
    super.initState();
    _generate(ShareLinkExpiration.day);
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  void _generate(ShareLinkExpiration expiration) {
    cubit.generate(
      bucket: widget.bucket,
      key: widget.objectKey,
      expiration: expiration,
    );
  }

  String _label(ShareLinkExpiration expiration) => switch (expiration) {
    ShareLinkExpiration.hour => app.intl.shareLinkHour,
    ShareLinkExpiration.day => app.intl.shareLinkDay,
    ShareLinkExpiration.week => app.intl.shareLinkWeek,
  };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShareLinkCubit, ShareLinkState>(
      bloc: cubit,
      builder: (context, state) {
        final link = state is ShareLinkLoadingSuccessState ? state.link : null;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: app.dimensions.padding.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                app.intl.shareLinkDescription(widget.objectKey.split('/').last),
                style: app.textTheme.bodyMedium?.copyWith(
                  color: app.colors.neutral.grey2,
                ),
              ),
              app.dimensions.padding.l.gap(),
              Row(
                children: [
                  Text(
                    app.intl.shareLinkExpiresIn,
                    style: app.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  app.dimensions.padding.m.gap(),
                  SegmentedButton<ShareLinkExpiration>(
                    showSelectedIcon: false,
                    segments: [
                      for (final expiration in ShareLinkExpiration.values)
                        ButtonSegment(
                          value: expiration,
                          label: Text(_label(expiration)),
                        ),
                    ],
                    selected: {state.expiration},
                    onSelectionChanged: (selection) =>
                        _generate(selection.first),
                  ),
                ],
              ),
              app.dimensions.padding.l.gap(),
              Container(
                height: 48,
                padding: EdgeInsets.only(left: app.dimensions.padding.m),
                decoration: BoxDecoration(
                  color: app.colors.primary.background1,
                  borderRadius: app.dimensions.border.borderRadius.s,
                  border: Border.all(color: app.colors.neutral.grey5),
                ),
                child: LoadingOverlay(
                  visible: state is ShareLinkLoadingInProgressState,
                  overlayWidgetBuilder: LoadingOverlayStyles.table,
                  disableBackButton: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          switch (state) {
                            ShareLinkLoadingErrorState(:final exception) =>
                              exception.message,
                            _ => link?.url ?? '',
                          },
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: app.textTheme.bodyMedium?.copyWith(
                            fontFamily: 'monospace',
                            color: state is ShareLinkLoadingErrorState
                                ? app.colors.primary.error
                                : null,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: app.intl.shareLinkCopy,
                        onPressed: link == null
                            ? null
                            : () {
                                Clipboard.setData(
                                  ClipboardData(text: link.url),
                                );
                                app.snack.showSuccess(
                                  message: app.intl.shareLinkCopied,
                                  context: context,
                                );
                              },
                        icon: app.assets.icons.actions.copy.build(
                          size: 18,
                          color: link == null
                              ? app.colors.neutral.grey5
                              : app.colors.neutral.grey2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              app.dimensions.padding.s.gap(),
              Text(
                link == null
                    ? ''
                    : app.intl.shareLinkValidUntil(
                        app.dateFormatter.l.format(link.expiresAt),
                      ),
                style: app.textTheme.bodySmall?.copyWith(
                  color: app.colors.neutral.grey3,
                ),
              ),
              app.dimensions.padding.xl.gap(),
              PrimaryButton.primary(
                onPressed: () => app.navigator.pop(),
                title: app.intl.close,
                color: app.colors.primary.background3,
              ),
            ],
          ),
        );
      },
    );
  }
}
