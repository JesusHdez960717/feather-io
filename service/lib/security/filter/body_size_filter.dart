import 'package:service/feather.dart';

///Limita el tamaño del cuerpo segun la ruta, mirando el `Content-Length` antes
///de leer nada. Winter corta cualquier cuerpo por encima de
///[ExtendedEnv.maxObjectSize] (ver `ServerConfig` en `main.dart`):
///- Subir un objeto (`s3.put-object`) va a disco como stream: si declara mas
///  de [ExtendedEnv.maxObjectSize], `EntityTooLarge`.
///- El resto lee el cuerpo en memoria (JSON, XML del borrado multiple, login):
///  como mucho [maxRequestBodySize]. Sin `Content-Length` (cuerpo vacio o
///  chunked: shelf quita `Transfer-Encoding` y no se distinguen) el limite se
///  comprueba mientras se lee el cuerpo
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
      //sin tamaño no se puede acotar antes de leerlo: se corta al leerlo (413).
      //Asi pasa un cuerpo vacio sin cabecera, como el CreateBucket de
      //aws-sdk-java-v2
      return await chain.doFilter(
        request.change(
          body: limitBodySize(request.read(), maxBytes: maxRequestBodySize),
        ),
      );
    }

    return await chain.doFilter(request);
  }

  @override
  String toString() =>
      'BodySizeFilter{maxRequestBodySize: $maxRequestBodySize}';
}
