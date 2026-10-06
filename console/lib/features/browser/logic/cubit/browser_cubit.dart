import 'dart:math';

import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Navigation through the objects of a bucket.
/// Listing, creating and deleting buckets is [BucketCubit]'s job.
///
/// The open bucket and folder come from the URL: the screen calls [open] when
/// it changes, and [goUp]/[goForward] only work out where to navigate
class BrowserCubit extends Cubit<BrowserState>
    with GlobalEventBusCommunication<BrowserState> {
  final AuthCubit auth;
  final BrowserRepo repo;

  final ViewType? initialViewType;

  /// Prefixes left with [goUp], the last one on top.
  /// [goForward] goes back down; any other navigation clears it
  final List<String> _forwardPrefixes = [];

  /// The next [open] comes from [goUp]/[goForward] and must not clear [_forwardPrefixes]
  bool _historyNavigation = false;

  bool get _canGoForward => _forwardPrefixes.isNotEmpty;

  /// Items per page; kept when the folder changes
  int _pageSize = BrowserPagination.defaultPageSize;

  BrowserCubit({required this.auth, required this.repo, this.initialViewType})
    : super(BrowserInitialState(viewType: initialViewType)) {
    onBus<BucketChangedEvent>(_onBucketChanged);
  }

  /// Keeps the open bucket up to date if another section changes it. If it is
  /// deleted, the screen sees it is no longer in the bucket list and says so
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

  /// State without a selected bucket (the bucket list is shown)
  void init() {
    _forwardPrefixes.clear();
    emit(BrowserLoadingSuccessState(viewType: _viewType));
  }

  /// Folder *up one level* leads to, or null at the bucket root (it goes back
  /// to the bucket list). It is remembered so [goForward] can come back
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

  /// Folder of the last [goUp], or null if there is nowhere to go back to
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

  /// Opens [prefix] of [bucket]; does nothing if that is already shown
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

  /// Requests the shown folder again, up to the current page
  Future<void> refresh() async {
    if (state is! BrowserSearchState) return;
    final current = state as BrowserSearchState;
    await _list(prefix: current.prefix, pageIndex: current.pageIndex);
  }

  /// Next page: the stored one if already loaded, otherwise requested from the service
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

  /// Previous page, which is always loaded already
  void previousPage() {
    if (state is! BrowserSearchState) return;
    final current = state as BrowserSearchState;
    if (!current.canGoPrevious) return;
    emit(_loadingSuccessFrom(current, pageIndex: current.pageIndex - 1));
  }

  /// Changes the items per page and goes back to the first one
  Future<void> changePageSize(int pageSize) async {
    if (state is! BrowserSearchState || pageSize == _pageSize) return;
    _pageSize = pageSize;
    await _list(prefix: (state as BrowserSearchState).prefix);
  }

  /// Loads the pages of [prefix] from the first up to [pageIndex] (or up to the
  /// last one there is) and shows [pageIndex]. While loading, the previous
  /// content stays visible if it is the same folder
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

      BrowserWindow.openBytes(data.bytes, contentType: data.contentType);

      emit(_loadingSuccessFrom(currentState));
    });
  }

  /// Emits [BrowserProcessInProgressState], runs the action and, if it fails,
  /// emits [BrowserLoadingErrorState] keeping the current context.
  /// If the action uploads or deletes objects of [changedBucket], it notifies the
  /// others when done, even on failure: an upload of several files can fail halfway
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

  /// Pages of the folder already loaded, contiguous from the first
  final List<ListObjectsModel> pages;

  /// Page shown, within [pages]
  final int pageIndex;

  /// Items per page
  final int pageSize;
  final ViewType viewType;

  /// There is an *up one level* that *forward* can undo
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

  /// The page shown
  ListObjectsModel? get objects =>
      pageIndex < pages.length ? pages[pageIndex] : null;

  /// Pages of the folder according to the total the service gives
  int get totalPages {
    final total = objects?.totalKeys ?? 0;
    return max(1, (total / pageSize).ceil());
  }

  bool get canGoPrevious => pageIndex > 0;

  bool get canGoNext =>
      pageIndex + 1 < pages.length || (objects?.isTruncated ?? false);

  /// Objects of every loaded page (to search and filter them)
  List<BrowserObjectModel> get loadedObjects => [
    for (final page in pages) ...page.objects,
  ];

  /// Folders of every loaded page
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
