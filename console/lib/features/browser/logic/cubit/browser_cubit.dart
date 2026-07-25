import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BrowserCubit extends Cubit<BrowserState>
    with GlobalEventBusCommunication<BrowserState> {
  final AuthCubit auth;
  final BrowserRepo repo;

  List<BucketModel> _allBuckets = [];

  final ViewType? initialViewType;

  BrowserCubit({required this.auth, required this.repo, this.initialViewType})
    : super(const BrowserInitialState());

  void reset() {
    _allBuckets.clear();
    emit(const BrowserInitialState());
  }

  Future<void> refresh() async {
    _allBuckets.clear();
    await init();
  }

  Future<void> init() async {
    try {
      emit(
        BrowserSearchingState(
          buckets: [],
          viewType:
              initialViewType ??
              (state is BrowserSearchState
                  ? (state as BrowserSearchState).viewType
                  : ViewType.list),
        ),
      );

      _allBuckets = await repo.listBuckets(
        access: auth.access,
        secret: auth.secret,
      );

      emit(
        BrowserSearchOkState(
          buckets: _allBuckets,
          viewType:
              initialViewType ??
              (state is BrowserSearchState
                  ? (state as BrowserSearchState).viewType
                  : ViewType.list),
        ),
      );
    } catch (exc) {
      emit(
        BrowserSearchErrorState(
          ExceptionConverter.parse(exc),
          buckets: _allBuckets,
          viewType:
              initialViewType ??
              (state is BrowserSearchState
                  ? (state as BrowserSearchState).viewType
                  : ViewType.list),
        ),
      );
    }
  }

  void changeViewType(ViewType viewType) {
    if (state is BrowserSearchState) {
      final currentState = state as BrowserSearchState;
      if (currentState.viewType == viewType) return;
      emit(currentState.copyWith(viewType: viewType));
    }
  }

  Future<void> selectBucket({
    required BucketModel bucket,
    String? prefix,
  }) async {
    await listObjects(bucket: bucket, prefix: prefix);
  }

  Future<void> listObjects({BucketModel? bucket, String? prefix}) async {
    final targetBucket =
        bucket ??
        (state is BrowserSearchState
            ? (state as BrowserSearchState).selectedBucket
            : null);
    if (targetBucket == null) return;

    final viewType = (state as BrowserSearchState).viewType;

    try {
      emit(
        BrowserSearchingState(
          buckets: _allBuckets,
          selectedBucket: targetBucket,
          prefix: prefix ?? '',
          viewType: viewType,
        ),
      );

      final objects = await repo.listObjects(
        access: auth.access,
        secret: auth.secret,
        bucket: targetBucket.name,
        prefix: prefix,
        delimiter: '/',
      );

      emit(
        BrowserSearchOkState(
          buckets: _allBuckets,
          selectedBucket: targetBucket,
          prefix: prefix ?? '',
          objects: objects,
          viewType: viewType,
        ),
      );
    } catch (exc) {
      emit(
        BrowserSearchErrorState(
          ExceptionConverter.parse(exc),
          buckets: _allBuckets,
          selectedBucket: targetBucket,
          prefix: prefix ?? '',
          viewType: viewType,
        ),
      );
    }
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
  final List<BucketModel> buckets;

  final BucketModel? selectedBucket;
  final String prefix;
  final String delimiter = '/';
  final ListObjectsModel? objects;
  final ViewType viewType;

  BrowserSearchState({
    required this.buckets,
    this.selectedBucket,
    this.prefix = '',
    this.objects,
    this.viewType = ViewType.list,
  });

  BrowserSearchState copyWith({
    List<BucketModel>? buckets,
    BucketModel? selectedBucket,
    String? prefix,
    ListObjectsModel? objects,
    ViewType? viewType,
  });
}

class BrowserSearchingState extends BrowserSearchState {
  BrowserSearchingState({
    required super.buckets,
    super.selectedBucket,
    super.prefix = '',
    super.objects,
    super.viewType,
  });

  @override
  BrowserSearchingState copyWith({
    List<BucketModel>? buckets,
    BucketModel? selectedBucket,
    String? prefix,
    ListObjectsModel? objects,
    ViewType? viewType,
  }) {
    return BrowserSearchingState(
      buckets: buckets ?? this.buckets,
      selectedBucket: selectedBucket ?? this.selectedBucket,
      prefix: prefix ?? this.prefix,
      objects: objects ?? this.objects,
      viewType: viewType ?? this.viewType,
    );
  }
}

class BrowserSearchOkState extends BrowserSearchState {
  BrowserSearchOkState({
    required super.buckets,
    super.selectedBucket,
    super.prefix = '',
    super.objects,
    super.viewType,
  });

  @override
  BrowserSearchOkState copyWith({
    List<BucketModel>? buckets,
    BucketModel? selectedBucket,
    String? prefix,
    ListObjectsModel? objects,
    ViewType? viewType,
  }) {
    return BrowserSearchOkState(
      buckets: buckets ?? this.buckets,
      selectedBucket: selectedBucket ?? this.selectedBucket,
      prefix: prefix ?? this.prefix,
      objects: objects ?? this.objects,
      viewType: viewType ?? this.viewType,
    );
  }
}

class BrowserSearchErrorState extends BrowserSearchState {
  final GlobalException exception;

  BrowserSearchErrorState(
    this.exception, {
    required super.buckets,
    super.selectedBucket,
    super.prefix = '',
    super.objects,
    super.viewType,
  });

  @override
  BrowserSearchErrorState copyWith({
    List<BucketModel>? buckets,
    BucketModel? selectedBucket,
    String? prefix,
    ListObjectsModel? objects,
    ViewType? viewType,
    GlobalException? exception,
  }) {
    return BrowserSearchErrorState(
      exception ?? this.exception,
      buckets: buckets ?? this.buckets,
      selectedBucket: selectedBucket ?? this.selectedBucket,
      prefix: prefix ?? this.prefix,
      objects: objects ?? this.objects,
      viewType: viewType ?? this.viewType,
    );
  }
}
