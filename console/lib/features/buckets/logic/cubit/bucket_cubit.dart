import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BucketCubit extends Cubit<BucketState>
    with GlobalEventBusCommunication<BucketState> {
  final BucketRepo _repo;
  final AuthCubit _auth;

  BucketCubit(this._repo, this._auth) : super(const BucketInitialState()) {
    //cada seccion (explorador, Buckets) tiene su propio BucketCubit: si otro
    //cambia los buckets, este recarga su lista
    onBus<BucketChangedEvent>((event) {
      if (!identical(event.source, this)) load();
    });
  }

  ///Recarga la lista tras un cambio hecho desde esta seccion y avisa al resto
  ///(las demas listas de buckets y el explorador)
  Future<void> reloadAfterChange({
    required BucketChange change,
    required String bucketName,
    BucketModel? bucket,
  }) async {
    GlobalEventBus().fire(
      BucketChangedEvent(
        source: this,
        change: change,
        bucketName: bucketName,
        bucket: bucket,
      ),
    );
    await load();
  }

  Future<void> load() async {
    emit(BucketLoadingInProgressState(buckets: state.buckets));
    try {
      final buckets = await _repo.listBuckets(token: _auth.auth?.accessToken);
      emit(BucketLoadingSuccessState(buckets: buckets));
    } catch (e) {
      emit(
        BucketLoadingErrorState(
          ExceptionConverter.parse(e),
          buckets: state.buckets,
        ),
      );
    }
  }

  Future<void> deleteBucket({required BucketModel bucket}) async {
    await _process(
      bucket: bucket,
      change: BucketChange.deleted,
      () =>
          _repo.deleteBucket(name: bucket.name, token: _auth.auth?.accessToken),
    );
  }

  Future<void> emptyBucket({required BucketModel bucket}) async {
    await _process(
      bucket: bucket,
      change: BucketChange.emptied,
      () =>
          _repo.emptyBucket(name: bucket.name, token: _auth.auth?.accessToken),
    );
  }

  ///Ejecuta una accion sobre los buckets y, si sale bien, recarga el listado
  Future<void> _process(
    Future<void> Function() action, {
    required BucketModel bucket,
    required BucketChange change,
  }) async {
    emit(BucketProcessInProgressState(buckets: state.buckets));
    try {
      await action();
      emit(BucketProcessingOKState(buckets: state.buckets));
    } catch (e) {
      emit(
        BucketProcessingErrorState(
          ExceptionConverter.parse(e).message,
          buckets: state.buckets,
        ),
      );
      return;
    }
    await reloadAfterChange(change: change, bucketName: bucket.name);
  }
}

abstract class BucketState {
  final List<BucketModel> buckets;

  const BucketState({this.buckets = const []});
}

class BucketInitialState extends BucketState {
  const BucketInitialState();
}

//------------------------- LOADING -------------------------\\
class BucketLoadingInProgressState extends BucketState {
  const BucketLoadingInProgressState({super.buckets});
}

class BucketLoadingSuccessState extends BucketState {
  const BucketLoadingSuccessState({super.buckets});
}

class BucketLoadingErrorState extends BucketState {
  final GlobalException exception;

  const BucketLoadingErrorState(this.exception, {super.buckets});
}

//------------------------- PROCESSING -------------------------\\
class BucketProcessInProgressState extends BucketState {
  const BucketProcessInProgressState({super.buckets});
}

class BucketProcessingOKState extends BucketState {
  const BucketProcessingOKState({super.buckets});
}

class BucketProcessingErrorState extends BucketState {
  final String message;

  const BucketProcessingErrorState(this.message, {super.buckets});
}
