import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

///Estado del cajon de añadir regla. Vive mientras el cajon esta abierto, asi la
///carga y los errores se muestran dentro del formulario
class AnonymousRuleFormCubit extends Cubit<AnonymousRuleFormState> {
  final AnonymousAccessRepo _repo;
  final AuthCubit _auth;

  AnonymousRuleFormCubit(this._repo, this._auth)
    : super(const AnonymousRuleFormInitialState());

  Future<void> create({
    required String bucket,
    required AnonymousRuleModel rule,
  }) async {
    emit(const AnonymousRuleFormProcessInProgressState());
    try {
      await _repo.createRule(
        bucket: bucket,
        rule: rule,
        token: _auth.auth?.accessToken,
      );
      emit(AnonymousRuleFormProcessingOKState(prefix: rule.prefix));
    } catch (e) {
      final exception = ExceptionConverter.parse(e);
      emit(
        AnonymousRuleFormProcessingErrorState(
          exception,
          fieldErrors: switch (exception.data) {
            List<ValidationError> errors
                when exception.type == GlobalExceptionType.validation =>
              errors.asFailedValidations(),
            _ => const {},
          },
        ),
      );
    }
  }
}

///Nombres de campo del formulario, iguales a los `fieldName` que devuelve la API
abstract class AnonymousRuleFormField {
  static const String prefix = 'prefix';
  static const String access = 'access';
}

abstract class AnonymousRuleFormState {
  const AnonymousRuleFormState();
}

class AnonymousRuleFormInitialState extends AnonymousRuleFormState {
  const AnonymousRuleFormInitialState();
}

//------------------------- PROCESSING -------------------------\
class AnonymousRuleFormProcessInProgressState extends AnonymousRuleFormState {
  const AnonymousRuleFormProcessInProgressState();
}

class AnonymousRuleFormProcessingOKState extends AnonymousRuleFormState {
  final String prefix;

  const AnonymousRuleFormProcessingOKState({required this.prefix});
}

class AnonymousRuleFormProcessingErrorState extends AnonymousRuleFormState {
  final GlobalException exception;

  ///Errores por campo; si esta vacio, el error es de todo el formulario
  final Map<String, String> fieldErrors;

  const AnonymousRuleFormProcessingErrorState(
    this.exception, {
    this.fieldErrors = const {},
  });
}
