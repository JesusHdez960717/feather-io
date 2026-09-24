import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BucketCubit extends Cubit<BucketState>
    with GlobalEventBusCommunication<BucketState> {
  final BucketRepo _repo;
  final AuthCubit _auth;

  BucketCubit(this._repo, this._auth) : super(const BucketInitialState());

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

  Future<void> createBucket({
    required String name,
    String? description,
    int? color,
  }) async {
    await _process(
      () => _repo.createBucket(
        name: name,
        description: description,
        color: color,
        token: _auth.auth?.accessToken,
      ),
    );
  }

  Future<void> deleteBucket({required BucketModel bucket}) async {
    await _process(
      () =>
          _repo.deleteBucket(name: bucket.name, token: _auth.auth?.accessToken),
    );
  }

  ///Ejecuta una accion sobre los buckets y, si sale bien, recarga el listado
  Future<void> _process(Future<void> Function() action) async {
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
    await load();
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
