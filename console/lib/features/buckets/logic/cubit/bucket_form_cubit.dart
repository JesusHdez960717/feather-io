import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// State of the create/edit bucket drawer. It lives while the drawer is open, so
/// loading and errors show inside the form and not on the screen behind
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

  /// [action] returns the updated bucket when the API returns it (edit)
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

  /// Errors shown on their field: a 422 by `fieldName` and a 409 (the bucket
  /// already exists) on the name. The rest goes to the form's general notice
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

/// Field names of the form, equal to the `fieldName`s the API returns
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

  /// The already updated bucket, when editing
  final BucketModel? bucket;

  const BucketFormProcessingOKState({
    required this.name,
    required this.change,
    this.bucket,
  });
}

class BucketFormProcessingErrorState extends BucketFormState {
  final GlobalException exception;

  /// Errors per field; if empty, the error belongs to the whole form
  final Map<String, String> fieldErrors;

  const BucketFormProcessingErrorState(
    this.exception, {
    this.fieldErrors = const {},
  });
}
