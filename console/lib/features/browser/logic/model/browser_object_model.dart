class BrowserObjectModel {
  final String key;
  final int sizeBytes;
  final DateTime lastModified;

  BrowserObjectModel({
    required this.key,
    required this.sizeBytes,
    required this.lastModified,
  });
}

class ListObjectsModel {
  final String bucketName;
  final String? prefix;
  final String? delimiter;
  final List<BrowserObjectModel> objects;
  final List<String> commonPrefixes;

  ///Hay mas elementos despues de esta pagina
  final bool isTruncated;

  ///Token para pedir la pagina siguiente
  final String? nextContinuationToken;

  ///Elementos de la carpeta en todas las paginas
  final int totalKeys;

  ListObjectsModel({
    required this.bucketName,
    required this.objects,
    required this.commonPrefixes,
    this.prefix,
    this.delimiter,
    this.isTruncated = false,
    this.nextContinuationToken,
    this.totalKeys = 0,
  });
}

///Cabeceras de un objeto (`HEAD`), para su panel de detalles
class ObjectInfoModel {
  final String? contentType;
  final int? sizeBytes;
  final DateTime? lastModified;

  ObjectInfoModel({this.contentType, this.sizeBytes, this.lastModified});
}

class ObjectDataModel {
  final List<int> bytes;
  final String? contentType;

  ObjectDataModel({required this.bytes, this.contentType});
}

///Item (carpeta u objeto) tal como se muestra en el explorador
class BrowserObjectWrapper {
  final String name;
  final bool isFolder;
  final int? size;
  final DateTime? lastModified;
  final String fullPath;

  BrowserObjectWrapper({
    required this.name,
    required this.isFolder,
    required this.fullPath,
    this.size,
    this.lastModified,
  });
}
