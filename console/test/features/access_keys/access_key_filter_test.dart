import 'package:console/app_exporter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';

void main() {
  final reader = accessKey(
    name: 'Reader',
    grants: [grant('photos', AccessKeyLevel.readOnly)],
  );
  final writer = accessKey(
    name: 'Writer',
    grants: [
      grant('inbox', AccessKeyLevel.writeOnly),
      grant('photos', AccessKeyLevel.writeOnly),
    ],
  );
  final everything = accessKey(
    name: 'All',
    allBuckets: AccessKeyLevel.readWrite,
  );
  final disabled = accessKey(
    name: 'Off',
    enabled: false,
    grants: [grant('backups', AccessKeyLevel.readOnly)],
  );
  final expired = accessKey(
    name: 'Old',
    expired: true,
    grants: [grant('backups', AccessKeyLevel.readOnly)],
  );
  final keys = [reader, writer, everything, disabled, expired];

  List<String> names(AccessKeyFilter filter) =>
      keys.where(filter.matches).map((k) => k.name).toList();

  test('No filter lets every key through', () {
    expect(names(AccessKeyFilter.none), [
      'Reader',
      'Writer',
      'All',
      'Off',
      'Old',
    ]);
    expect(AccessKeyFilter.none.isActive, isFalse);
  });

  test('Status: one of the checked ones', () {
    expect(names(const AccessKeyFilter(statuses: {AccessKeyStatus.disabled})), [
      'Off',
    ]);
    expect(
      names(
        const AccessKeyFilter(
          statuses: {AccessKeyStatus.disabled, AccessKeyStatus.expired},
        ),
      ),
      ['Off', 'Old'],
    );
  });

  test('A disabled key is disabled even if it also expired', () {
    final both = accessKey(enabled: false, expired: true);
    expect(both.status, AccessKeyStatus.disabled);
  });

  test('Level: any of the key levels, its own or on every bucket', () {
    expect(names(const AccessKeyFilter(levels: {AccessKeyLevel.writeOnly})), [
      'Writer',
    ]);
    expect(names(const AccessKeyFilter(levels: {AccessKeyLevel.readWrite})), [
      'All',
    ]);
  });

  test('Bucket: keys on every bucket reach any bucket', () {
    expect(names(const AccessKeyFilter(buckets: {'photos'})), [
      'Reader',
      'Writer',
      'All',
    ]);
    expect(names(const AccessKeyFilter(buckets: {'nowhere'})), ['All']);
  });

  test('Groups are combined: every group must match', () {
    const filter = AccessKeyFilter(
      statuses: {AccessKeyStatus.active},
      levels: {AccessKeyLevel.readOnly},
      buckets: {'photos', 'backups'},
    );
    expect(names(filter), ['Reader']);
    expect(filter.activeCount, 4);
  });

  test('copyWith changes only the given group', () {
    const filter = AccessKeyFilter(statuses: {AccessKeyStatus.active});
    final changed = filter.copyWith(buckets: {'photos'});
    expect(changed.statuses, {AccessKeyStatus.active});
    expect(changed.buckets, {'photos'});
    expect(changed.levels, isEmpty);
  });
}
