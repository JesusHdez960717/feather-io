import 'package:console/app_exporter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransferCubit.zipFileName', () {
    test('A given name gets .zip once', () {
      expect(
        TransferCubit.zipFileName(['a', 'b'], zipName: 'books'),
        'books.zip',
      );
      expect(
        TransferCubit.zipFileName(['a', 'b'], zipName: 'books.zip'),
        'books.zip',
      );
    });

    test('A single key names the zip after it (folder or object)', () {
      expect(TransferCubit.zipFileName(['photos/2026/']), '2026.zip');
      expect(TransferCubit.zipFileName(['docs/report.pdf']), 'report.pdf.zip');
    });

    test('Several keys without a name get a dated name', () {
      expect(
        TransferCubit.zipFileName(['a.txt', 'b.txt']),
        matches(RegExp(r'^download_\d+\.zip$')),
      );
    });
  });
}
