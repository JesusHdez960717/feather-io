import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

///este es el screen base con el bottom-nav-bar
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
              selectedIndex: widget.navigationShell.currentIndex,
              onDestinationSelected: _onTap,
              //leading: const SizedBox.shrink(),
              leading: IconButton(
                icon:
                    (_isRailExpanded
                            ? app.assets.icons.navigation.left
                            : app.assets.icons.navigation.menu)
                        .build(size: 22, color: app.colors.neutral.grey2),
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
              ],
              trailing: Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const LanguageWidget(),
                    app.dimensions.padding.m.gap(),
                    PrimaryButton.svgIcon(
                      onPressed: () {
                        app.di.find<AuthCubit>().logout();
                      },
                      buttonSize: 38,
                      icon: app.assets.icons.actions.logout,
                      iconColor: app.colors.neutral.white,
                    ),
                    app.dimensions.padding.l.gap(),
                  ],
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
