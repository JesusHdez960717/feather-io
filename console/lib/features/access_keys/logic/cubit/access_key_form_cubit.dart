import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// State of the create/edit drawer. It lives while the drawer is open, so
/// loading and errors show inside the form
class AccessKeyFormCubit extends Cubit<AccessKeyFormState> {
  final AccessKeyRepo _repo;
  final AuthCubit _auth;

  AccessKeyFormCubit(this._repo, this._auth)
    : super(const AccessKeyFormInitialState());

  /// Creates the key, or updates [id]. After creating, the OK state carries
  /// the secret
  Future<void> save({required AccessKeyDraft draft, String? id}) async {
    emit(const AccessKeyFormProcessInProgressState());
    try {
      final key = id == null
          ? await _repo.createKey(draft: draft, token: _auth.auth?.accessToken)
          : await _repo.updateKey(
              id: id,
              draft: draft,
              token: _auth.auth?.accessToken,
            );
      emit(AccessKeyFormProcessingOKState(key, created: id == null));
    } catch (e) {
      final exception = ExceptionConverter.parse(e);
      emit(
        AccessKeyFormProcessingErrorState(
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

/// Field names of the form, equal to the `fieldName`s the API returns
abstract class AccessKeyFormField {
  static const String name = 'name';
}

abstract class AccessKeyFormState {
  const AccessKeyFormState();
}

class AccessKeyFormInitialState extends AccessKeyFormState {
  const AccessKeyFormInitialState();
}

//------------------------- PROCESSING -------------------------\
class AccessKeyFormProcessInProgressState extends AccessKeyFormState {
  const AccessKeyFormProcessInProgressState();
}

class AccessKeyFormProcessingOKState extends AccessKeyFormState {
  final AccessKeyModel key;
  final bool created;

  const AccessKeyFormProcessingOKState(this.key, {required this.created});
}

class AccessKeyFormProcessingErrorState extends AccessKeyFormState {
  final GlobalException exception;

  /// Errors per field; if empty, the error belongs to the whole form
  final Map<String, String> fieldErrors;

  const AccessKeyFormProcessingErrorState(
    this.exception, {
    this.fieldErrors = const {},
  });
}
