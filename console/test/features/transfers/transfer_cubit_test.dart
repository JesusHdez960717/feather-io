import 'dart:async';
import 'dart:typed_data';

import 'package:console/app_exporter.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/fixtures.dart';

class _MockRepo extends Mock implements TransferRepo {}

class _MockAuth extends Mock implements AuthCubit {}

XFile _file(String name, int size) =>
    XFile.fromData(Uint8List(size), name: name, path: name, length: size);

void main() {
  late _MockRepo repo;
  late _MockAuth auth;
  late TransferCubit cubit;
  late List<BucketChangedEvent> events;
  late StreamSubscription<BucketChangedEvent> bus;

  When<Future<void>> whenUpload({String? key}) => when(
    () => repo.upload(
      id: any(named: 'id'),
      bucket: any(named: 'bucket'),
      key: key ?? any(named: 'key'),
      data: any(named: 'data'),
      length: any(named: 'length'),
      onProgress: any(named: 'onProgress'),
      token: any(named: 'token'),
    ),
  );

  When<Future<String>> whenUploadPart() => when(
    () => repo.uploadPart(
      id: any(named: 'id'),
      bucket: any(named: 'bucket'),
      key: any(named: 'key'),
      uploadId: any(named: 'uploadId'),
      partNumber: any(named: 'partNumber'),
      data: any(named: 'data'),
      length: any(named: 'length'),
      onProgress: any(named: 'onProgress'),
      token: any(named: 'token'),
    ),
  );

  setUpAll(() => registerFallbackValue(const Stream<List<int>>.empty()));

  setUp(() {
    repo = _MockRepo();
    auth = _MockAuth();
    when(() => auth.auth).thenReturn(session());
    whenUpload().thenAnswer((_) async {});
    when(
      () => repo.abortMultipart(
        bucket: any(named: 'bucket'),
        key: any(named: 'key'),
        uploadId: any(named: 'uploadId'),
        token: any(named: 'token'),
      ),
    ).thenAnswer((_) async {});
    cubit = TransferCubit(repo, auth);
    events = [];
    bus = GlobalEventBus().on<BucketChangedEvent>().listen(events.add);
  });

  tearDown(() async {
    await bus.cancel();
    await cubit.close();
  });

  List<TransferStatus> statuses() =>
      cubit.state.tasks.map((t) => t.status).toList();

  group('uploads', () {
    test('Uploads each file into the folder and tells the bucket', () async {
      await cubit.upload(
        bucket: 'media',
        prefix: 'photos/',
        files: [_file('a.jpg', 3)],
      );
      await pumpEventQueue();

      verify(
        () => repo.upload(
          id: any(named: 'id'),
          bucket: 'media',
          key: 'photos/a.jpg',
          data: any(named: 'data'),
          length: 3,
          onProgress: any(named: 'onProgress'),
          token: 'jwt',
        ),
      );
      expect(cubit.state, isA<TransferProcessingOKState>());
      final task = cubit.state.tasks.single;
      expect(task.status, TransferStatus.done);
      expect(task.name, 'a.jpg');
      expect(task.folder, 'photos/');
      expect(events.single.bucketName, 'media');
      expect(events.single.change, BucketChange.objectsChanged);
    });

    test('A folder without a trailing slash still gets one', () async {
      await cubit.upload(
        bucket: 'media',
        prefix: 'photos',
        files: [_file('a.jpg', 1)],
      );
      await pumpEventQueue();

      expect(cubit.state.tasks.single.key, 'photos/a.jpg');
    });

    test('Runs two uploads at a time; the rest wait their turn', () async {
      final running = <String, Completer<void>>{};
      whenUpload().thenAnswer((call) {
        final key = call.namedArguments[#key] as String;
        return (running[key] = Completer<void>()).future;
      });

      await cubit.upload(
        bucket: 'media',
        prefix: '',
        files: [_file('a', 1), _file('b', 1), _file('c', 1)],
      );
      await pumpEventQueue();

      expect(running.keys, ['a', 'b']);
      expect(statuses(), [
        TransferStatus.running,
        TransferStatus.running,
        TransferStatus.queued,
      ]);
      expect(cubit.state.activeCount, 3);

      running['a']!.complete();
      await pumpEventQueue();
      expect(running.keys, ['a', 'b', 'c']);

      running['b']!.complete();
      running['c']!.complete();
      await pumpEventQueue();
      expect(statuses(), everyElement(TransferStatus.done));
    });

    test('With uploads pending, the bucket is announced at most every '
        'interval', () async {
      final running = <String, Completer<void>>{};
      whenUpload().thenAnswer((call) {
        final key = call.namedArguments[#key] as String;
        return (running[key] = Completer<void>()).future;
      });
      await cubit.upload(
        bucket: 'media',
        prefix: '',
        files: [_file('a', 1), _file('b', 1), _file('c', 1)],
      );
      await pumpEventQueue();

      running['a']!.complete();
      await pumpEventQueue();
      running['b']!.complete();
      await pumpEventQueue();
      expect(events, hasLength(1), reason: 'b ends right after a');

      running['c']!.complete();
      await pumpEventQueue();
      expect(events, hasLength(2), reason: 'the last one always announces');
    });

    test('A failure keeps the error, and a retry uploads again', () async {
      whenUpload().thenThrow(apiError('down'));
      await cubit.upload(bucket: 'media', prefix: '', files: [_file('a', 1)]);
      await pumpEventQueue();

      final failed = cubit.state.tasks.single;
      expect(failed.status, TransferStatus.failed);
      expect(failed.error?.message, 'down');
      expect(cubit.state.failedCount, 1);
      expect(events, isEmpty, reason: 'nothing was uploaded');

      whenUpload().thenAnswer((_) async {});
      cubit.retry(failed.id);
      await pumpEventQueue();

      final retried = cubit.state.tasks.single;
      expect(retried.status, TransferStatus.done);
      expect(retried.error, isNull);
    });

    test('Cancelling cuts the request and the task stays cancelled', () async {
      final upload = Completer<void>();
      whenUpload().thenAnswer((_) => upload.future);
      when(() => repo.cancel(any())).thenAnswer((_) {
        upload.completeError(apiError('cancelled'));
      });
      await cubit.upload(bucket: 'media', prefix: '', files: [_file('a', 1)]);
      await pumpEventQueue();

      final id = cubit.state.tasks.single.id;
      cubit.cancel(id);
      await pumpEventQueue();

      verify(() => repo.cancel(id));
      expect(cubit.state.tasks.single.status, TransferStatus.cancelled);
      expect(cubit.state.tasks.single.error, isNull);
    });

    test('Progress is reported per task and for the whole batch', () async {
      final upload = Completer<void>();
      late void Function(int, int) progress;
      whenUpload().thenAnswer((call) {
        progress = call.namedArguments[#onProgress] as void Function(int, int);
        return upload.future;
      });
      await cubit.upload(bucket: 'media', prefix: '', files: [_file('a', 100)]);
      await pumpEventQueue();

      progress(25, 100);
      expect(cubit.state.tasks.single.transferred, 25);
      expect(cubit.state.progress, 0.25);

      upload.complete();
      await pumpEventQueue();
      expect(cubit.state.progress, 1);
    });
  });

  group('multipart', () {
    const mib = 1024 * 1024;
    const size = TransferCubit.multipartThreshold + mib;

    setUp(() {
      when(
        () => repo.createMultipart(
          id: any(named: 'id'),
          bucket: any(named: 'bucket'),
          key: any(named: 'key'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async => 'upload-1');
      whenUploadPart().thenAnswer(
        (call) async => 'etag-${call.namedArguments[#partNumber]}',
      );
      when(
        () => repo.completeMultipart(
          id: any(named: 'id'),
          bucket: any(named: 'bucket'),
          key: any(named: 'key'),
          uploadId: any(named: 'uploadId'),
          parts: any(named: 'parts'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async {});
    });

    test(
      'A big file goes in parts and is completed with their ETags',
      () async {
        await cubit.upload(
          bucket: 'media',
          prefix: '',
          files: [_file('video.mp4', size)],
        );
        await pumpEventQueue();

        final lengths = verify(
          () => repo.uploadPart(
            id: any(named: 'id'),
            bucket: 'media',
            key: 'video.mp4',
            uploadId: 'upload-1',
            partNumber: any(named: 'partNumber'),
            data: any(named: 'data'),
            length: captureAny(named: 'length'),
            onProgress: any(named: 'onProgress'),
            token: 'jwt',
          ),
        ).captured;
        expect(lengths, [
          TransferCubit.partSize,
          TransferCubit.partSize,
          size - 2 * TransferCubit.partSize,
        ]);
        final parts =
            verify(
                  () => repo.completeMultipart(
                    id: any(named: 'id'),
                    bucket: 'media',
                    key: 'video.mp4',
                    uploadId: 'upload-1',
                    parts: captureAny(named: 'parts'),
                    token: 'jwt',
                  ),
                ).captured.single
                as List<UploadedPart>;
        expect(parts.map((p) => '${p.number}:${p.etag}'), [
          '1:etag-1',
          '2:etag-2',
          '3:etag-3',
        ]);
        verifyNever(
          () => repo.upload(
            id: any(named: 'id'),
            bucket: any(named: 'bucket'),
            key: any(named: 'key'),
            data: any(named: 'data'),
            length: any(named: 'length'),
            onProgress: any(named: 'onProgress'),
            token: any(named: 'token'),
          ),
        );
        expect(cubit.state.tasks.single.status, TransferStatus.done);
      },
    );

    test('A failed part aborts the upload on the service', () async {
      whenUploadPart().thenThrow(apiError('down'));
      await cubit.upload(
        bucket: 'media',
        prefix: '',
        files: [_file('video.mp4', size)],
      );
      await pumpEventQueue();

      verify(
        () => repo.abortMultipart(
          bucket: 'media',
          key: 'video.mp4',
          uploadId: 'upload-1',
          token: 'jwt',
        ),
      );
      expect(cubit.state.tasks.single.status, TransferStatus.failed);
    });
  });

  group('downloads', () {
    test('Downloads the zip and finishes with its size', () async {
      when(
        () => repo.downloadZip(
          id: any(named: 'id'),
          bucket: any(named: 'bucket'),
          keys: any(named: 'keys'),
          onProgress: any(named: 'onProgress'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async => [1, 2, 3, 4]);

      cubit.download(
        bucket: 'media',
        keys: ['photos/a.jpg', 'photos/b.jpg'],
        zipName: 'holidays',
      );
      await pumpEventQueue();

      final task = cubit.state.tasks.single;
      expect(task.direction, TransferDirection.download);
      expect(task.name, 'holidays.zip');
      expect(task.folder, 'photos/');
      expect(task.status, TransferStatus.done);
      expect(task.size, 4);
      expect(events, isEmpty, reason: 'a download changes no bucket');
    });
  });

  group('list', () {
    Future<void> twoFinished() async {
      whenUpload(key: 'b').thenThrow(apiError());
      await cubit.upload(
        bucket: 'media',
        prefix: '',
        files: [_file('a', 1), _file('b', 1)],
      );
      await pumpEventQueue();
    }

    test('Removing a finished task leaves the others', () async {
      await twoFinished();
      cubit.remove(cubit.state.tasks.first.id);
      expect(cubit.state.tasks.map((t) => t.name), ['b']);
    });

    test('Clearing the finished ones empties the list', () async {
      await twoFinished();
      cubit.clearFinished();
      expect(cubit.state, isA<TransferInitialState>());
    });

    test('Logging out cancels what is running and clears the list', () async {
      whenUpload().thenAnswer((_) => Completer<void>().future);
      when(() => repo.cancel(any())).thenReturn(null);
      await cubit.upload(bucket: 'media', prefix: '', files: [_file('a', 1)]);
      await pumpEventQueue();

      cubit.reset();

      verify(() => repo.cancel(any())).called(1);
      expect(cubit.state, isA<TransferInitialState>());
    });
  });
}
