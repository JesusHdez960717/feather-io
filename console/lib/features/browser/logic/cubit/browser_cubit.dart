import 'dart:js_interop';
import 'dart:typed_data';

import 'package:console/app_exporter.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web/web.dart' as web;

///Navegacion por los objetos de un bucket.
///El listado/creacion/borrado de buckets es responsabilidad de [BucketCubit].
///
///El bucket y la carpeta abiertos vienen de la URL: la pantalla llama a [open]
///cuando cambia, y [goUp]/[goForward] solo calculan a donde navegar
class BrowserCubit extends Cubit<BrowserState>
    with GlobalEventBusCommunication<BrowserState> {
  final AuthCubit auth;
  final BrowserRepo repo;

  final ViewType? initialViewType;

  ///Prefijos de los que se ha subido con [goUp], el ultimo arriba.
  ///[goForward] vuelve a bajar; cualquier otra navegacion lo vacia
  final List<String> _forwardPrefixes = [];

  ///El proximo [open] viene de [goUp]/[goForward] y no debe vaciar [_forwardPrefixes]
  bool _historyNavigation = false;

  bool get _canGoForward => _forwardPrefixes.isNotEmpty;

  BrowserCubit({required this.auth, required this.repo, this.initialViewType})
    : super(BrowserInitialState(viewType: initialViewType)) {
    onBus<BucketChangedEvent>(_onBucketChanged);
  }

  ///Mantiene al dia el bucket abierto si otra seccion lo cambia. Si lo borran,
  ///la pantalla ve que ya no esta en la lista de buckets y lo dice
  void _onBucketChanged(BucketChangedEvent event) {
    if (identical(event.source, this)) return;
    final current = state is BrowserSearchState
        ? state as BrowserSearchState
        : null;
    final selected = current?.selectedBucket;
    if (current == null || selected?.name != event.bucketName) return;

    switch (event.change) {
      case BucketChange.emptied:
      case BucketChange.objectsChanged:
        _list(prefix: current.prefix);
      case BucketChange.updated:
        final bucket = event.bucket;
        if (bucket != null) emit(current.copyWith(selectedBucket: bucket));
      case BucketChange.created:
      case BucketChange.deleted:
        break;
    }
  }

  ViewType get _viewType => switch (state) {
    BrowserSearchState(:final viewType) => viewType,
    BrowserInitialState(:final viewType) =>
      viewType ?? initialViewType ?? ViewType.list,
    _ => initialViewType ?? ViewType.list,
  };

  ///Estado sin bucket seleccionado (se muestra el listado de buckets)
  void init() {
    _forwardPrefixes.clear();
    emit(BrowserLoadingSuccessState(viewType: _viewType));
  }

  ///Carpeta a la que lleva *subir un nivel*, o null en la raiz del bucket
  ///(se sale al listado de buckets). La recuerda para que [goForward] vuelva
  String? goUp() {
    if (state is! BrowserSearchState) return null;
    final prefix = (state as BrowserSearchState).prefix;
    final parts = prefix.split('/').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return null;
    parts.removeLast();
    _forwardPrefixes.add(prefix);
    _historyNavigation = true;
    return parts.isEmpty ? '' : '${parts.join('/')}/';
  }

  ///Carpeta del ultimo [goUp], o null si no hay a donde volver
  String? goForward() {
    if (_forwardPrefixes.isEmpty) return null;
    _historyNavigation = true;
    return _forwardPrefixes.removeLast();
  }

  void changeViewType(ViewType viewType) {
    if (state is BrowserSearchState) {
      final currentState = state as BrowserSearchState;
      if (currentState.viewType == viewType) return;
      emit(currentState.copyWith(viewType: viewType));
    } else if (state is BrowserInitialState) {
      emit(BrowserInitialState(viewType: viewType));
    }
  }

  ///Abre [prefix] de [bucket]; no hace nada si ya es lo que se muestra
  Future<void> open({
    required BucketModel bucket,
    required String prefix,
  }) async {
    final current = state is BrowserSearchState
        ? state as BrowserSearchState
        : null;
    final isShown =
        current?.selectedBucket?.name == bucket.name &&
        current?.prefix == prefix;
    final fromHistory = _historyNavigation;
    _historyNavigation = false;
    if (isShown) return;
    if (!fromHistory) _forwardPrefixes.clear();
    await _list(bucket: bucket, prefix: prefix);
  }

  ///Vuelve a pedir la carpeta que se muestra
  Future<void> refresh() async {
    if (state is! BrowserSearchState) return;
    await _list(prefix: (state as BrowserSearchState).prefix);
  }

  Future<void> _list({BucketModel? bucket, String? prefix}) async {
    final targetBucket =
        bucket ??
        (state is BrowserSearchState
            ? (state as BrowserSearchState).selectedBucket
            : null);
    if (targetBucket == null) return;

    final viewType = _viewType;

    try {
      emit(
        BrowserLoadingInProgressState(
          selectedBucket: targetBucket,
          prefix: prefix ?? '',
          viewType: viewType,
          canGoForward: _canGoForward,
        ),
      );

      final objects = await repo.listObjects(
        token: auth.auth?.accessToken,
        bucket: targetBucket.name,
        prefix: prefix,
        delimiter: '/',
      );

      emit(
        BrowserLoadingSuccessState(
          selectedBucket: targetBucket,
          prefix: prefix ?? '',
          objects: objects,
          viewType: viewType,
          canGoForward: _canGoForward,
        ),
      );
    } catch (exc) {
      emit(
        BrowserLoadingErrorState(
          ExceptionConverter.parse(exc),
          selectedBucket: targetBucket,
          prefix: prefix ?? '',
          viewType: viewType,
          canGoForward: _canGoForward,
        ),
      );
    }
  }

  Future<void> deleteObjects({
    required BucketModel bucket,
    required List<String> keys,
  }) async {
    await _process(changedBucket: bucket, (currentState) async {
      await repo.deleteObjects(
        token: auth.auth?.accessToken,
        bucket: bucket.name,
        keys: keys,
      );

      await _list(bucket: bucket, prefix: currentState.prefix);
    });
  }

  Future<void> uploadFiles({
    required BucketModel bucket,
    required String prefix,
    required List<XFile> files,
  }) async {
    await _process(changedBucket: bucket, (currentState) async {
      for (final file in files) {
        final length = await file.length();
        //el prefijo de una carpeta ya termina en '/' (p. ej. 'fotos/')
        final key = prefix.isEmpty || prefix.endsWith('/')
            ? '$prefix${file.name}'
            : '$prefix/${file.name}';
        await repo.uploadObject(
          token: auth.auth?.accessToken,
          bucket: bucket.name,
          key: key,
          data: file.openRead(),
          length: length,
        );
      }

      await _list(bucket: bucket, prefix: currentState.prefix);
    });
  }

  Future<void> download({
    required BucketModel bucket,
    required List<String> keys,
    String? zipName,
  }) async {
    await _process((currentState) async {
      final bytes = await repo.download(
        token: auth.auth?.accessToken,
        bucket: bucket.name,
        keys: keys,
      );

      final String fileName;
      if (zipName != null) {
        fileName = zipName.endsWith('.zip') ? zipName : '$zipName.zip';
      } else if (keys.length == 1) {
        final name = keys.first.split('/').where((s) => s.isNotEmpty).last;
        fileName = '$name.zip';
      } else {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        fileName = 'download_$timestamp.zip';
      }

      final blob = web.Blob([Uint8List.fromList(bytes).toJS].toJS);
      final url = web.URL.createObjectURL(blob);
      final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
      anchor.href = url;
      anchor.download = fileName;
      anchor.click();
      web.URL.revokeObjectURL(url);

      emit(_loadingSuccessFrom(currentState));
    });
  }

  Future<void> viewObject({
    required BucketModel bucket,
    required String key,
  }) async {
    await _process((currentState) async {
      final data = await repo.getObject(
        token: auth.auth?.accessToken,
        bucket: bucket.name,
        key: key,
      );

      final blob = web.Blob(
        [Uint8List.fromList(data.bytes).toJS].toJS,
        web.BlobPropertyBag(
          type: data.contentType ?? 'application/octet-stream',
        ),
      );
      final url = web.URL.createObjectURL(blob);

      web.window.open(url, '_blank');

      emit(_loadingSuccessFrom(currentState));
    });
  }

  ///Emite [BrowserProcessInProgressState], ejecuta la accion y, si falla,
  ///emite [BrowserLoadingErrorState] conservando el contexto actual.
  ///Si la accion sube o borra objetos de [changedBucket], avisa al resto al
  ///terminar, aunque falle: una subida de varios ficheros puede fallar a medias
  Future<void> _process(
    Future<void> Function(BrowserSearchState currentState) action, {
    BucketModel? changedBucket,
  }) async {
    if (state is! BrowserSearchState) return;
    final currentState = state as BrowserSearchState;

    try {
      emit(
        BrowserProcessInProgressState(
          selectedBucket: currentState.selectedBucket,
          prefix: currentState.prefix,
          objects: currentState.objects,
          viewType: currentState.viewType,
          canGoForward: _canGoForward,
        ),
      );
      await action(currentState);
    } catch (exc) {
      emit(
        BrowserLoadingErrorState(
          ExceptionConverter.parse(exc),
          selectedBucket: currentState.selectedBucket,
          prefix: currentState.prefix,
          objects: currentState.objects,
          viewType: currentState.viewType,
          canGoForward: _canGoForward,
        ),
      );
    } finally {
      if (changedBucket != null) {
        GlobalEventBus().fire(
          BucketChangedEvent(
            source: this,
            change: BucketChange.objectsChanged,
            bucketName: changedBucket.name,
          ),
        );
      }
    }
  }

  BrowserLoadingSuccessState _loadingSuccessFrom(BrowserSearchState state) =>
      BrowserLoadingSuccessState(
        selectedBucket: state.selectedBucket,
        prefix: state.prefix,
        objects: state.objects,
        viewType: state.viewType,
        canGoForward: state.canGoForward,
      );
}

