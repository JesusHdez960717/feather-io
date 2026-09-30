import 'package:console/app_exporter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../object_info_helper.dart';

///Cajon con los detalles de un objeto: miniatura si es una imagen, key, tipo,
///tamaño, fecha y URL, y al pie sus acciones. Cada accion cierra el cajon antes
class ObjectDetailsDrawer extends StatefulWidget {
  static Future<void> show({
    required String bucket,
    required BrowserObjectWrapper object,
    required VoidCallback onDelete,
    required VoidCallback onRename,
    required VoidCallback onMove,
    required VoidCallback onDownload,
  }) {
    final info = ObjectInfoHelper.getFileInfo(object);
    void closeThen(VoidCallback action) {
      app.navigator.pop();
      action();
    }

    return FormDrawerTemplate.showAsDialog(
      title: object.name,
      description: app.intl.objectDetailsSubtitle(
        info.name,
        app.storageFormatter.formatSize(object.size ?? 0),
      ),
      icon: app.assets.icons.storage.object,
      width: 560,
      footerActions: [
        //el pie envuelve cada accion en un Padding: ancho fijo (cajon menos
        //su padding) para dejar Eliminar a la izquierda
        SizedBox(
          width: 560 - 1 - 2 * 20,
          child: Row(
            children: [
              PrimaryButton.secondary(
                onPressed: () => closeThen(onDelete),
                title: app.intl.delete,
                icon: app.assets.icons.actions.delete,
                iconColor: app.colors.primary.error,
                h: 40,
                w: 130,
              ),
              const Spacer(),
              PrimaryButton.secondary(
                onPressed: () => closeThen(onRename),
                title: app.intl.objectsRename,
                icon: app.assets.icons.actions.edit,
                h: 40,
                w: 140,
              ),
              app.dimensions.padding.s.gap(),
              PrimaryButton.secondary(
                onPressed: () => closeThen(onMove),
                title: app.intl.objectsMove,
                icon: app.assets.icons.storage.folder,
                h: 40,
                w: 120,
              ),
              app.dimensions.padding.s.gap(),
              PrimaryButton.primary(
                onPressed: () => closeThen(onDownload),
                title: app.intl.download,
                icon: app.assets.icons.actions.download,
                h: 40,
                w: 140,
              ),
            ],
          ),
        ),
      ],
      child: ObjectDetailsDrawer._(bucket: bucket, object: object),
    );
  }

  final String bucket;
  final BrowserObjectWrapper object;

  const ObjectDetailsDrawer._({required this.bucket, required this.object});

  @override
  State<ObjectDetailsDrawer> createState() => _ObjectDetailsDrawerState();
}

class _ObjectDetailsDrawerState extends State<ObjectDetailsDrawer> {
  late final ObjectDetailsCubit cubit =
      ObjectDetailsCubit(app.di.find(), app.di.find())..load(
        bucket: widget.bucket,
        key: widget.object.fullPath,
        sizeBytes: widget.object.size ?? 0,
      );

  String get _url =>
      '${Environment.serviceUrl}/${widget.bucket}/${widget.object.fullPath}';

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ObjectDetailsCubit, ObjectDetailsState>(
      bloc: cubit,
      builder: (context, state) {
        if (state is ObjectDetailsLoadingErrorState) {
          return Text(
            state.exception.message,
            style: app.textTheme.bodyMedium?.copyWith(
              color: app.colors.primary.error,
            ),
          );
        }
        final loaded = state is ObjectDetailsLoadingSuccessState ? state : null;
        final size = loaded?.info.sizeBytes ?? widget.object.size ?? 0;
        final modified =
            loaded?.info.lastModified ?? widget.object.lastModified;
        return LoadingOverlay(
          visible: loaded == null,
          overlayWidgetBuilder: LoadingOverlayStyles.form,
          disableBackButton: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (loaded?.thumbnail != null) ...[
                Container(
                  height: 190,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: app.colors.primary.background1,
                    borderRadius: app.dimensions.border.borderRadius.m,
                    border: Border.all(
                      color: app.colors.neutral.grey5.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Image.memory(
                    Uint8List.fromList(loaded!.thumbnail!),
                    fit: BoxFit.contain,
                  ),
                ),
                app.dimensions.padding.l.gap(),
              ],
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: app.dimensions.padding.l,
                ),
                decoration: BoxDecoration(
                  color: app.colors.primary.background2,
                  borderRadius: app.dimensions.border.borderRadius.m,
                  border: Border.all(color: app.colors.neutral.grey5),
                ),
                child: Column(
                  children: [
                    _row(
                      app.intl.objectDetailsKey,
                      _code(widget.object.fullPath),
                    ),
                    _row(
                      app.intl.objectDetailsType,
                      Text(loaded?.info.contentType ?? '-'),
                    ),
                    _row(
                      app.intl.objectDetailsSize,
                      Text(
                        '${app.storageFormatter.formatSize(size)} '
                        '${app.intl.objectDetailsSizeBytes(size)}',
                      ),
                    ),
                    _row(
                      app.intl.objectDetailsModified,
                      Text(
                        modified == null
                            ? '-'
                            : app.dateFormatter.l.format(modified),
                      ),
                    ),
                    _row(
                      app.intl.objectDetailsUrl,
                      Row(
                        children: [
                          Flexible(child: _code(_url)),
                          IconButton(
                            tooltip: app.intl.objectDetailsCopyUrl,
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _url));
                              app.snack.showSuccess(
                                message: app.intl.objectDetailsUrlCopied,
                                context: context,
                              );
                            },
                            icon: app.assets.icons.actions.copy.build(
                              size: 16,
                              color: app.colors.neutral.grey3,
                            ),
                          ),
                        ],
                      ),
                      last: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _code(String text) {
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
        text,
        style: app.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
      ),
    );
  }

  Widget _row(String label, Widget value, {bool last = false}) {
    return Container(
      constraints: const BoxConstraints(minHeight: 46),
      padding: EdgeInsets.symmetric(vertical: app.dimensions.padding.s),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(
                bottom: BorderSide(
                  color: app.colors.neutral.grey5.withValues(alpha: 0.5),
                ),
              ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: app.textTheme.bodyMedium?.copyWith(
                color: app.colors.neutral.grey3,
              ),
            ),
          ),
          Expanded(
            child: DefaultTextStyle.merge(
              style: app.textTheme.bodyMedium,
              child: value,
            ),
          ),
        ],
      ),
    );
  }
}
