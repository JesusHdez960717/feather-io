import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BrowserCubit extends Cubit<BrowserState>
    with GlobalEventBusCommunication<BrowserState> {
  final AuthCubit auth;
  final BrowserRepo repo;

  List<BucketModel> _allBuckets = [];

  BrowserCubit({required this.auth, required this.repo})
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
          buckets: _allBuckets,
        ),
      );

      if (_allBuckets.isEmpty) {
        _allBuckets = await repo.listBuckets(
          access: auth.access,
          secret: auth.secret,
        );
      }

      emit(
        BrowserSearchOkState(
          buckets: _allBuckets,
        ),
      );
    } catch (exc) {
      emit(
        BrowserSearchErrorState(
          ExceptionConverter.parse(exc),
          buckets: _allBuckets,
        ),
      );
    }
  }

  Future<void> selectBucket({
    required BucketModel bucket,
    String? prefix,
  }) async {
    await listObjects(bucket: bucket, prefix: prefix);
  }

  Future<void> listObjects({
    BucketModel? bucket,
    String? prefix,
  }) async {
    final targetBucket = bucket ??
        (state is BrowserSearchState
            ? (state as BrowserSearchState).selectedBucket
            : null);
    if (targetBucket == null) return;

    try {
      emit(
        BrowserSearchingState(
          buckets: _allBuckets,
          selectedBucket: targetBucket,
          prefix: prefix ?? '',
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
        ),
      );
    } catch (exc) {
      emit(
        BrowserSearchErrorState(
          ExceptionConverter.parse(exc),
          buckets: _allBuckets,
          selectedBucket: targetBucket,
          prefix: prefix ?? '',
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

  BrowserSearchState({
    required this.buckets,
    this.selectedBucket,
    this.prefix = '',
    this.objects,
  });
}

class BrowserSearchingState extends BrowserSearchState {
  BrowserSearchingState({
    required super.buckets,
    super.selectedBucket,
    super.prefix = '',
    super.objects,
  });
}

class BrowserSearchOkState extends BrowserSearchState {
  BrowserSearchOkState({
    required super.buckets,
    super.selectedBucket,
    super.prefix = '',
    super.objects,
  });
}

class BrowserSearchErrorState extends BrowserSearchState {
  final GlobalException exception;

  BrowserSearchErrorState(
    this.exception, {
    required super.buckets,
    super.selectedBucket,
    super.prefix = '',
    super.objects,
  });
}
