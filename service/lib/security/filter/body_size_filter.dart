import 'package:service/feather.dart';

///Limita el tamaño del cuerpo segun la ruta, mirando el `Content-Length` antes
///de leer nada. Winter corta cualquier cuerpo por encima de
///[ExtendedEnv.maxObjectSize] (ver `ServerConfig` en `main.dart`):
///- Subir un objeto (`s3.put-object`) va a disco como stream: si declara mas
///  de [ExtendedEnv.maxObjectSize], `EntityTooLarge`.
///- El resto lee el cuerpo en memoria (JSON, XML del borrado multiple, login):
///  como mucho [maxRequestBodySize], y con `Content-Length` obligatorio en
///  `POST`, `PUT` y `PATCH`
class BodySizeFilter extends Filter {
  static const String objectRouteKey = 's3.put-object';

  ///Cuerpo maximo de las peticiones que no suben un objeto (2 MB: cabe el XML
  ///de un borrado multiple de 1000 keys de 1024 bytes)
  static const int maxRequestBodySize = 2 * 1024 * 1024;

  static const Set<String> _bodyMethods = {'POST', 'PUT', 'PATCH'};

  static final BodySizeFilter _instance = BodySizeFilter._();

  BodySizeFilter._();

  factory BodySizeFilter() => _instance;

  @override
  Future<ResponseEntity> doFilter(
    RequestEntity request,
    FilterChain chain,
  ) async {
    final length = request.contentLength;

    if (request.routingContext?.key == objectRouteKey) {
      final max = env.maxObjectSize;
      if (length != null && length > max) {
        throw S3Exception(
          S3ErrorCode.entityTooLarge,
          message: 'El objeto ocupa $length bytes y el máximo es $max.',
          resource: request.pathParams['key'],
        );
      }
    } else if (length != null && length > maxRequestBodySize) {
      throw PayloadTooLargeException();
    } else if (length == null && _bodyMethods.contains(request.method)) {
      //sin tamaño (cuerpo chunked) no se puede acotar antes de leerlo. dart:io
      //decodifica el chunked y no deja ver `Transfer-Encoding`, asi que se pide
      //`Content-Length` a todo lo que lleva cuerpo; los clientes lo mandan
      //aunque el cuerpo este vacio
      throw ApiException(statusCode: 411, body: 'Length Required');
    }

    return await chain.doFilter(request);
  }

  @override
  String toString() =>
      'BodySizeFilter{maxRequestBodySize: $maxRequestBodySize}';
}
