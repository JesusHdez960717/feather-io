import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Language selector of the rail footer: the flag of the current language in a
/// [RailButton]; it opens a menu with the languages
class LanguageWidget extends CubitView<LanguageCubit> {
  const LanguageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, LanguageState>(
      builder: (context, state) {
        return RailButton(
          tooltip: app.intl.navLanguage(state.current.name),
          onPressed: (anchor) => _showMenu(anchor, state),
          child: ClipRRect(
            borderRadius: app.dimensions.border.borderRadius.xs,
            child: state.current.icon.build(size: 22),
          ),
        );
      },
    );
  }

  /// The menu opens over the button
  void _showMenu(BuildContext anchor, LanguageState state) {
    final button = anchor.findRenderObject() as RenderBox;
    final overlay = Overlay.of(anchor).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: anchor,
      position: position,
      color: app.colors.primary.background2,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: app.dimensions.border.borderRadius.s,
        side: BorderSide(color: app.colors.neutral.grey5),
      ),
      items: [
        for (final language in state.allLanguages)
          PopupMenuItem(
            value: language.key,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: app.dimensions.border.borderRadius.xs,
                  child: language.icon.build(size: 22),
                ),
                app.dimensions.padding.m.gap(),
                Text(
                  language.name,
                  style: app.textTheme.bodyMedium?.copyWith(
                    color: app.colors.neutral.white,
                    fontWeight: language == state.current
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
      ],
    ).then((key) {
      if (key != null) cubit.changeLanguageKey(languageKey: key);
    });
  }
}
