import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

///Estado del cajon de crear/editar bucket. Vive mientras el cajon esta abierto, asi la
///carga y los errores se muestran dentro del formulario y no en la pantalla de fondo
class BucketFormCubit extends Cubit<BucketFormState> {
  final BucketRepo _repo;
  final AuthCubit _auth;

  BucketFormCubit(this._repo, this._auth)
    : super(const BucketFormInitialState());

  Future<void> create({
    required String name,
    String? description,
    int? color,
  }) async {
    await _process(
      name: name,
      change: BucketChange.created,
      action: () async {
        await _repo.createBucket(
          name: name,
          description: description,
          color: color,
          token: _auth.auth?.accessToken,
        );
        return null;
      },
    );
  }

  Future<void> update({
    required String name,
    String? description,
    int? color,
  }) async {
    await _process(
      name: name,
      change: BucketChange.updated,
      action: () => _repo.updateBucket(
        name: name,
        description: description,
        color: color,
        token: _auth.auth?.accessToken,
      ),
    );
  }

  ///[action] devuelve el bucket actualizado cuando la API lo devuelve (editar)
  Future<void> _process({
    required String name,
    required BucketChange change,
    required Future<BucketModel?> Function() action,
  }) async {
    emit(const BucketFormProcessInProgressState());
    try {
      final bucket = await action();
      emit(
        BucketFormProcessingOKState(name: name, change: change, bucket: bucket),
      );
    } catch (e) {
      final exception = ExceptionConverter.parse(e);
      emit(
        BucketFormProcessingErrorState(
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
        BucketFormField.name: app.intl.bucketNameExists,
      },
      _ => const {},
    };
  }
}

///Nombres de campo del formulario, iguales a los `fieldName` que devuelve la API
abstract class BucketFormField {
  static const String name = 'name';
  static const String description = 'description';
  static const String color = 'color';
}

abstract class BucketFormState {
  const BucketFormState();
}

class BucketFormInitialState extends BucketFormState {
  const BucketFormInitialState();
}

//------------------------- PROCESSING -------------------------\\
class BucketFormProcessInProgressState extends BucketFormState {
  const BucketFormProcessInProgressState();
}

class BucketFormProcessingOKState extends BucketFormState {
  final String name;
  final BucketChange change;

  ///El bucket ya actualizado, al editar
  final BucketModel? bucket;

  const BucketFormProcessingOKState({
    required this.name,
    required this.change,
    this.bucket,
  });
}

class BucketFormProcessingErrorState extends BucketFormState {
  final GlobalException exception;

  ///Errores por campo; si esta vacio, el error es de todo el formulario
  final Map<String, String> fieldErrors;

  const BucketFormProcessingErrorState(
    this.exception, {
    this.fieldErrors = const {},
  });
}
