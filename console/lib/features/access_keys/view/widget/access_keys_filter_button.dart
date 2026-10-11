import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

/// *Filter* button of the access keys: status, level and bucket
class AccessKeysFilterButton extends StatelessWidget {
  final AccessKeyFilter filter;

  /// Names of the existing buckets, for the bucket group
  final List<String> buckets;
  final ValueChanged<AccessKeyFilter> onChanged;

  const AccessKeysFilterButton({
    required this.filter,
    required this.buckets,
    required this.onChanged,
    super.key,
  });

  Set<T> _toggle<T>(Set<T> set, T value) =>
      set.contains(value) ? ({...set}..remove(value)) : {...set, value};

  @override
  Widget build(BuildContext context) {
    return AppFilterButton(
      activeCount: filter.activeCount,
      onClear: () => onChanged(AccessKeyFilter.none),
      groups: [
        AppFilterGroup(
          title: app.intl.accessKeysFilterStatus,
          options: [
            for (final status in AccessKeyStatus.values)
              AppFilterOption(
                label: switch (status) {
                  AccessKeyStatus.active => app.intl.accessKeyStatusActive,
                  AccessKeyStatus.disabled => app.intl.accessKeyStatusDisabled,
                  AccessKeyStatus.expired => app.intl.accessKeyStatusExpired,
                },
                selected: filter.statuses.contains(status),
                onTap: () => onChanged(
                  filter.copyWith(statuses: _toggle(filter.statuses, status)),
                ),
              ),
          ],
        ),
        AppFilterGroup(
          title: app.intl.accessKeysFilterLevel,
          options: [
            for (final level in AccessKeyLevel.values)
              AppFilterOption(
                label: level.shortLabel,
                selected: filter.levels.contains(level),
                onTap: () => onChanged(
                  filter.copyWith(levels: _toggle(filter.levels, level)),
                ),
              ),
          ],
        ),
        if (buckets.isNotEmpty)
          AppFilterGroup(
            title: app.intl.accessKeysFilterBucket,
            options: [
              for (final bucket in buckets)
                AppFilterOption(
                  label: bucket,
                  selected: filter.buckets.contains(bucket),
                  onTap: () => onChanged(
                    filter.copyWith(buckets: _toggle(filter.buckets, bucket)),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
