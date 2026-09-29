import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';

class FormDrawerTemplate extends StatelessWidget {
  ///Se completa al cerrarse el cajon. Para impedir que se cierre (p. ej.
  ///mientras se envia), el [child] puede envolverse en un [PopScope]
  static Future<void> showAsDialog({
    required String title,
    required String description,
    required SvgAsset icon,
    required List<Widget> footerActions,
    required Widget child,
    BuildContext? context,
    double? width,
  }) {
    return showGeneralDialog(
      context: context ?? app.context,
      barrierDismissible: true,
      barrierLabel: app.intl.close,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Builder(
            builder: (context) {
              return FormDrawerTemplate(
                title: title,
                description: description,
                icon: icon,
                footerActions: footerActions,
                child: child,
              );
            },
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        );
      },
    );
  }

  final String title;
  final String description;
  final SvgAsset icon;
  final List<Widget> footerActions;
  final Widget child;
  final double? width;

  const FormDrawerTemplate({
    required this.title,
    required this.description,
    required this.icon,
    required this.footerActions,
    required this.child,
    super.key,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: app.colors.neutral.transparent,
      child: Container(
        width: width ?? (app.mediaQuery.size.width * 0.45),
        height: double.infinity,
        decoration: BoxDecoration(
          color: app.colors.primary.backgroundForm,
          border: Border(
            left: BorderSide(
              color: app.colors.neutral.grey5.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(-5, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            // ---------- HEADER ----------
            Container(
              padding: EdgeInsets.all(app.dimensions.padding.xl),
              decoration: BoxDecoration(
                color: app.colors.primary.background2,
                border: Border(
                  bottom: BorderSide(
                    color: app.colors.neutral.grey5.withValues(alpha: 0.1),
                  ),
                ),
              ),

              child: Row(
                crossAxisAlignment: .start,
                mainAxisAlignment: .start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: app.colors.primary.primaryFaded.withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: app.dimensions.border.borderRadius.m,
                    ),
                    child: icon.build(
                      size: 24,
                      color: app.colors.neutral.white,
                    ),
                  ),
                  app.dimensions.padding.m.gap(),
                  Flexible(
                    child: Column(
                      mainAxisAlignment: .start,
                      crossAxisAlignment: .start,
                      children: [
                        Text(
                          title,
                          style: app.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          description,
                          style: app.textTheme.bodyMedium?.copyWith(
                            color: app.colors.neutral.grey3,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: app.intl.close,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: app.assets.icons.actions.close.build(
                      size: 20,
                      color: app.colors.neutral.grey3,
                    ),
                  ),
                ],
              ),
            ),

            // ---------- BODY ----------
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(app.dimensions.padding.xl),
                child: child,
              ),
            ),

            // ---------- FOOTER ----------
            Container(
              padding: EdgeInsets.all(app.dimensions.padding.xl),
              decoration: BoxDecoration(
                color: app.colors.primary.background2,
                border: Border(
                  top: BorderSide(
                    color: app.colors.neutral.grey5.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: footerActions.map((action) {
                  final isLast = footerActions.last == action;
                  return Padding(
                    padding: EdgeInsets.only(
                      right: isLast ? 0 : app.dimensions.padding.m,
                    ),
                    child: action,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
