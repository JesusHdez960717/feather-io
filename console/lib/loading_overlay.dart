import 'dart:ui';

import 'package:material_ui/material_ui.dart';

///Muestra y oculta los [LoadingOverlay] montados.
///
///```dart
///LoadingOverlay(id: 'bucket-create', child: form)
///
///LoadingOverlayController().show(id: 'bucket-create');
///LoadingOverlayController().hide(id: 'bucket-create');
///```
///
///Con `id` busca el [LoadingOverlay] con ese id; sin `id`, el ultimo montado.
///Para el que envuelve a un widget, sin id, usa [LoadingOverlay.of].
class LoadingOverlayController {
  static final LoadingOverlayController _instance =
      LoadingOverlayController._internal();

  LoadingOverlayController._internal();

  factory LoadingOverlayController() => _instance;

  ///Montados, en orden de montaje; el ultimo es el que esta mas arriba
  final List<LoadingOverlayState> _mounted = [];

  void show({Object? id}) => _find(id: id, action: 'show')?.show();

  void hide({Object? id}) => _find(id: id, action: 'hide')?.hide();

  bool isShowing({Object? id}) =>
      _find(id: id, action: 'isShowing')?.isShowing ?? false;

  void _register(LoadingOverlayState state) => _mounted.add(state);

  void _unregister(LoadingOverlayState state) => _mounted.remove(state);

  LoadingOverlayState? _find({required String action, Object? id}) {
    final found = id != null
        ? _mounted.where((s) => s.widget.id == id).lastOrNull
        : _mounted.lastOrNull;
    if (found == null) {
      debugPrint(
        'LoadingOverlayController.$action: no LoadingOverlay found (id: $id)',
      );
    }
    return found;
  }
}

///Zona que se puede cubrir con un velo de carga. Mientras se ve, bloquea las
///pulsaciones sobre [child] sin desactivar sus widgets.
///
///Se controla de dos formas:
///- Declarativa, con [visible] desde el `build` (p. ej. segun el estado de un
///  cubit). Si [visible] no es null, manda sobre `show`/`hide`.
///- Imperativa, con [LoadingOverlayController.show] / `hide` (por `id`) o
///  con `LoadingOverlay.of(context).show()` / `hide()` desde un descendiente.
///
///[overlayWidgetBuilder] dibuja el velo (por defecto [defaultOverlay]). Va
///recortado a los limites de [child], asi que un [BackdropFilter] no desenfoca
///nada fuera de la zona:
///
///```dart
///LoadingOverlay(
///  overlayWidgetBuilder: (context) => BackdropFilter(
///    filter: ImageFilter.blur(sigmaX: 4.5, sigmaY: 4.5),
///    child: const Center(child: CircularProgressIndicator()),
///  ),
///  child: form,
///)
///```
class LoadingOverlay extends StatefulWidget {
  ///Para encontrarlo con `LoadingOverlayController().show(id: ...)`
  final Object? id;
  final Widget child;
  final WidgetBuilder overlayWidgetBuilder;

  ///Si no es null, el velo se ve cuando vale true, sin necesidad de `show`
  final bool? visible;

  ///Mientras se ve, impide cerrar la ruta que lo contiene (boton atras, Escape,
  ///pulsar fuera de un dialogo o `Navigator.maybePop`)
  final bool disableBackButton;

  const LoadingOverlay({
    required this.child,
    this.id,
    this.visible,
    this.overlayWidgetBuilder = defaultOverlay,
    this.disableBackButton = true,
    super.key,
  });

  ///Blur ligero y el spinner del tema
  static Widget defaultOverlay(BuildContext context) => BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
    child: const Center(child: CircularProgressIndicator()),
  );

  ///El [LoadingOverlay] mas cercano por encima de [context], o null si no hay
  static LoadingOverlayState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<LoadingOverlayState>();

  ///El [LoadingOverlay] mas cercano por encima de [context]:
  ///`LoadingOverlay.of(context).show()`. [context] tiene que estar por debajo
  ///del [LoadingOverlay] (el del widget que lo construye no vale: usa un
  ///[Builder])
  static LoadingOverlayState of(BuildContext context) {
    final state = maybeOf(context);
    if (state == null) {
      throw FlutterError(
        'LoadingOverlay.of() called with a context that has no LoadingOverlay above it.',
      );
    }
    return state;
  }

  @override
  State<LoadingOverlay> createState() => LoadingOverlayState();
}

class LoadingOverlayState extends State<LoadingOverlay> {
  bool _visible = false;

  ///Si el velo se ve (con [LoadingOverlay.visible], si no es null, manda este)
  bool get isShowing => widget.visible ?? _visible;

  void show() => _setVisible(true);

  void hide() => _setVisible(false);

  void _setVisible(bool visible) {
    if (!mounted || _visible == visible) return;
    setState(() => _visible = visible);
  }

  @override
  void initState() {
    super.initState();
    LoadingOverlayController()._register(this);
  }

  @override
  void dispose() {
    LoadingOverlayController()._unregister(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = isShowing;
    return PopScope(
      canPop: !(widget.disableBackButton && visible),
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !visible,
              child: AnimatedOpacity(
                opacity: visible ? 1 : 0,
                duration: const Duration(milliseconds: 150),
                child: ClipRect(
                  child: Builder(builder: widget.overlayWidgetBuilder),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
