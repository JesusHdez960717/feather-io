import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Actions of the browser dialogs: create folder, rename and move.
/// It lives while the dialog is open, so loading and errors show in it. When
/// done it announces it on the bus: the browser and the bucket lists reload
class ObjectActionCubit extends Cubit<ObjectActionState> {
  final BrowserRepo _repo;
  final AuthCubit _auth;

  ObjectActionCubit(this._repo, this._auth)
    : super(const ObjectActionInitialState());

  String? get _token => _auth.auth?.accessToken;

  /// Creates the folder [name] inside [prefix]
  Future<void> createFolder({
    required String bucket,
    required String prefix,
    required String name,
  }) async {
    await _process(changedBuckets: {bucket}, () async {
      await _repo.createFolder(
        bucket: bucket,
        key: '$prefix$name/',
        token: _token,
      );
    });
  }

  /// Renames [key] to [newName] in the same folder: copies and deletes the original
  Future<void> rename({
    required String bucket,
    required String key,
    required String newName,
  }) async {
    final folder = key.substring(0, key.lastIndexOf('/') + 1);
    await _process(changedBuckets: {bucket}, () async {
      await _repo.copyObject(
        sourceBucket: bucket,
        sourceKey: key,
        bucket: bucket,
        key: '$folder$newName',
        token: _token,
      );
      await _repo.deleteObjects(bucket: bucket, keys: [key], token: _token);
    });
  }

  /// Moves [keys] to [targetPrefix] of [targetBucket]: copies each one and
  /// deletes the originals that were copied. If a copy fails, what was already
  /// copied stays moved and the error says how many were moved
  Future<void> move({
    required String bucket,
    required List<String> keys,
    required String targetBucket,
    required String targetPrefix,
  }) async {
    await _process(changedBuckets: {bucket, targetBucket}, () async {
      final moved = <String>[];
      try {
        for (final key in keys) {
          await _repo.copyObject(
            sourceBucket: bucket,
            sourceKey: key,
            bucket: targetBucket,
            key: '$targetPrefix${key.split('/').last}',
            token: _token,
          );
          moved.add(key);
        }
      } catch (e) {
        if (moved.isNotEmpty) {
          await _repo.deleteObjects(bucket: bucket, keys: moved, token: _token);
        }
        final exception = ExceptionConverter.parse(e);
        throw GlobalException(
          type: exception.type,
          message: moved.isEmpty
              ? exception.message
              : app.intl.objectsMovePartial(moved.length, keys.length),
          data: exception.data,
        );
      }
      await _repo.deleteObjects(bucket: bucket, keys: moved, token: _token);
    });
  }

  Future<void> _process(
    Future<void> Function() action, {
    required Set<String> changedBuckets,
  }) async {
    emit(const ObjectActionProcessInProgressState());
    try {
      await action();
      emit(const ObjectActionProcessingOKState());
    } catch (e) {
      emit(ObjectActionProcessingErrorState(ExceptionConverter.parse(e)));
    } finally {
      for (final bucket in changedBuckets) {
        GlobalEventBus().fire(
          BucketChangedEvent(
            source: this,
            change: BucketChange.objectsChanged,
            bucketName: bucket,
          ),
        );
      }
    }
  }
}

abstract class ObjectActionState {
  const ObjectActionState();
}

class ObjectActionInitialState extends ObjectActionState {
  const ObjectActionInitialState();
}

//------------------------- PROCESSING -------------------------\\
class ObjectActionProcessInProgressState extends ObjectActionState {
  const ObjectActionProcessInProgressState();
}

class ObjectActionProcessingOKState extends ObjectActionState {
  const ObjectActionProcessingOKState();
}

class ObjectActionProcessingErrorState extends ObjectActionState {
  final GlobalException exception;

  const ObjectActionProcessingErrorState(this.exception);
}
