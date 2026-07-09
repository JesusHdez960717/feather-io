import 'package:dio/dio.dart';
import 'package:console/app_exporter.dart';

class ExceptionConverter {
  static GlobalException parse(dynamic exception) {
    return switch (exception) {
      GlobalException() => exception,
      DioException() => ApiExceptionConverter.parse(exception),
      _ => GlobalException(
        type: GlobalExceptionType.general,
        message: 'Unknown error', //TODO: intl
        data: exception,
      ),
    };
  }
}
