import 'package:console/app_exporter.dart';
import 'package:flutter_test/flutter_test.dart';

BrowserObjectWrapper _object(String name, {int size = 0, DateTime? at}) =>
    BrowserObjectWrapper(
      name: name,
      isFolder: false,
      fullPath: name,
      size: size,
      lastModified: at ?? DateTime(2026, 10, 1),
    );

void main() {
  group('ObjectName', () {
    ObjectNameError? validate(String name, {String? current}) =>
        ObjectName.validate(
          name,
          existing: {'photos', 'a.jpg'},
          current: current,
        );

    test('A new name is valid', () {
      expect(validate('beach.jpg'), isNull);
      expect(validate('  beach.jpg  '), isNull);
    });

    test('Empty, the same name or one that exists', () {
      expect(validate('   '), ObjectNameError.empty);
      expect(validate('a.jpg', current: 'a.jpg'), ObjectNameError.unchanged);
      expect(validate('photos'), ObjectNameError.exists);
    });

    test('Characters the service rejects, dot names and very long names', () {
      for (final name in ['a/b', r'a\b', 'a:b', 'a*b', 'a?b', '.', '..']) {
        expect(validate(name), ObjectNameError.invalid, reason: name);
      }
      expect(validate('x' * 256), ObjectNameError.invalid);
    });
  });

  group('ObjectFilter', () {
    const mb = 1024 * 1024;
    final now = DateTime(2026, 10, 5, 12);

    test('No filter lets everything through, folders included', () {
      final folder = BrowserObjectWrapper(
        name: 'photos',
        isFolder: true,
        fullPath: 'photos/',
      );
      expect(ObjectFilter.none.matches(folder), isTrue);
      expect(ObjectFilter.none.matches(_object('a.jpg')), isTrue);
    });

    test('Any active filter hides the folders', () {
      final folder = BrowserObjectWrapper(
        name: 'photos',
        isFolder: true,
        fullPath: 'photos/',
      );
      const filter = ObjectFilter(sizes: {ObjectSizeFilter.small});
      expect(filter.matches(folder), isFalse);
    });

    test('Type by the extension', () {
      const images = ObjectFilter(types: {ObjectTypeFilter.image});
      expect(images.matches(_object('a.jpg')), isTrue);
      expect(images.matches(_object('a.pdf')), isFalse);
      expect(ObjectTypeFilter.of('report.docx'), ObjectTypeFilter.document);
      expect(ObjectTypeFilter.of('backup.zip'), ObjectTypeFilter.archive);
      expect(ObjectTypeFilter.of('no-extension'), ObjectTypeFilter.other);
    });

    test(
      'Within a group one option is enough; across groups all must match',
      () {
        const filter = ObjectFilter(
          types: {ObjectTypeFilter.image, ObjectTypeFilter.video},
          sizes: {ObjectSizeFilter.large},
        );
        expect(filter.matches(_object('a.mp4', size: 200 * mb)), isTrue);
        expect(filter.matches(_object('a.jpg', size: 200 * mb)), isTrue);
        expect(filter.matches(_object('a.jpg', size: mb)), isFalse);
      },
    );

    test('Size ranges: under 1 MB, 1 to 100 MB, over 100 MB', () {
      expect(ObjectSizeFilter.small.matches(mb - 1), isTrue);
      expect(ObjectSizeFilter.medium.matches(mb), isTrue);
      expect(ObjectSizeFilter.medium.matches(100 * mb), isTrue);
      expect(ObjectSizeFilter.large.matches(100 * mb + 1), isTrue);
    });

    test('Date by the age of the last change', () {
      const recent = ObjectFilter(dates: {ObjectDateFilter.last24Hours});
      const old = ObjectFilter(dates: {ObjectDateFilter.older});
      final yesterday = _object(
        'a.jpg',
        at: now.subtract(const Duration(hours: 20)),
      );
      final lastYear = _object('b.jpg', at: DateTime(2025, 1, 1));

      expect(recent.matches(yesterday, now: now), isTrue);
      expect(recent.matches(lastYear, now: now), isFalse);
      expect(old.matches(lastYear, now: now), isTrue);
    });

    test('activeCount counts every checked option', () {
      const filter = ObjectFilter(
        types: {ObjectTypeFilter.image},
        dates: {ObjectDateFilter.last7Days, ObjectDateFilter.older},
      );
      expect(filter.activeCount, 3);
      expect(filter.isActive, isTrue);
      expect(filter.copyWith(types: {}).activeCount, 2);
    });
  });
}
