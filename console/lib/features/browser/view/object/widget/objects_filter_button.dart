import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

/// *Filter* button of the browser: type, size and modification date of the
/// objects of the pages already loaded
class ObjectsFilterButton extends StatelessWidget {
  final ObjectFilter filter;
  final ValueChanged<ObjectFilter> onChanged;

  const ObjectsFilterButton({
    required this.filter,
    required this.onChanged,
    super.key,
  });

  Set<T> _toggle<T>(Set<T> set, T value) =>
      set.contains(value) ? ({...set}..remove(value)) : {...set, value};

  @override
  Widget build(BuildContext context) {
    return AppFilterButton(
      activeCount: filter.activeCount,
      onClear: () => onChanged(ObjectFilter.none),
      note: app.intl.objectsFilterFoldersHidden,
      groups: [
        AppFilterGroup(
          title: app.intl.objectsFilterType,
          options: [
            for (final type in ObjectTypeFilter.values)
              AppFilterOption(
                label: _typeLabel(type),
                selected: filter.types.contains(type),
                onTap: () => onChanged(
                  filter.copyWith(types: _toggle(filter.types, type)),
                ),
              ),
          ],
        ),
        AppFilterGroup(
          title: app.intl.objectsFilterSize,
          options: [
            for (final size in ObjectSizeFilter.values)
              AppFilterOption(
                label: _sizeLabel(size),
                selected: filter.sizes.contains(size),
                onTap: () => onChanged(
                  filter.copyWith(sizes: _toggle(filter.sizes, size)),
                ),
              ),
          ],
        ),
        AppFilterGroup(
          title: app.intl.objectsFilterModified,
          options: [
            for (final date in ObjectDateFilter.values)
              AppFilterOption(
                label: _dateLabel(date),
                selected: filter.dates.contains(date),
                onTap: () => onChanged(
                  filter.copyWith(dates: _toggle(filter.dates, date)),
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _typeLabel(ObjectTypeFilter type) => switch (type) {
    ObjectTypeFilter.image => app.intl.fileTypeImage,
    ObjectTypeFilter.video => app.intl.fileTypeVideo,
    ObjectTypeFilter.audio => app.intl.fileTypeAudio,
    ObjectTypeFilter.document => app.intl.fileTypeDocument,
    ObjectTypeFilter.archive => app.intl.fileTypeArchive,
    ObjectTypeFilter.other => app.intl.objectsFilterTypeOther,
  };

  String _sizeLabel(ObjectSizeFilter size) => switch (size) {
    ObjectSizeFilter.small => app.intl.objectsFilterSizeSmall,
    ObjectSizeFilter.medium => app.intl.objectsFilterSizeMedium,
    ObjectSizeFilter.large => app.intl.objectsFilterSizeLarge,
  };

  String _dateLabel(ObjectDateFilter date) => switch (date) {
    ObjectDateFilter.last24Hours => app.intl.objectsFilterDate24h,
    ObjectDateFilter.last7Days => app.intl.objectsFilterDate7d,
    ObjectDateFilter.last30Days => app.intl.objectsFilterDate30d,
    ObjectDateFilter.older => app.intl.objectsFilterDateOlder,
  };
}
