import 'package:material_ui/material_ui.dart';

///Hace seleccionable con el raton todo el texto de la app. Va en el `builder`
///de `MaterialApp`, por encima del `Navigator`, asi cubre pantallas, dialogos y
///cajones. Lleva su propio [Overlay] porque ahi aun no hay uno donde pintar el
///menu contextual de la seleccion
class AppSelectionArea extends StatefulWidget {
  final Widget child;

  const AppSelectionArea({required this.child, super.key});

  @override
  State<AppSelectionArea> createState() => _AppSelectionAreaState();
}

class _AppSelectionAreaState extends State<AppSelectionArea> {
  late final OverlayEntry _entry = OverlayEntry(
    builder: (context) => SelectionArea(child: widget.child),
  );

  @override
  void didUpdateWidget(covariant AppSelectionArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    _entry.markNeedsBuild();
  }

  @override
  Widget build(BuildContext context) {
    return Overlay(initialEntries: [_entry]);
  }
}