abstract class BrowserState {
  const BrowserState();
}

class BrowserInitialState extends BrowserState {
  final ViewType? viewType;

  const BrowserInitialState({this.viewType});
}

//------------------------- SEARCH -------------------------\\
abstract class BrowserSearchState extends BrowserState {
  final BucketModel? selectedBucket;
  final String prefix;
  final String delimiter = '/';
  final ListObjectsModel? objects;
  final ViewType viewType;

  ///Hay un *subir un nivel* que *adelante* puede deshacer
  final bool canGoForward;

  BrowserSearchState({
    this.selectedBucket,
    this.prefix = '',
    this.objects,
    this.viewType = ViewType.list,
    this.canGoForward = false,
  });

  BrowserSearchState copyWith({
    BucketModel? selectedBucket,
    String? prefix,
    ListObjectsModel? objects,
    ViewType? viewType,
    bool? canGoForward,
  });
}

class BrowserLoadingInProgressState extends BrowserSearchState {
  BrowserLoadingInProgressState({
    super.selectedBucket,
    super.prefix = '',
    super.objects,
    super.viewType,
    super.canGoForward,
  });

  @override
  BrowserLoadingInProgressState copyWith({
    BucketModel? selectedBucket,
    String? prefix,
    ListObjectsModel? objects,
    ViewType? viewType,
    bool? canGoForward,
  }) {
    return BrowserLoadingInProgressState(
      selectedBucket: selectedBucket ?? this.selectedBucket,
      prefix: prefix ?? this.prefix,
      objects: objects ?? this.objects,
      viewType: viewType ?? this.viewType,
      canGoForward: canGoForward ?? this.canGoForward,
    );
  }
}

