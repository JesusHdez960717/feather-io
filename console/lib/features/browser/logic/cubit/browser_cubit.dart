import 'dart:js_interop';
import 'dart:math';
import 'dart:typed_data';

import 'package:console/app_exporter.dart';
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

  ///Elementos por pagina; se mantiene al cambiar de carpeta
  int _pageSize = BrowserPagination.defaultPageSize;

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
        _list(prefix: current.prefix, pageIndex: current.pageIndex);
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

  ///Vuelve a pedir la carpeta que se muestra, hasta la pagina actual
  Future<void> refresh() async {
    if (state is! BrowserSearchState) return;
    final current = state as BrowserSearchState;
    await _list(prefix: current.prefix, pageIndex: current.pageIndex);
  }

  ///Pagina siguiente: la guardada si ya se cargo, si no se pide al servicio
  Future<void> nextPage() async {
    if (state is! BrowserSearchState) return;
    final current = state as BrowserSearchState;
    if (!current.canGoNext) return;
    final next = current.pageIndex + 1;
    if (next < current.pages.length) {
      emit(_loadingSuccessFrom(current, pageIndex: next));
      return;
    }
    final bucket = current.selectedBucket;
    if (bucket == null) return;
    try {
      emit(_loadingInProgressFrom(current));
      final page = await repo.listObjects(
        token: auth.auth?.accessToken,
        bucket: bucket.name,
        prefix: current.prefix,
        delimiter: current.delimiter,
        maxKeys: current.pageSize,
        continuationToken: current.objects?.nextContinuationToken,
      );
      emit(
        _loadingSuccessFrom(
          current,
          pages: [...current.pages, page],
          pageIndex: next,
        ),
      );
    } catch (exc) {
      emit(_loadingErrorFrom(current, exc));
    }
  }

  ///Pagina anterior, que siempre esta ya cargada
  void previousPage() {
    if (state is! BrowserSearchState) return;
    final current = state as BrowserSearchState;
    if (!current.canGoPrevious) return;
    emit(_loadingSuccessFrom(current, pageIndex: current.pageIndex - 1));
  }

  ///Cambia los elementos por pagina y vuelve a la primera
  Future<void> changePageSize(int pageSize) async {
    if (state is! BrowserSearchState || pageSize == _pageSize) return;
    _pageSize = pageSize;
    await _list(prefix: (state as BrowserSearchState).prefix);
  }

  ///Carga las paginas de [prefix] desde la primera hasta [pageIndex] (o hasta
  ///la ultima que haya) y muestra [pageIndex]. Mientras carga sigue viendose
  ///lo anterior si es la misma carpeta
  Future<void> _list({
    BucketModel? bucket,
    String? prefix,
    int pageIndex = 0,
  }) async {
    final current = state is BrowserSearchState
        ? state as BrowserSearchState
        : null;
    final targetBucket = bucket ?? current?.selectedBucket;
    if (targetBucket == null) return;
    final targetPrefix = prefix ?? '';

    final samePlace =
        current?.selectedBucket?.name == targetBucket.name &&
        current?.prefix == targetPrefix;
    final previousPages = samePlace ? current!.pages : <ListObjectsModel>[];
    final previousIndex = samePlace ? current!.pageIndex : 0;
    final viewType = _viewType;

    try {
      emit(
        BrowserLoadingInProgressState(
          selectedBucket: targetBucket,
          prefix: targetPrefix,
          pages: previousPages,
          pageIndex: previousIndex,
          pageSize: _pageSize,
          viewType: viewType,
          canGoForward: _canGoForward,
        ),
      );

      final pages = <ListObjectsModel>[];
      String? continuationToken;
      do {
        final page = await repo.listObjects(
          token: auth.auth?.accessToken,
          bucket: targetBucket.name,
          prefix: targetPrefix,
          delimiter: '/',
          maxKeys: _pageSize,
          continuationToken: continuationToken,
        );
        pages.add(page);
        continuationToken = page.nextContinuationToken;
      } while (pages.length <= pageIndex && continuationToken != null);

      emit(
        BrowserLoadingSuccessState(
          selectedBucket: targetBucket,
          prefix: targetPrefix,
          pages: pages,
          pageIndex: min(pageIndex, pages.length - 1),
          pageSize: _pageSize,
          viewType: viewType,
          canGoForward: _canGoForward,
        ),
      );
    } catch (exc) {
      emit(
        BrowserLoadingErrorState(
          ExceptionConverter.parse(exc),
          selectedBucket: targetBucket,
          prefix: targetPrefix,
          pages: previousPages,
          pageIndex: previousIndex,
          pageSize: _pageSize,
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

      await _list(
        bucket: bucket,
        prefix: currentState.prefix,
        pageIndex: currentState.pageIndex,
      );
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
          pages: currentState.pages,
          pageIndex: currentState.pageIndex,
          pageSize: currentState.pageSize,
          viewType: currentState.viewType,
          canGoForward: _canGoForward,
        ),
      );
      await action(currentState);
    } catch (exc) {
      emit(_loadingErrorFrom(currentState, exc));
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

  BrowserLoadingSuccessState _loadingSuccessFrom(
    BrowserSearchState state, {
    List<ListObjectsModel>? pages,
    int? pageIndex,
  }) => BrowserLoadingSuccessState(
    selectedBucket: state.selectedBucket,
    prefix: state.prefix,
    pages: pages ?? state.pages,
    pageIndex: pageIndex ?? state.pageIndex,
    pageSize: state.pageSize,
    viewType: state.viewType,
    canGoForward: state.canGoForward,
  );

  BrowserLoadingInProgressState _loadingInProgressFrom(
    BrowserSearchState state,
  ) => BrowserLoadingInProgressState(
    selectedBucket: state.selectedBucket,
    prefix: state.prefix,
    pages: state.pages,
    pageIndex: state.pageIndex,
    pageSize: state.pageSize,
    viewType: state.viewType,
    canGoForward: state.canGoForward,
  );

  BrowserLoadingErrorState _loadingErrorFrom(
    BrowserSearchState state,
    Object exc,
  ) => BrowserLoadingErrorState(
    ExceptionConverter.parse(exc),
    selectedBucket: state.selectedBucket,
    prefix: state.prefix,
    pages: state.pages,
    pageIndex: state.pageIndex,
    pageSize: state.pageSize,
    viewType: state.viewType,
    canGoForward: _canGoForward,
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

  ///Paginas de la carpeta ya cargadas, seguidas desde la primera
  final List<ListObjectsModel> pages;

  ///Pagina que se muestra, dentro de [pages]
  final int pageIndex;

  ///Elementos por pagina
  final int pageSize;
  final ViewType viewType;

  ///Hay un *subir un nivel* que *adelante* puede deshacer
  final bool canGoForward;

  BrowserSearchState({
    this.selectedBucket,
    this.prefix = '',
    this.pages = const [],
    this.pageIndex = 0,
    this.pageSize = BrowserPagination.defaultPageSize,
    this.viewType = ViewType.list,
    this.canGoForward = false,
  });

  ///La pagina que se muestra
  ListObjectsModel? get objects =>
      pageIndex < pages.length ? pages[pageIndex] : null;

  ///Paginas de la carpeta segun el total que da el servicio
  int get totalPages {
    final total = objects?.totalKeys ?? 0;
    return max(1, (total / pageSize).ceil());
  }

  bool get canGoPrevious => pageIndex > 0;

  bool get canGoNext =>
      pageIndex + 1 < pages.length || (objects?.isTruncated ?? false);

  ///Objetos de todas las paginas cargadas (para buscar y filtrar en ellas)
  List<BrowserObjectModel> get loadedObjects => [
    for (final page in pages) ...page.objects,
  ];

  ///Carpetas de todas las paginas cargadas
  List<String> get loadedPrefixes => [
    for (final page in pages) ...page.commonPrefixes,
  ];

  BrowserSearchState copyWith({
    BucketModel? selectedBucket,
    String? prefix,
    List<ListObjectsModel>? pages,
    int? pageIndex,
    int? pageSize,
    ViewType? viewType,
    bool? canGoForward,
  });
}

class BrowserLoadingInProgressState extends BrowserSearchState {
  BrowserLoadingInProgressState({
    super.selectedBucket,
    super.prefix = '',
    super.pages,
    super.pageIndex,
    super.pageSize,
    super.viewType,
    super.canGoForward,
  });

  @override
  BrowserLoadingInProgressState copyWith({
    BucketModel? selectedBucket,
    String? prefix,
    List<ListObjectsModel>? pages,
    int? pageIndex,
    int? pageSize,
    ViewType? viewType,
    bool? canGoForward,
  }) {
    return BrowserLoadingInProgressState(
      selectedBucket: selectedBucket ?? this.selectedBucket,
      prefix: prefix ?? this.prefix,
      pages: pages ?? this.pages,
      pageIndex: pageIndex ?? this.pageIndex,
      pageSize: pageSize ?? this.pageSize,
      viewType: viewType ?? this.viewType,
      canGoForward: canGoForward ?? this.canGoForward,
    );
  }
}

class BrowserLoadingSuccessState extends BrowserSearchState {
  BrowserLoadingSuccessState({
    super.selectedBucket,
    super.prefix = '',
    super.pages,
    super.pageIndex,
    super.pageSize,
    super.viewType,
    super.canGoForward,
  });

  @override
  BrowserLoadingSuccessState copyWith({
    BucketModel? selectedBucket,
    String? prefix,
    List<ListObjectsModel>? pages,
    int? pageIndex,
    int? pageSize,
    ViewType? viewType,
    bool? canGoForward,
  }) {
    return BrowserLoadingSuccessState(
      selectedBucket: selectedBucket ?? this.selectedBucket,
      prefix: prefix ?? this.prefix,
      pages: pages ?? this.pages,
      pageIndex: pageIndex ?? this.pageIndex,
      pageSize: pageSize ?? this.pageSize,
      viewType: viewType ?? this.viewType,
      canGoForward: canGoForward ?? this.canGoForward,
    );
  }
}

class BrowserProcessInProgressState extends BrowserSearchState {
  BrowserProcessInProgressState({
    super.selectedBucket,
    super.prefix = '',
    super.pages,
    super.pageIndex,
    super.pageSize,
    super.viewType,
    super.canGoForward,
  });

  @override
  BrowserProcessInProgressState copyWith({
    BucketModel? selectedBucket,
    String? prefix,
    List<ListObjectsModel>? pages,
    int? pageIndex,
    int? pageSize,
    ViewType? viewType,
    bool? canGoForward,
  }) {
    return BrowserProcessInProgressState(
      selectedBucket: selectedBucket ?? this.selectedBucket,
      prefix: prefix ?? this.prefix,
      pages: pages ?? this.pages,
      pageIndex: pageIndex ?? this.pageIndex,
      pageSize: pageSize ?? this.pageSize,
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
    super.pages,
    super.pageIndex,
    super.pageSize,
    super.viewType,
    super.canGoForward,
  });

  @override
  BrowserLoadingErrorState copyWith({
    BucketModel? selectedBucket,
    String? prefix,
    List<ListObjectsModel>? pages,
    int? pageIndex,
    int? pageSize,
    ViewType? viewType,
    bool? canGoForward,
    GlobalException? exception,
  }) {
    return BrowserLoadingErrorState(
      exception ?? this.exception,
      selectedBucket: selectedBucket ?? this.selectedBucket,
      prefix: prefix ?? this.prefix,
      pages: pages ?? this.pages,
      pageIndex: pageIndex ?? this.pageIndex,
      pageSize: pageSize ?? this.pageSize,
      viewType: viewType ?? this.viewType,
      canGoForward: canGoForward ?? this.canGoForward,
    );
  }
}
