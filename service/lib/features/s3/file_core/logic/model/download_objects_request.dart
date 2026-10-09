import 'package:service/feather.dart';

/// Objects (and folders, ending in `/`) to download in a zip.
class DownloadObjectsRequest {
  final List<String> keys;

  DownloadObjectsRequest({required this.keys});

  /// The example of the OpenAPI document.
  static final DownloadObjectsRequest example = DownloadObjectsRequest(
    keys: ['photos/beach.jpg', 'documents/'],
  );

  factory DownloadObjectsRequest.fromJson(Map<String, dynamic> json) {
    return DownloadObjectsRequest(
      keys: json.field<List<String>?>('keys') ?? const [],
    );
  }

  Map<String, Object?> toJson() {
    return {'keys': keys};
  }
}
