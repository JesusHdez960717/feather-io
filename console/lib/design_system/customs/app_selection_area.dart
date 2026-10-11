import 'package:material_ui/material_ui.dart';

/// Makes all the text of the app selectable with the mouse. It goes in the
/// `builder` of `MaterialApp`, above the `Navigator`, so it covers screens,
/// dialogs and drawers. It has its own [Overlay] because there is none there yet
/// to paint the selection's context menu
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
