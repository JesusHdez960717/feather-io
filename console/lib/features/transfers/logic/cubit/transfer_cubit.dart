import 'dart:js_interop';
import 'dart:math';
import 'dart:typed_data';

import 'package:console/app_exporter.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web/web.dart' as web;

///Cola de transferencias (subidas y descargas) en segundo plano. Vive en toda
///la app: siguen aunque se cambie de carpeta, de bucket o de seccion. Hace
///[maxConcurrent] subidas y otras tantas descargas a la vez y avisa con
///[BucketChangedEvent] de las subidas que terminan
class TransferCubit extends Cubit<TransferState> {
  static const int maxConcurrent = 2;

  ///Con subidas pendientes en un bucket, se avisa como mucho cada este tiempo
  ///para no recargar el explorador por cada fichero
  static const Duration announceInterval = Duration(seconds: 2);

  final TransferRepo _repo;
  final AuthCubit _auth;

  final List<TransferTask> _tasks = [];

  ///Ids de las transferencias desde que la cola estuvo parada por ultima vez:
  ///el progreso total se calcula sobre ellas
  final Set<String> _batch = {};

  final Set<String> _unannounced = {};
  final Map<String, DateTime> _lastAnnounced = {};
  final Map<TransferDirection, int> _running = {
    for (final direction in TransferDirection.values) direction: 0,
  };
  int _nextId = 0;

  TransferCubit(this._repo, this._auth) : super(const TransferInitialState());

  ///Pone en cola [files] para subirlos a [prefix] de [bucket]
  Future<void> upload({
    required String bucket,
    required String prefix,
    required List<XFile> files,
  }) async {
    for (final file in files) {
      //el prefijo de una carpeta ya termina en '/' (p. ej. 'fotos/')
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

  ///Pone en cola la descarga de [keys] de [bucket] en un zip llamado
  ///[zipName] (se le añade `.zip`); sin el, se nombra por la key o la fecha
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

  ///Nombre del zip de una descarga
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

  ///Quita de la lista una transferencia ya terminada
  void remove(String id) {
    _tasks.removeWhere((t) => t.id == id && !t.status.isActive);
    _emit();
  }

  void clearFinished() {
    _tasks.removeWhere((t) => !t.status.isActive);
    _emit();
  }

  ///Al cerrar sesion: corta todo y vacia la lista
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

  ///Arranca transferencias en cola hasta llenar los huecos de cada sentido
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

  ///Guarda el progreso de [id] si sigue en curso, como mucho uno por cada 1%
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
      await _repo.upload(
        id: task.id,
        token: _auth.auth?.accessToken,
        bucket: task.bucket,
        key: task.key!,
        data: task.file!.openRead(),
        length: task.size,
        onProgress: _progress(task.id),
      );
      uploaded = true;
      _finish(task.id);
    } catch (e) {
      _fail(task.id, e);
    } finally {
      _announce(task.bucket, uploaded: uploaded);
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
      //si la cancelaron justo al acabar, no se guarda
      if (_find(task.id)?.status != TransferStatus.running) return;
      _save(bytes, task.name);
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

  ///Entrega el fichero al navegador para que lo guarde
  void _save(List<int> bytes, String fileName) {
    final blob = web.Blob([Uint8List.fromList(bytes).toJS].toJS);
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.download = fileName;
    anchor.click();
    web.URL.revokeObjectURL(url);
  }

  ///Avisa de que [bucket] tiene objetos nuevos: al acabar su ultima subida
  ///pendiente o, si aun quedan, cada [announceInterval]
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

  //------------------------- AVISO AL SALIR -------------------------\\
  bool _guarding = false;

  late final JSFunction _beforeUnload = ((web.Event event) {
    event.preventDefault();
  }).toJS;

  ///Con transferencias en curso, el navegador pregunta antes de cerrar o
  ///recargar la pestaña
  void _guardLeave(bool on) {
    if (on == _guarding) return;
    _guarding = on;
    if (on) {
      web.window.addEventListener('beforeunload', _beforeUnload);
    } else {
      web.window.removeEventListener('beforeunload', _beforeUnload);
    }
  }

  @override
  Future<void> close() {
    _guardLeave(false);
    return super.close();
  }
}

abstract class TransferState {
  final List<TransferTask> tasks;

  ///En cola o en curso
  final int activeCount;
  final int failedCount;

  ///Terminadas (bien, con error o canceladas): las que se pueden quitar
  final int finishedCount;

  ///Progreso de las transferencias desde que la cola estuvo parada, de 0 a 1
  final double progress;

  const TransferState({
    this.tasks = const [],
    this.activeCount = 0,
    this.failedCount = 0,
    this.finishedCount = 0,
    this.progress = 0,
  });
}

///Sin transferencias
class TransferInitialState extends TransferState {
  const TransferInitialState();
}

//------------------------- PROCESS -------------------------\\
///Hay transferencias en cola o en curso
class TransferProcessInProgressState extends TransferState {
  const TransferProcessInProgressState({
    required super.tasks,
    required super.activeCount,
    required super.failedCount,
    required super.finishedCount,
    required super.progress,
  });
}

///Todas las transferencias han terminado; [failedCount] dice cuantas fallaron
class TransferProcessingOKState extends TransferState {
  const TransferProcessingOKState({
    required super.tasks,
    required super.failedCount,
    required super.finishedCount,
  }) : super(progress: 1);
}
