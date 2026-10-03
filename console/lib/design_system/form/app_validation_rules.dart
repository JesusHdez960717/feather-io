import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

enum AppRuleState { pending, ok, fail }

class AppValidationRule {
  final String label;
  final AppRuleState state;

  const AppValidationRule({required this.label, required this.state});
}

/// List of a field's rules that get fulfilled while typing.
/// Each state has its icon, so it doesn't rely on color alone
class AppValidationRules extends StatelessWidget {
  final List<AppValidationRule> rules;

  const AppValidationRules({required this.rules, super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: app.dimensions.padding.l,
      runSpacing: app.dimensions.padding.s,
      children: [for (final rule in rules) _buildRule(rule)],
    );
  }

  Widget _buildRule(AppValidationRule rule) {
    final (icon, iconColor, textColor) = switch (rule.state) {
      AppRuleState.pending => (
        Icons.circle_outlined,
        app.colors.neutral.grey4,
        app.colors.neutral.grey3,
      ),
      AppRuleState.ok => (
        Icons.check_circle_outline,
        app.colors.primary.green,
        app.colors.neutral.grey2,
      ),
      AppRuleState.fail => (
        Icons.cancel_outlined,
        app.colors.primary.error,
        app.colors.primary.error,
      ),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: iconColor),
        app.dimensions.padding.xs.gap(),
        Text(
          rule.label,
          style: app.textTheme.bodySmall?.copyWith(color: textColor),
        ),
      ],
    );
  }
}
