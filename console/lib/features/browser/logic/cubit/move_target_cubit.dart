import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Target folder being picked in the move dialog: the bucket, the open folder
/// and its subfolders
class MoveTargetCubit extends Cubit<MoveTargetState> {
  final BrowserRepo _repo;
  final AuthCubit _auth;

  MoveTargetCubit(this._repo, this._auth)
    : super(const MoveTargetInitialState());

  /// Opens [prefix] of [bucket] and lists its subfolders
  Future<void> open({required String bucket, required String prefix}) async {
    emit(
      MoveTargetLoadingInProgressState(
        bucket: bucket,
        prefix: prefix,
        folders: bucket == state.bucket && prefix == state.prefix
            ? state.folders
            : const [],
      ),
    );
    try {
      final listing = await _repo.listObjects(
        token: _auth.auth?.accessToken,
        bucket: bucket,
        prefix: prefix,
        delimiter: '/',
        maxKeys: 1000,
      );
      // if another folder was opened meanwhile, this response is stale
      if (state.bucket != bucket || state.prefix != prefix) return;
      emit(
        MoveTargetLoadingSuccessState(
          bucket: bucket,
          prefix: prefix,
          folders: listing.commonPrefixes,
        ),
      );
    } catch (e) {
      if (state.bucket != bucket || state.prefix != prefix) return;
      emit(
        MoveTargetLoadingErrorState(
          ExceptionConverter.parse(e),
          bucket: bucket,
          prefix: prefix,
        ),
      );
    }
  }
}

abstract class MoveTargetState {
  final String? bucket;

  /// Open folder as a prefix (`books/2026/`); empty is the root
  final String prefix;

  /// Subfolders of [prefix], as full prefixes
  final List<String> folders;

  const MoveTargetState({
    this.bucket,
    this.prefix = '',
    this.folders = const [],
  });
}

class MoveTargetInitialState extends MoveTargetState {
  const MoveTargetInitialState();
}

//------------------------- LOADING -------------------------\\
class MoveTargetLoadingInProgressState extends MoveTargetState {
  const MoveTargetLoadingInProgressState({
    super.bucket,
    super.prefix,
    super.folders,
  });
}

class MoveTargetLoadingSuccessState extends MoveTargetState {
  const MoveTargetLoadingSuccessState({
    super.bucket,
    super.prefix,
    super.folders,
  });
}

class MoveTargetLoadingErrorState extends MoveTargetState {
  final GlobalException exception;

  const MoveTargetLoadingErrorState(
    this.exception, {
    super.bucket,
    super.prefix,
  });
}
