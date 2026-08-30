class DeleteObjectsRequest {
  final List<String> keys;
  final bool quiet;

  DeleteObjectsRequest({
    required this.keys,
    this.quiet = false,
  });

  factory DeleteObjectsRequest.fromJson(Map<String, dynamic> json) {
    // Soportamos el formato estándar y uno más directo
    final delete = json['Delete'] ?? json['delete'] ?? json;
    
    final List<dynamic> objectsList = (delete is Map) 
        ? (delete['Object'] ?? delete['object'] ?? delete['objects'] ?? [])
        : [];
    
    final keys = objectsList.map((e) {
      if (e is String) return e;
      if (e is Map) return (e['Key'] ?? e['key'] ?? '').toString();
      return '';
    }).where((k) => k.isNotEmpty).toList();

    final quietValue = (delete is Map) ? (delete['Quiet'] ?? delete['quiet']) : false;

    return DeleteObjectsRequest(
      keys: keys,
      quiet: quietValue == true || quietValue == 'true',
    );
  }
}
