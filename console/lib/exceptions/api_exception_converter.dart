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
        //TODO: revisar con mas detalles el error en web
        if (kIsWeb) {
          return GlobalException(
            //in web, dio handle 403/401 as a connection error, some weird stuff with navigator closing the connection
            //all other status 200,404,422, work ok, only 403/401, so we gonna handle this connection error as an auth exception
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

  ///Los errores S3 llegan como `{code, message, resource}`; el resto como texto plano
  static String _message(dynamic data) {
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return data?.toString() ?? '';
  }
}
