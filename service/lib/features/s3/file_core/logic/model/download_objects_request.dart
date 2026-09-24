import 'package:service/feather.dart';

class DownloadObjectsRequest implements Serializable {
  final List<String> keys;

  DownloadObjectsRequest({required this.keys});

  factory DownloadObjectsRequest.fromJson(Map<String, dynamic> json) {
    final List<dynamic> keysList = json['keys'] ?? [];
    return DownloadObjectsRequest(
      keys: keysList.map((e) => e.toString()).toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'keys': keys,
    };
  }
}
