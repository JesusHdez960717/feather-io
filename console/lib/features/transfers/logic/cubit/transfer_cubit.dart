import 'dart:math';

import 'package:console/app_exporter.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Background transfer queue (uploads and downloads). It lives across the whole
/// app: transfers keep going across folders, buckets and sections. It runs
/// [maxConcurrent] uploads and as many downloads at a time and announces the
/// finished uploads with [BucketChangedEvent]
class TransferCubit extends Cubit<TransferState> {
  static const int maxConcurrent = 2;

  /// With uploads pending in a bucket, it announces at most once per this time,
  /// so the browser doesn't reload for every file
  static const Duration announceInterval = Duration(seconds: 2);

  /// Above this size it uploads in parts (multipart): on web every request is
  /// loaded whole in memory, so this way there is only one part at a time
  static const int multipartThreshold = 16 * 1024 * 1024;

  /// Size of each part (S3 asks for at least 5 MiB except for the last one)
  static const int partSize = 8 * 1024 * 1024;

  final TransferRepo _repo;
  final AuthCubit _auth;

  final List<TransferTask> _tasks = [];

  /// Ids of the transfers since the queue was last idle: the total progress is
  /// computed over them
  final Set<String> _batch = {};

  final Set<String> _unannounced = {};
  final Map<String, DateTime> _lastAnnounced = {};
  final Map<TransferDirection, int> _running = {
    for (final direction in TransferDirection.values) direction: 0,
  };
  int _nextId = 0;

  TransferCubit(this._repo, this._auth) : super(const TransferInitialState());

  /// Queues [files] to upload them to [prefix] of [bucket]
  Future<void> upload({
    required String bucket,
    required String prefix,
    required List<XFile> files,
  }) async {
    for (final file in files) {
      // a folder prefix already ends in '/' (e.g. 'photos/')
      final key = prefix.isEmpty || prefix.endsWith('/')
          ? '$prefix${file.name}'
          : '$prefix/${file.name}';
      _add(
        TransferTask(
          id: '${_nextId++}',
          direction: TransferDirection.upload,
          bucket: bucket,
          name: key.split('/').where((s) => s.isNotEmpty).last,
          folder: TransferTask.parentFolder(key),
          key: key,
          file: file,
          size: await file.length(),
        ),
      );
    }
    _emit();
    _pump();
  }

  /// Queues the download of [keys] of [bucket] in a zip named [zipName]
  /// (`.zip` is appended); without it, it is named after the key or the date
  void download({
    required String bucket,
    required List<String> keys,
    String? zipName,
  }) {
    _add(
      TransferTask(
        id: '${_nextId++}',
        direction: TransferDirection.download,
        bucket: bucket,
        name: zipFileName(keys, zipName: zipName),
        folder: TransferTask.parentFolder(keys.first),
        keys: keys,
      ),
    );
    _emit();
    _pump();
  }

  /// Zip name of a download
  static String zipFileName(List<String> keys, {String? zipName}) {
    if (zipName != null) {
      return zipName.endsWith('.zip') ? zipName : '$zipName.zip';
    }
    if (keys.length == 1) {
      return '${keys.first.split('/').where((s) => s.isNotEmpty).last}.zip';
    }
    return 'download_${DateTime.now().millisecondsSinceEpoch}.zip';
  }

  void cancel(String id) {
    final task = _find(id);
    if (task == null || !task.status.isActive) return;
    _update(id, (t) => t.copyWith(status: TransferStatus.cancelled));
    _repo.cancel(id);
  }

  void retry(String id) {
    final task = _find(id);
    if (task == null || task.status.isActive) return;
    _batch.add(id);
    _update(
      id,
      (t) => t.copyWith(
        status: TransferStatus.queued,
        transferred: 0,
        size: t.isUpload ? t.size : 0,
        clearError: true,
      ),
    );
    _pump();
  }

  /// Removes a finished transfer from the list
  void remove(String id) {
    _tasks.removeWhere((t) => t.id == id && !t.status.isActive);
    _emit();
  }

  void clearFinished() {
    _tasks.removeWhere((t) => !t.status.isActive);
    _emit();
  }

  /// On log out: cuts everything and clears the list
  void reset() {
    for (final task in _tasks) {
      if (task.status.isActive) _repo.cancel(task.id);
    }
    _tasks.clear();
    _batch.clear();
    _unannounced.clear();
    _emit();
  }

