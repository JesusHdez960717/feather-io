import 'dart:ui';

import 'package:material_ui/material_ui.dart';

/// Shows and hides the mounted [LoadingOverlay]s.
///
/// ```dart
/// LoadingOverlay(id: 'bucket-create', child: form)
///
/// LoadingOverlayController().show(id: 'bucket-create');
/// LoadingOverlayController().hide(id: 'bucket-create');
/// ```
///
/// With `id` it looks for the [LoadingOverlay] with that id; without `id`, the
/// last one mounted. For the one wrapping a widget, without an id, use [LoadingOverlay.of].
class LoadingOverlayController {
  static final LoadingOverlayController _instance =
      LoadingOverlayController._internal();

  LoadingOverlayController._internal();

  factory LoadingOverlayController() => _instance;

  /// Mounted, in mounting order; the last one is the topmost
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

/// Area that can be covered with a loading veil. While visible, it blocks taps
/// on [child] without disabling its widgets.
///
/// It can be controlled in two ways:
/// - Declaratively, with [visible] from `build` (e.g. from a cubit's state).
///   If [visible] is not null, it wins over `show`/`hide`.
/// - Imperatively, with [LoadingOverlayController.show] / `hide` (by `id`) or
///   with `LoadingOverlay.of(context).show()` / `hide()` from a descendant.
///
/// [overlayWidgetBuilder] draws the veil ([defaultOverlay] by default). It is
/// clipped to the bounds of [child], so a [BackdropFilter] blurs nothing
/// outside the area:
///
/// ```dart
/// LoadingOverlay(
///   overlayWidgetBuilder: (context) => BackdropFilter(
///     filter: ImageFilter.blur(sigmaX: 4.5, sigmaY: 4.5),
///     child: const Center(child: CircularProgressIndicator()),
///   ),
///   child: form,
/// )
/// ```
class LoadingOverlay extends StatefulWidget {
  /// To find it with `LoadingOverlayController().show(id: ...)`
  final Object? id;
  final Widget child;
  final WidgetBuilder overlayWidgetBuilder;

  /// If not null, the veil shows while it is true, without calling `show`
  final bool? visible;

  /// While visible, it stops the route that contains it from closing (back
  /// button, Escape, tapping outside a dialog or `Navigator.maybePop`)
  final bool disableBackButton;

  const LoadingOverlay({
    required this.child,
    this.id,
    this.visible,
    this.overlayWidgetBuilder = defaultOverlay,
    this.disableBackButton = true,
    super.key,
  });

  /// Light blur and the theme's spinner
  static Widget defaultOverlay(BuildContext context) => BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
    child: const Center(child: CircularProgressIndicator()),
  );

  /// The closest [LoadingOverlay] above [context], or null if there is none
  static LoadingOverlayState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<LoadingOverlayState>();

  /// The closest [LoadingOverlay] above [context]:
  /// `LoadingOverlay.of(context).show()`. [context] must be below the
  /// [LoadingOverlay] (the context of the widget that builds it doesn't work:
  /// use a [Builder])
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

  /// Whether the veil shows ([LoadingOverlay.visible], when not null, wins)
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
