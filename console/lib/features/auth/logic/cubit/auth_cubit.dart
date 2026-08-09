import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepo repo;
  AuthModel? _auth;

  AuthCubit(this.repo) : super(AuthInitialState());

  AuthModel? get auth => _auth;

  void login({required String access, required String secret}) async {
    emit(AuthProcessingInProgressState());
    try {
      _auth = await repo.login(access: access, secret: secret);
      emit(AuthProcessingOKState());
    } catch (e) {
      _auth = null;
      final exc = ExceptionConverter.parse(e);
      emit(AuthProcessingErrorState(exc.message));
    }
  }

  void logout() {
    _auth = null;
    emit(AuthLogoutState());
  }

  void reset() {
    _auth = null;
    emit(AuthInitialState());
  }
}

abstract class AuthState {}

class AuthInitialState extends AuthState {}

class AuthProcessingInProgressState extends AuthState {}

class AuthProcessingOKState extends AuthState {}

class AuthProcessingErrorState extends AuthState {
  final String message;

  AuthProcessingErrorState(this.message);
}

class AuthLogoutState extends AuthState {}
