import 'dart:math';

import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class SnackBarAdapter {
  static final SnackBarAdapter _instance = SnackBarAdapter._internal();

  SnackBarAdapter._internal();

  factory SnackBarAdapter() => _instance;

  void showSuccess({required String message, required BuildContext context}) {
    _show(
      context: context,
      child: _AppSnackBar(
        message: message,
        icon: Icons.check_circle_outline,
        backgroundColor: app.colors.primary.greenAction,
      ),
    );
  }

  void showError({required String message, required BuildContext context}) {
    _show(
      context: context,
      child: _AppSnackBar(
        message: message,
        icon: Icons.error_outline,
        backgroundColor: app.colors.primary.errorAction,
      ),
    );
  }

  ///Ancho del aviso; en pantallas mas estrechas, lo que quepa
  static const double width = 420;

  void _show({required BuildContext context, required Widget child}) {
    //el overlay raiz cubre toda la pantalla; el de cada rama del shell solo
    //el contenido, sin el rail, y el aviso perderia el ancho de este
    final overlay = Overlay.of(context, rootOverlay: true);
    final screen = MediaQuery.sizeOf(overlay.context).width;
    final margin = app.dimensions.padding.l;
    showTopSnackBar(
      overlay,
      snackBarPosition: SnackBarPosition.bottom,
      //abajo a la derecha con ancho fijo: el margen izquierdo es lo que sobra
      padding: EdgeInsets.only(
        right: margin,
        bottom: margin,
        left: max(margin, screen - margin - width),
      ),
      child,
    );
  }
}

///Exito y error se distinguen por el icono ademas de por el color
class _AppSnackBar extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color backgroundColor;

  const _AppSnackBar({
    required this.message,
    required this.icon,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: app.dimensions.border.borderRadius.m,
      elevation: 6,
      child: Padding(
        padding: EdgeInsets.all(app.dimensions.padding.l),
        child: Row(
          children: [
            Icon(icon, size: 24, color: app.colors.neutral.white),
            app.dimensions.padding.m.gap(),
            Expanded(
              child: Text(
                message,
                style: app.textTheme.titleMedium!.copyWith(
                  color: app.colors.neutral.white,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