  void _add(TransferTask task) {
    _tasks.add(task);
    _batch.add(task.id);
  }

  TransferTask? _find(String id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    return index < 0 ? null : _tasks[index];
  }

  void _update(String id, TransferTask Function(TransferTask task) change) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index < 0) return;
    _tasks[index] = change(_tasks[index]);
    _emit();
  }

  /// Starts queued transfers until the free slots of each direction are filled
  void _pump() {
    for (final direction in TransferDirection.values) {
      while (_running[direction]! < maxConcurrent) {
        final index = _tasks.indexWhere(
          (t) => t.direction == direction && t.status == TransferStatus.queued,
        );
        if (index < 0) break;
        final task = _tasks[index];
        _running[direction] = _running[direction]! + 1;
        _update(task.id, (t) => t.copyWith(status: TransferStatus.running));
        final run = task.isUpload ? _runUpload(task) : _runDownload(task);
        run.whenComplete(() {
          _running[direction] = _running[direction]! - 1;
          _pump();
        });
      }
    }
  }

  /// Stores the progress of [id] if it is still running, at most once per 1%
  void Function(int transferred, int total) _progress(String id) {
    var last = -1;
    return (transferred, total) {
      final task = _find(id);
      if (task == null || task.status != TransferStatus.running) return;
      final size = task.isUpload ? task.size : max(total, 0);
      final percent = size == 0 ? -1 : transferred * 100 ~/ size;
      if (percent == last && size == task.size) return;
      last = percent;
      _update(
        id,
        (t) => t.copyWith(
          size: size,
          transferred: size == 0 ? transferred : min(transferred, size),
        ),
      );
    };
  }

  Future<void> _runUpload(TransferTask task) async {
    var uploaded = false;
    try {
      if (task.size > multipartThreshold) {
        await _uploadMultipart(task);
      } else {
        await _repo.upload(
          id: task.id,
          token: _auth.auth?.accessToken,
          bucket: task.bucket,
          key: task.key!,
          data: task.file!.openRead(),
          length: task.size,
          onProgress: _progress(task.id),
        );
      }
      uploaded = true;
      _finish(task.id);
    } catch (e) {
      _fail(task.id, e);
    } finally {
      _announce(task.bucket, uploaded: uploaded);
    }
  }

  /// Uploads [task] in parts of [partSize], one after another. If it fails or
  /// is cancelled, it aborts the upload on the service so no parts are left behind
  Future<void> _uploadMultipart(TransferTask task) async {
    final token = _auth.auth?.accessToken;
    final report = _progress(task.id);
    String? uploadId;
    try {
      uploadId = await _repo.createMultipart(
        id: task.id,
        token: token,
        bucket: task.bucket,
        key: task.key!,
      );
      final parts = <UploadedPart>[];
      var done = 0;
      for (var number = 1; done < task.size; number++) {
        // cancelled between two parts
        if (_find(task.id)?.status != TransferStatus.running) {
          throw const _Cancelled();
        }
        final end = min(done + partSize, task.size);
        final sent = done;
        final etag = await _repo.uploadPart(
          id: task.id,
          token: token,
          bucket: task.bucket,
          key: task.key!,
          uploadId: uploadId,
          partNumber: number,
          data: task.file!.openRead(done, end),
          length: end - done,
          onProgress: (bytes, _) => report(sent + bytes, task.size),
        );
        parts.add(UploadedPart(number: number, etag: etag));
        done = end;
      }
      await _repo.completeMultipart(
        id: task.id,
        token: token,
        bucket: task.bucket,
        key: task.key!,
        uploadId: uploadId,
        parts: parts,
      );
    } catch (_) {
      final id = uploadId;
      if (id != null) {
        // not awaited: if it fails, the service deletes it when the bucket is deleted
        _repo
            .abortMultipart(
              token: token,
              bucket: task.bucket,
              key: task.key!,
              uploadId: id,
            )
            .ignore();
      }
      rethrow;
    }
  }

  Future<void> _runDownload(TransferTask task) async {
    try {
      final bytes = await _repo.downloadZip(
        id: task.id,
        token: _auth.auth?.accessToken,
        bucket: task.bucket,
        keys: task.keys,
        onProgress: _progress(task.id),
      );
      // if it was cancelled right when finishing, it is not stored
      if (_find(task.id)?.status != TransferStatus.running) return;
      FileSaver.save(bytes, task.name);
      _finish(task.id, size: bytes.length);
    } catch (e) {
      _fail(task.id, e);
    }
  }

  void _finish(String id, {int? size}) {
    _update(
      id,
      (t) => t.status == TransferStatus.running
          ? t.copyWith(
              status: TransferStatus.done,
              size: size ?? t.size,
              transferred: size ?? t.size,
            )
          : t,
    );
  }

  void _fail(String id, Object error) {
    _update(
      id,
      (t) => t.status == TransferStatus.running
          ? t.copyWith(
              status: TransferStatus.failed,
              error: ExceptionConverter.parse(error),
            )
          : t,
    );
  }

  /// Announces that [bucket] has new objects: when its last pending upload
  /// ends or, if some remain, every [announceInterval]
  void _announce(String bucket, {required bool uploaded}) {
    if (uploaded) _unannounced.add(bucket);
    if (!_unannounced.contains(bucket)) return;
    final pending = _tasks.any(
      (t) => t.isUpload && t.bucket == bucket && t.status.isActive,
    );
    final last = _lastAnnounced[bucket];
    final now = DateTime.now();
    if (pending && last != null && now.difference(last) < announceInterval) {
      return;
    }
    _unannounced.remove(bucket);
    _lastAnnounced[bucket] = now;
    GlobalEventBus().fire(
      BucketChangedEvent(
        source: this,
        change: BucketChange.objectsChanged,
        bucketName: bucket,
      ),
    );
  }

  void _emit() {
    if (isClosed) return;
    final tasks = List<TransferTask>.unmodifiable(_tasks);
    final active = tasks.where((t) => t.status.isActive).length;
    final failed = tasks.where((t) => t.status == TransferStatus.failed).length;
    final finished = tasks.length - active;
    _guardLeave(active > 0);
    if (tasks.isEmpty) {
      _batch.clear();
      emit(const TransferInitialState());
      return;
    }
    if (active == 0) {
      _batch.clear();
      emit(
        TransferProcessingOKState(
          tasks: tasks,
          failedCount: failed,
          finishedCount: finished,
        ),
      );
      return;
    }
    final batch = tasks.where(
      (t) => _batch.contains(t.id) && t.status != TransferStatus.cancelled,
    );
    final total = batch.fold<int>(0, (sum, t) => sum + t.size);
    final done = batch.fold<int>(
      0,
      (sum, t) => sum + (t.progress * t.size).round(),
    );
    emit(
      TransferProcessInProgressState(
        tasks: tasks,
        activeCount: active,
        failedCount: failed,
        finishedCount: finished,
        progress: total == 0 ? 0 : done / total,
      ),
    );
  }

  //------------------------- LEAVE WARNING -------------------------\\
  bool _guarding = false;

  /// With transfers running, the browser asks before closing or reloading the
  /// tab
  void _guardLeave(bool on) {
    if (on == _guarding) return;
    _guarding = on;
    BrowserWindow.guardLeave(on);
  }

  @override
  Future<void> close() {
    _guardLeave(false);
    return super.close();
  }
}

/// A multipart upload cancelled between two parts
class _Cancelled implements Exception {
  const _Cancelled();
}

abstract class TransferState {
  final List<TransferTask> tasks;

  /// Queued or running
  final int activeCount;
  final int failedCount;

  /// Finished (successfully, with an error or cancelled): the ones that can be removed
  final int finishedCount;

  /// Progress of the transfers since the queue was idle, from 0 to 1
  final double progress;

  const TransferState({
    this.tasks = const [],
    this.activeCount = 0,
    this.failedCount = 0,
    this.finishedCount = 0,
    this.progress = 0,
  });
}

/// No transfers
class TransferInitialState extends TransferState {
  const TransferInitialState();
}

//------------------------- PROCESS -------------------------\\
/// There are queued or running transfers
class TransferProcessInProgressState extends TransferState {
  const TransferProcessInProgressState({
    required super.tasks,
    required super.activeCount,
    required super.failedCount,
    required super.finishedCount,
    required super.progress,
  });
}

/// Every transfer has finished; [failedCount] says how many failed
class TransferProcessingOKState extends TransferState {
  const TransferProcessingOKState({
    required super.tasks,
    required super.failedCount,
    required super.finishedCount,
  }) : super(progress: 1);
}
