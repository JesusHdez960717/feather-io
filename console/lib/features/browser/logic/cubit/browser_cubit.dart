import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BrowserCubit extends Cubit<BrowserState> {
  final BrowserRepo repo;
  final AuthCubit auth;

  BrowserCubit({required this.repo, required this.auth})
    : super(BrowserInitialState());

  Future<void> loadBuckets() async {
    emit(BrowserLoadingInProgressState());
    try {
      final buckets = await repo.listBuckets(
        access: auth.access,
        secret: auth.secret,
      );
      emit(BrowserLoadingSuccessState(buckets));
    } catch (e) {
      emit(BrowserLoadingErrorState(e.toString()));
    }
  }

  void reset() {
    emit(BrowserInitialState());
  }
}

abstract class BrowserState {}

class BrowserInitialState extends BrowserState {}

class BrowserLoadingInProgressState extends BrowserState {}

class BrowserLoadingSuccessState extends BrowserState {
  final List<BucketModel> buckets;

  BrowserLoadingSuccessState(this.buckets);
}

class BrowserLoadingErrorState extends BrowserState {
  final String message;

  BrowserLoadingErrorState(this.message);
}
