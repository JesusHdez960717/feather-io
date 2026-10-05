import 'dart:ui' show lerpDouble;

import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

/// Base screen with the navigation rail
class BaseScreen extends StatefulWidget {
  /// The navigation shell and container for the branch Navigators.
  final StatefulNavigationShell navigationShell;

  const BaseScreen(this.navigationShell, {super.key});

  @override
  State<BaseScreen> createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  bool _isRailExpanded = false;

  void _toggleRail() {
    setState(() {
      _isRailExpanded = !_isRailExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: NavigationRail(
              extended: _isRailExpanded,
              minWidth: _RailFooter.collapsedWidth,
              minExtendedWidth: _RailFooter.expandedWidth,
              selectedIndex: widget.navigationShell.currentIndex,
              onDestinationSelected: _onTap,
              leading: _RailMenuButton(
                expanded: _isRailExpanded,
                onPressed: _toggleRail,
              ),
              destinations: [
                NavigationRailDestination(
                  icon: app.assets.icons.storage.folder.build(
                    color: app.colors.neutral.grey3,
                  ),
                  selectedIcon: app.assets.icons.storage.folder.build(
                    color: app.colors.neutral.white,
                  ),
                  label: Text(app.intl.navBrowser),
                ),
                NavigationRailDestination(
                  icon: app.assets.icons.storage.bucket.build(
                    color: app.colors.neutral.grey3,
                  ),
                  selectedIcon: app.assets.icons.storage.bucket.build(
                    color: app.colors.neutral.white,
                  ),
                  label: Text(app.intl.navBuckets),
                ),
                NavigationRailDestination(
                  icon: app.assets.icons.actions.key.build(
                    color: app.colors.neutral.grey3,
                  ),
                  selectedIcon: app.assets.icons.actions.key.build(
                    color: app.colors.neutral.white,
                  ),
                  label: Text(app.intl.navAccessKeys),
                ),
              ],
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: app.dimensions.padding.l),
                    child: const _RailFooter(),
                  ),
                ),
              ),
            ),
          ),
          VerticalDivider(
            thickness: 1,
            width: 1,
            color: app.colors.neutral.grey5,
          ),
          Expanded(child: widget.navigationShell),
        ],
      ),
    );
  }

  void _onTap(int index) {
    widget.navigationShell.goBranch(index);
  }
}

/// Rail footer: transfers, language and log out, three identical [RailButton]s.
/// With the rail collapsed they go in a column and expanded in a row; each one
/// slides from one place to the other with the rail's own animation
class _RailFooter extends StatelessWidget {
  static const double collapsedWidth = 80;

  /// The footer row plus `padding-l` on each side
  static const double expandedWidth = _rowWidth + 2 * 16;

  static const double _gap = 12;
  static const double _size = RailButton.size;
  static const double _rowWidth = 3 * _size + 2 * _gap;

  const _RailFooter();

  @override
  Widget build(BuildContext context) {
    final animation = NavigationRail.extendedAnimation(context);
    final buttons = [
      const TransfersIndicator(),
      const LanguageWidget(),
      RailButton(
        tooltip: app.intl.navLogout,
        onPressed: (_) => app.di.find<AuthCubit>().logout(),
        child: app.assets.icons.actions.logout.build(
          size: 18,
          color: app.colors.neutral.grey2,
        ),
      ),
    ];
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        // with "reduce motion" they jump from the column to the row
        final t = MediaQuery.disableAnimationsOf(context)
            ? animation.value.roundToDouble()
            : animation.value;
        final width = lerpDouble(collapsedWidth, expandedWidth, t)!;
        // the column is as tall as the row is wide
        final height = lerpDouble(_rowWidth, _size, t)!;
        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < buttons.length; i++)
                Positioned(
                  left: lerpDouble(
                    (collapsedWidth - _size) / 2,
                    (expandedWidth - _rowWidth) / 2 + i * (_size + _gap),
                    t,
                  ),
                  top: lerpDouble(i * (_size + _gap), 0, t),
                  child: buttons[i],
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Button to expand/collapse the rail. The rail centers its `leading`; this one
/// takes the whole width of the rail and stays on the left, in the same place as
/// with the rail collapsed, so it doesn't move when expanding it
class _RailMenuButton extends StatelessWidget {
  static const double _size = 48;

  final bool expanded;
  final VoidCallback onPressed;

  const _RailMenuButton({required this.expanded, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final animation = NavigationRail.extendedAnimation(context);
    final button = SizedBox.square(
      dimension: _size,
      child: IconButton(
        icon:
            (expanded
                    ? app.assets.icons.navigation.left
                    : app.assets.icons.navigation.menu)
                .build(size: 22, color: app.colors.neutral.grey2),
        onPressed: onPressed,
      ),
    );
    return AnimatedBuilder(
      animation: animation,
      child: button,
      builder: (context, child) => SizedBox(
        width: lerpDouble(
          _RailFooter.collapsedWidth,
          _RailFooter.expandedWidth,
          animation.value,
        ),
        child: Padding(
          padding: const EdgeInsets.only(
            left: (_RailFooter.collapsedWidth - _size) / 2,
          ),
          child: Align(alignment: Alignment.centerLeft, child: child),
        ),
      ),
    );
  }
}
