import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

///Estado del cajon de crear bucket. Vive mientras el cajon esta abierto, asi la
///carga y los errores se muestran dentro del formulario y no en la pantalla de fondo
class BucketCreateCubit extends Cubit<BucketCreateState> {
  final BucketRepo _repo;
  final AuthCubit _auth;

  BucketCreateCubit(this._repo, this._auth)
    : super(const BucketCreateInitialState());

  Future<void> create({
    required String name,
    String? description,
    int? color,
  }) async {
    emit(const BucketCreateProcessInProgressState());
    try {
      await _repo.createBucket(
        name: name,
        description: description,
        color: color,
        token: _auth.auth?.accessToken,
      );
      emit(BucketCreateProcessingOKState(name: name));
    } catch (e) {
      final exception = ExceptionConverter.parse(e);
      emit(
        BucketCreateProcessingErrorState(
          exception,
          fieldErrors: _fieldErrors(exception),
        ),
      );
    }
  }

  ///Errores que se muestran en su campo: un 422 por `fieldName` y un 409 (el
  ///bucket ya existe) en el nombre. El resto va al aviso general del formulario
  Map<String, String> _fieldErrors(GlobalException exception) {
    return switch (exception.type) {
      GlobalExceptionType.validation => switch (exception.data) {
        List<ValidationError> errors => errors.asFailedValidations(),
        _ => const {},
      },
      GlobalExceptionType.conflict => {
        BucketCreateField.name: app.intl.bucketNameExists,
      },
      _ => const {},
    };
  }
}

///Nombres de campo del formulario, iguales a los `fieldName` que devuelve la API
abstract class BucketCreateField {
  static const String name = 'name';
  static const String description = 'description';
  static const String color = 'color';
}

abstract class BucketCreateState {
  const BucketCreateState();
}

class BucketCreateInitialState extends BucketCreateState {
  const BucketCreateInitialState();
}

//------------------------- PROCESSING -------------------------\\
class BucketCreateProcessInProgressState extends BucketCreateState {
  const BucketCreateProcessInProgressState();
}

class BucketCreateProcessingOKState extends BucketCreateState {
  final String name;

  const BucketCreateProcessingOKState({required this.name});
}

class BucketCreateProcessingErrorState extends BucketCreateState {
  final GlobalException exception;

  ///Errores por campo; si esta vacio, el error es de todo el formulario
  final Map<String, String> fieldErrors;

  const BucketCreateProcessingErrorState(
    this.exception, {
    this.fieldErrors = const {},
  });
}
