import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BucketCubit extends Cubit<BucketState>
    with GlobalEventBusCommunication<BucketState> {
  final BucketRepo _repo;
  final AuthCubit _auth;

  BucketCubit(this._repo, this._auth) : super(BucketInitialState());

  Future<void> createBucket({
    required String name,
    String? description,
    int? color,
  }) async {
    emit(BucketProcessInProgressState());
    try {
      await _repo.createBucket(
        name: name,
        description: description,
        color: color,
        token: _auth.auth?.accessToken,
      );
      emit(BucketProcessingOKState());
    } catch (e) {
      emit(BucketProcessingErrorState(e.toString()));
    }
  }

  void reset() {
    emit(BucketInitialState());
  }
}

abstract class BucketState {}

class BucketInitialState extends BucketState {}

class BucketProcessInProgressState extends BucketState {}

class BucketProcessingOKState extends BucketState {}

class BucketProcessingErrorState extends BucketState {
  final String message;

  BucketProcessingErrorState(this.message);
}
