/// Metadatos de un objeto: su ETag y las cabeceras con las que se subio
class ObjectMetaModel {
  /// md5 del contenido (sin comillas), o `md5-N` si se subio por partes
  final String etag;

  /// `Content-Type`, `x-amz-meta-*`… en minusculas, tal y como se guardaron
  final Map<String, String> headers;

  const ObjectMetaModel({required this.etag, this.headers = const {}});
}