class BrowserLoadingSuccessState extends BrowserSearchState {
  BrowserLoadingSuccessState({
    super.selectedBucket,
    super.prefix = '',
    super.objects,
    super.viewType,
    super.canGoForward,
  });

  @override
  BrowserLoadingSuccessState copyWith({
    BucketModel? selectedBucket,
    String? prefix,
    ListObjectsModel? objects,
    ViewType? viewType,
    bool? canGoForward,
  }) {
    return BrowserLoadingSuccessState(
      selectedBucket: selectedBucket ?? this.selectedBucket,
      prefix: prefix ?? this.prefix,
      objects: objects ?? this.objects,
      viewType: viewType ?? this.viewType,
      canGoForward: canGoForward ?? this.canGoForward,
    );
  }
}

class BrowserProcessInProgressState extends BrowserSearchState {
  BrowserProcessInProgressState({
    super.selectedBucket,
    super.prefix = '',
    super.objects,
    super.viewType,
    super.canGoForward,
  });

  @override
  BrowserProcessInProgressState copyWith({
    BucketModel? selectedBucket,
    String? prefix,
    ListObjectsModel? objects,
    ViewType? viewType,
    bool? canGoForward,
  }) {
    return BrowserProcessInProgressState(
      selectedBucket: selectedBucket ?? this.selectedBucket,
      prefix: prefix ?? this.prefix,
      objects: objects ?? this.objects,
      viewType: viewType ?? this.viewType,
      canGoForward: canGoForward ?? this.canGoForward,
    );
  }
}

class BrowserLoadingErrorState extends BrowserSearchState {
  final GlobalException exception;

  BrowserLoadingErrorState(
    this.exception, {
    super.selectedBucket,
    super.prefix = '',
    super.objects,
    super.viewType,
    super.canGoForward,
  });

  @override
  BrowserLoadingErrorState copyWith({
    BucketModel? selectedBucket,
    String? prefix,
    ListObjectsModel? objects,
    ViewType? viewType,
    bool? canGoForward,
    GlobalException? exception,
  }) {
    return BrowserLoadingErrorState(
      exception ?? this.exception,
      selectedBucket: selectedBucket ?? this.selectedBucket,
      prefix: prefix ?? this.prefix,
      objects: objects ?? this.objects,
      viewType: viewType ?? this.viewType,
      canGoForward: canGoForward ?? this.canGoForward,
    );
  }
}
