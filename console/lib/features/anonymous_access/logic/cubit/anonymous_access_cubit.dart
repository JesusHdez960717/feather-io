import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

///Reglas de acceso anonimo del bucket que se muestra en el detalle
class AnonymousAccessCubit extends Cubit<AnonymousAccessState> {
  final AnonymousAccessRepo _repo;
  final AuthCubit _auth;

  AnonymousAccessCubit(this._repo, this._auth)
    : super(const AnonymousAccessInitialState());

  Future<void> load({required String bucket}) async {
    //las reglas de otro bucket no se muestran mientras cargan las nuevas
    final rules = bucket == state.bucket ? state.rules : <AnonymousRuleModel>[];
    emit(AnonymousAccessLoadingInProgressState(bucket: bucket, rules: rules));
    try {
      final loaded = await _repo.getRules(
        bucket: bucket,
        token: _auth.auth?.accessToken,
      );
      //si mientras tanto se eligio otro bucket, esta respuesta ya no vale
      if (state.bucket != bucket) return;
      emit(AnonymousAccessLoadingSuccessState(bucket: bucket, rules: loaded));
    } catch (e) {
      if (state.bucket != bucket) return;
      emit(
        AnonymousAccessLoadingErrorState(
          ExceptionConverter.parse(e),
          bucket: bucket,
          rules: rules,
        ),
      );
    }
  }

  Future<void> deleteRule({required String prefix}) async {
    final bucket = state.bucket;
    if (bucket == null) return;
    emit(
      AnonymousAccessProcessInProgressState(bucket: bucket, rules: state.rules),
    );
    try {
      await _repo.deleteRule(
        bucket: bucket,
        prefix: prefix,
        token: _auth.auth?.accessToken,
      );
      emit(
        AnonymousAccessProcessingOKState(bucket: bucket, rules: state.rules),
      );
    } catch (e) {
      emit(
        AnonymousAccessProcessingErrorState(
          ExceptionConverter.parse(e).message,
          bucket: bucket,
          rules: state.rules,
        ),
      );
      return;
    }
    await load(bucket: bucket);
  }
}

abstract class AnonymousAccessState {
  final String? bucket;
  final List<AnonymousRuleModel> rules;

  const AnonymousAccessState({this.bucket, this.rules = const []});
}

class AnonymousAccessInitialState extends AnonymousAccessState {
  const AnonymousAccessInitialState();
}

//------------------------- LOADING -------------------------\
class AnonymousAccessLoadingInProgressState extends AnonymousAccessState {
  const AnonymousAccessLoadingInProgressState({super.bucket, super.rules});
}

class AnonymousAccessLoadingSuccessState extends AnonymousAccessState {
  const AnonymousAccessLoadingSuccessState({super.bucket, super.rules});
}

class AnonymousAccessLoadingErrorState extends AnonymousAccessState {
  final GlobalException exception;

  const AnonymousAccessLoadingErrorState(
    this.exception, {
    super.bucket,
    super.rules,
  });
}

//------------------------- PROCESSING -------------------------\
class AnonymousAccessProcessInProgressState extends AnonymousAccessState {
  const AnonymousAccessProcessInProgressState({super.bucket, super.rules});
}

class AnonymousAccessProcessingOKState extends AnonymousAccessState {
  const AnonymousAccessProcessingOKState({super.bucket, super.rules});
}

class AnonymousAccessProcessingErrorState extends AnonymousAccessState {
  final String message;

  const AnonymousAccessProcessingErrorState(
    this.message, {
    super.bucket,
    super.rules,
  });
}
