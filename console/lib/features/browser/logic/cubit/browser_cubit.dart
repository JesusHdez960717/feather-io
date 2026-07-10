import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BrowserCubit extends Cubit<BrowserState>
    with GlobalEventBusCommunication<BrowserState> {
  final List<int> _pageSizes = [5, 10, defaultPageSize, 50, 100];

  static const int defaultPage = 0;
  static const int defaultPageSize = 20;

  final AuthCubit auth;
  final BrowserRepo repo;

  int currentPage = defaultPage;
  int currentPageSize = defaultPageSize;
  int totalPages = 0;

  final Map<int, List<BucketModel>> bucketsPerPage = {};
  List<BucketModel> _allBuckets = [];
  String? _currentSearchQuery;

  BrowserCubit({required this.auth, required this.repo})
    : super(const BrowserInitialState());

  void reset() {
    currentPage = defaultPage;
    currentPageSize = defaultPageSize;
    totalPages = 0;
    bucketsPerPage.clear();
    _allBuckets.clear();
    _currentSearchQuery = null;

    emit(const BrowserInitialState());
  }

  Future<void> refresh() async {
    bucketsPerPage.clear();
    _allBuckets.clear();
    await init();
  }

  Future<void> init({int? page, int? pageSize, String? searchQuery}) async {
    try {
      emit(
        BrowserSearchingState(
          bucketsPerPage: bucketsPerPage,
          totalPages: totalPages,
          currentPage: currentPage,
          currentPageSize: currentPageSize,
          pageSizes: _pageSizes,
        ),
      );

      if (page != null) {
        currentPage = page;
      }

      if (pageSize != null && currentPageSize != pageSize) {
        currentPage = defaultPage;
        currentPageSize = pageSize;
        bucketsPerPage.clear();
      }

      if (searchQuery != _currentSearchQuery) {
        _currentSearchQuery = searchQuery;
        currentPage = defaultPage;
        bucketsPerPage.clear();
      }

      if (bucketsPerPage[currentPage] == null) {
        // Como el repo no soporta búsqueda/paginación nativa aún, lo manejamos localmente
        // pero manteniendo la estructura del Cubit de Users.
        if (_allBuckets.isEmpty) {
          _allBuckets = await repo.listBuckets(
            access: auth.access,
            secret: auth.secret,
          );
        }

        final filtered =
            _currentSearchQuery == null || _currentSearchQuery!.isEmpty
            ? _allBuckets
            : _allBuckets
                  .where(
                    (b) => b.name.toLowerCase().contains(
                      _currentSearchQuery!.toLowerCase(),
                    ),
                  )
                  .toList();

        totalPages = (filtered.length / currentPageSize).ceil();

        final start = currentPage * currentPageSize;
        if (start < filtered.length) {
          bucketsPerPage[currentPage] = filtered
              .skip(start)
              .take(currentPageSize)
              .toList();
        } else {
          bucketsPerPage[currentPage] = [];
        }
      }

      emit(
        BrowserSearchOkState(
          bucketsPerPage: bucketsPerPage,
          totalPages: totalPages,
          currentPage: currentPage,
          currentPageSize: currentPageSize,
          pageSizes: _pageSizes,
        ),
      );
    } catch (exc) {
      emit(
        BrowserSearchErrorState(
          ExceptionConverter.parse(exc),
          bucketsPerPage: bucketsPerPage,
          totalPages: totalPages,
          currentPage: currentPage,
          currentPageSize: currentPageSize,
          pageSizes: _pageSizes,
        ),
      );
    }
  }

  Future<void> applySearch({required String query}) async {
    bucketsPerPage.clear();
    await init(page: defaultPage, searchQuery: query);
  }
}

abstract class BrowserState {
  const BrowserState();
}

class BrowserInitialState extends BrowserState {
  const BrowserInitialState();
}

//------------------------- SEARCH -------------------------\\
abstract class BrowserSearchState extends BrowserState {
  final int totalPages;
  final int currentPage;
  final int currentPageSize;
  final Map<int, List<BucketModel>> bucketsPerPage;
  final List<int> pageSizes;

  BrowserSearchState({
    required this.totalPages,
    required this.bucketsPerPage,
    required this.currentPage,
    required this.currentPageSize,
    required this.pageSizes,
  });
}

class BrowserSearchingState extends BrowserSearchState {
  BrowserSearchingState({
    required super.totalPages,
    required super.bucketsPerPage,
    required super.currentPage,
    required super.currentPageSize,
    required super.pageSizes,
  });
}

class BrowserSearchOkState extends BrowserSearchState {
  BrowserSearchOkState({
    required super.totalPages,
    required super.bucketsPerPage,
    required super.currentPage,
    required super.currentPageSize,
    required super.pageSizes,
  });
}

class BrowserSearchErrorState extends BrowserSearchState {
  final GlobalException exception;

  BrowserSearchErrorState(
    this.exception, {
    required super.totalPages,
    required super.bucketsPerPage,
    required super.currentPage,
    required super.currentPageSize,
    required super.pageSizes,
  });
}
