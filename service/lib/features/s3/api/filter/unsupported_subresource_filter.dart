import 'package:service/feather.dart';

/// Responde `501 NotImplemented`, como S3, a los subrecursos que el servicio no
/// implementa (`?versioning`, `?policy`, `?tagging`…). Sin el filtro caerian en
/// la ruta normal: `PUT /{bucket}?versioning` intentaria crear el bucket y
/// `GET /{bucket}?policy` devolveria el listado
class UnsupportedSubresourceFilter extends Filter {
  static final UnsupportedSubresourceFilter _instance =
      UnsupportedSubresourceFilter._();

  UnsupportedSubresourceFilter._();

  factory UnsupportedSubresourceFilter() => _instance;

  static const Set<String> _unsupported = {
    'accelerate',
    'acl',
    'analytics',
    'attributes',
    'cors',
    'encryption',
    'intelligent-tiering',
    'inventory',
    'legal-hold',
    'lifecycle',
    'logging',
    'metrics',
    'notification',
    'object-lock',
    'ownershipControls',
    'policy',
    'policyStatus',
    'publicAccessBlock',
    'replication',
    'requestPayment',
    'restore',
    'retention',
    'select',
    'tagging',
    'torrent',
    'versioning',
    'versions',
    'website',
  };

  @override
  Future<ResponseEntity> doFilter(
    RequestEntity request,
    FilterChain chain,
  ) async {
    final params = request.queryParams.keys;
    final subresource = params
        .where(_unsupported.contains)
        .where((p) => !_readable(request, p))
        .firstOrNull;
    if (subresource != null) {
      throw S3Exception(
        S3ErrorCode.notImplemented,
        message: 'El subrecurso "$subresource" no está implementado.',
        resource: request.requestedUri.path,
      );
    }

    return await chain.doFilter(request);
  }

  /// Lecturas que si se contestan aunque no se implemente el subrecurso,
  /// porque los clientes las piden antes de otras operaciones: las etiquetas
  /// de un objeto (GetObjectTagging, la CLI de AWS antes de una copia
  /// multipart; no hay ninguna) y el versionado de un bucket
  /// (GetBucketVersioning, rclone; nunca esta activado)
  bool _readable(RequestEntity request, String subresource) {
    if (request.method != 'GET') return false;
    final hasKey = request.pathParams['key'] != null;
    return (subresource == 'tagging' && hasKey) ||
        (subresource == 'versioning' && !hasKey);
  }

  @override
  String toString() => 'UnsupportedSubresourceFilter()';
}
