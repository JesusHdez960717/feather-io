import 'dart:js_interop';
import 'dart:typed_data';

import 'package:console/app_exporter.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web/web.dart' as web;

///Navegacion por los objetos de un bucket.
///El listado/creacion/borrado de buckets es responsabilidad de [BucketCubit].
class BrowserCubit extends Cubit<BrowserState>
    with GlobalEventBusCommunication<BrowserState> {
  final AuthCubit auth;
  final BrowserRepo repo;

  final ViewType? initialViewType;

  ///Prefijos de los que se ha subido con [goUp], el ultimo arriba.
  ///[goForward] vuelve a bajar; cualquier otra navegacion lo vacia
  final List<String> _forwardPrefixes = [];

  bool get canGoForward => _forwardPrefixes.isNotEmpty;

  BrowserCubit({required this.auth, required this.repo, this.initialViewType})
    : super(BrowserInitialState(viewType: initialViewType));

  ViewType get _viewType => switch (state) {
    BrowserSearchState(:final viewType) => viewType,
    BrowserInitialState(:final viewType) =>
      viewType ?? initialViewType ?? ViewType.list,
    _ => initialViewType ?? ViewType.list,
  };

  ///Estado sin bucket seleccionado (se muestra el listado de buckets)
  void init() {
    emit(BrowserLoadingSuccessState(viewType: _viewType));
  }

  ///Sale del bucket seleccionado
  void reset() {
    _forwardPrefixes.clear();
    init();
  }

  ///Sube un nivel; en la raiz del bucket sale al listado de buckets
  Future<void> goUp() async {
    if (state is! BrowserSearchState) return;
    final prefix = (state as BrowserSearchState).prefix;
    final parts = prefix.split('/').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) {
      reset();
      return;
    }
    parts.removeLast();
    _forwardPrefixes.add(prefix);
    await _list(prefix: parts.isEmpty ? '' : '${parts.join('/')}/');
  }

  ///Deshace el ultimo [goUp]
  Future<void> goForward() async {
    if (_forwardPrefixes.isEmpty) return;
    await _list(prefix: _forwardPrefixes.removeLast());
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

  Future<void> selectBucket({
    required BucketModel bucket,
    String? prefix,
  }) async {
    await listObjects(bucket: bucket, prefix: prefix);
  }

  Future<void> listObjects({BucketModel? bucket, String? prefix}) async {
    final current = state is BrowserSearchState
        ? state as BrowserSearchState
        : null;
    final isSameBucket =
        bucket == null || bucket.name == current?.selectedBucket?.name;
    final isSamePrefix = (prefix ?? '') == current?.prefix;
    if (!isSameBucket || !isSamePrefix) _forwardPrefixes.clear();
    await _list(bucket: bucket, prefix: prefix);
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
        ),
      );
    } catch (exc) {
      emit(
        BrowserLoadingErrorState(
          ExceptionConverter.parse(exc),
          selectedBucket: targetBucket,
          prefix: prefix ?? '',
          viewType: viewType,
        ),
      );
    }
  }

  Future<void> deleteObjects({
    required BucketModel bucket,
    required List<String> keys,
  }) async {
    await _process((currentState) async {
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
    await _process((currentState) async {
      for (final file in files) {
        final length = await file.length();
        final key = prefix.isNotEmpty ? '$prefix/${file.name}' : file.name;
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
  Future<void> _process(
    Future<void> Function(BrowserSearchState currentState) action,
  ) async {
    if (state is! BrowserSearchState) return;
    final currentState = state as BrowserSearchState;

    try {
      emit(
        BrowserProcessInProgressState(
          selectedBucket: currentState.selectedBucket,
          prefix: currentState.prefix,
          objects: currentState.objects,
          viewType: currentState.viewType,
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
        ),
      );
    }
  }

  BrowserLoadingSuccessState _loadingSuccessFrom(BrowserSearchState state) =>
      BrowserLoadingSuccessState(
        selectedBucket: state.selectedBucket,
        prefix: state.prefix,
        objects: state.objects,
        viewType: state.viewType,
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

  BrowserSearchState({
    this.selectedBucket,
    this.prefix = '',
    this.objects,
    this.viewType = ViewType.list,
  });

  BrowserSearchState copyWith({
    BucketModel? selectedBucket,
    String? prefix,
    ListObjectsModel? objects,
    ViewType? viewType,
  });
}

class BrowserLoadingInProgressState extends BrowserSearchState {
  BrowserLoadingInProgressState({
    super.selectedBucket,
    super.prefix = '',
    super.objects,
    super.viewType,
  });

  @override
  BrowserLoadingInProgressState copyWith({
    BucketModel? selectedBucket,
    String? prefix,
    ListObjectsModel? objects,
    ViewType? viewType,
  }) {
    return BrowserLoadingInProgressState(
      selectedBucket: selectedBucket ?? this.selectedBucket,
      prefix: prefix ?? this.prefix,
      objects: objects ?? this.objects,
      viewType: viewType ?? this.viewType,
    );
  }
}

class BrowserLoadingSuccessState extends BrowserSearchState {
  BrowserLoadingSuccessState({
    super.selectedBucket,
    super.prefix = '',
    super.objects,
    super.viewType,
  });

  @override
  BrowserLoadingSuccessState copyWith({
    BucketModel? selectedBucket,
    String? prefix,
    ListObjectsModel? objects,
    ViewType? viewType,
  }) {
    return BrowserLoadingSuccessState(
      selectedBucket: selectedBucket ?? this.selectedBucket,
      prefix: prefix ?? this.prefix,
      objects: objects ?? this.objects,
      viewType: viewType ?? this.viewType,
    );
  }
}

class BrowserProcessInProgressState extends BrowserSearchState {
  BrowserProcessInProgressState({
    super.selectedBucket,
    super.prefix = '',
    super.objects,
    super.viewType,
  });

  @override
  BrowserProcessInProgressState copyWith({
    BucketModel? selectedBucket,
    String? prefix,
    ListObjectsModel? objects,
    ViewType? viewType,
  }) {
    return BrowserProcessInProgressState(
      selectedBucket: selectedBucket ?? this.selectedBucket,
      prefix: prefix ?? this.prefix,
      objects: objects ?? this.objects,
      viewType: viewType ?? this.viewType,
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
  });

  @override
  BrowserLoadingErrorState copyWith({
    BucketModel? selectedBucket,
    String? prefix,
    ListObjectsModel? objects,
    ViewType? viewType,
    GlobalException? exception,
  }) {
    return BrowserLoadingErrorState(
      exception ?? this.exception,
      selectedBucket: selectedBucket ?? this.selectedBucket,
      prefix: prefix ?? this.prefix,
      objects: objects ?? this.objects,
      viewType: viewType ?? this.viewType,
    );
  }
}
