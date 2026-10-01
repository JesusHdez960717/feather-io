import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

///Boton cuadrado del pie del rail (transferencias, idioma, cerrar sesion):
///44x44, `background2` con borde `grey5` y `radius-s`. [onPressed] recibe el
///contexto del boton, para anclar a el un menu o un panel
class RailButton extends StatelessWidget {
  static const double size = 44;

  final String tooltip;
  final void Function(BuildContext context) onPressed;
  final Widget child;

  ///Se pinta fuera del borde, sobre la esquina superior derecha
  final Widget? badge;

  const RailButton({
    required this.tooltip,
    required this.onPressed,
    required this.child,
    this.badge,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final radius = app.dimensions.border.borderRadius.s;
    return Tooltip(
      message: tooltip,
      //el badge va fuera del Material: este pinta su borde por encima de lo
      //que contiene
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AppFocusRing(
            borderRadius: radius,
            child: Material(
              color: app.colors.primary.background2,
              shape: RoundedRectangleBorder(
                borderRadius: radius,
                side: BorderSide(color: app.colors.neutral.grey5),
              ),
              child: InkWell(
                borderRadius: radius,
                hoverColor: app.colors.primary.background3,
                onTap: () => onPressed(context),
                child: SizedBox.square(
                  dimension: size,
                  child: Center(child: child),
                ),
              ),
            ),
          ),
          if (badge != null)
            Positioned(
              top: -6,
              right: -6,
              //no tapa la pulsacion del boton
              child: IgnorePointer(child: badge),
            ),
        ],
      ),
    );
  }
}
