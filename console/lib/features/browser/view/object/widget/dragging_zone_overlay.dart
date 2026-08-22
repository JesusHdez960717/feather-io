import 'dart:ui';

import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

class DraggingZoneOverlay extends StatelessWidget {
  const DraggingZoneOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4.5, sigmaY: 4.5),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: app.colors.neutral.grey5, width: 0.5),
            right: BorderSide(color: app.colors.neutral.grey5, width: 0.5),
            bottom: BorderSide(color: app.colors.neutral.grey5, width: 0.5),
          ),
          color: app.colors.neutral.white.withValues(alpha: 0.03),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              app.assets.icons.actions.upload.build(
                size: 48,
                color: app.colors.neutral.white,
              ),
              app.dimensions.padding.m.gap(),
              Text(
                'Suelte aqui para subir',
                style: app.textTheme.titleLarge?.copyWith(
                  color: app.colors.neutral.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
