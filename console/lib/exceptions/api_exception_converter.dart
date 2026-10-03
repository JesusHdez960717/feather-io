import 'package:console/app_exporter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiExceptionConverter {
  static GlobalException parse(DioException error) {
    switch (error.type) {
      case DioExceptionType.cancel:
        return GlobalException(
          type: GlobalExceptionType.general,
          message: app.intl.errorRequestCancelled,
        );
      case DioExceptionType.connectionTimeout:
        return GlobalException(
          type: GlobalExceptionType.general,
          message: app.intl.errorConnectionTimeout,
        );
      case DioExceptionType.transformTimeout:
        return GlobalException(
          type: GlobalExceptionType.general,
          message: app.intl.errorNoConnection,
        );
      case DioExceptionType.unknown:
        return GlobalException(
          type: GlobalExceptionType.general,
          message: app.intl.errorNoConnection,
        );
      case DioExceptionType.receiveTimeout:
        return GlobalException(
          type: GlobalExceptionType.general,
          message: app.intl.errorReceiveTimeout,
        );
      case DioExceptionType.sendTimeout:
        return GlobalException(
          type: GlobalExceptionType.general,
          message: app.intl.errorSendTimeout,
        );
      case DioExceptionType.badCertificate:
        return GlobalException(
          type: GlobalExceptionType.general,
          message: app.intl.errorBadCertificate,
        );
      case DioExceptionType.connectionError:
        // TODO: look at the web error in more detail
        if (kIsWeb) {
          return GlobalException(
            // on web, Dio reports 403/401 as a connection error (the browser closes the connection)
            // every other status (200, 404, 422) works, so this connection error is handled as an auth exception
            type: GlobalExceptionType.auth,
            message: app.intl.errorConnection,
          );
        } else {
          return GlobalException(
            type: GlobalExceptionType.general,
            message: app.intl.errorConnection,
          );
        }
      case DioExceptionType.badResponse:
        return _parseBadResponse(error);
    }
  }

  static GlobalException _parseBadResponse(DioException error) {
    if (error.response!.statusCode == 422) {
      return GlobalException(
        type: GlobalExceptionType.validation,
        message: app.intl.errorValidation,
        data: (error.response!.data as List<dynamic>)
            .map(
              (json) => ValidationError.fromJson(json as Map<String, dynamic>),
            )
            .toList(),
      );
    } else if (error.response!.statusCode == 409) {
      return GlobalException(
        type: GlobalExceptionType.conflict,
        message: _message(error.response!.data),
        data: error.response!.data,
      );
    } else if (error.response!.statusCode! >= 500) {
      return GlobalException(
        type: GlobalExceptionType.general,
        message: app.intl.errorServer,
        data: error.response!.data,
      );
    } else {
      return GlobalException(
        type: GlobalExceptionType.general,
        message: _message(error.response!.data),
        data: error.response!.data,
      );
    }
  }

  /// S3 errors arrive as `{code, message, resource}`; the rest as plain text
  static String _message(dynamic data) {
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return data?.toString() ?? '';
  }
}
