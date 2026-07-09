import 'package:flutter_bloc/flutter_bloc.dart';

class AuthCubit extends Cubit<AuthState> {
  final String secret = 'secret';
  final String access = 'access';

  AuthCubit() : super(AuthInitialState());

  void logout() {}

  void reset() {
    emit(AuthInitialState());
  }
}

abstract class AuthState {}

class AuthInitialState extends AuthState {}
