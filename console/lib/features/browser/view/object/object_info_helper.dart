import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'objects_subscreen.dart';

class ObjectInfoHelper {
  static ({String name, IconData icon}) getFileInfo(BrowserObjectWrapper wrapper) {
    if (wrapper.isFolder) {
      return (name: 'Carpeta', icon: Icons.folder);
    }

    final fileName = wrapper.name;
    final mimeType = lookupMimeType(fileName);

    if (mimeType == null) {
      final ext = fileName.contains('.')
          ? fileName.split('.').last.toUpperCase()
          : 'FICHERO';
      return (name: ext, icon: Icons.insert_drive_file);
    }

    // 1. Categorías principales por tipo MIME
    if (mimeType.startsWith('image/')) {
      return (name: 'Imagen', icon: Icons.image);
    }
    if (mimeType.startsWith('video/')) {
      return (name: 'Video', icon: Icons.movie);
    }
    if (mimeType.startsWith('audio/')) {
      return (name: 'Audio', icon: Icons.audiotrack);
    }
    if (mimeType.startsWith('text/')) {
      return (name: 'Texto', icon: Icons.description);
    }

    // 2. Formatos específicos de aplicación
    switch (mimeType) {
      case 'application/pdf':
        return (name: 'PDF', icon: Icons.picture_as_pdf);

      case 'application/msword':
      case 'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
        return (name: 'Documento', icon: Icons.article);

      case 'application/vnd.ms-excel':
      case 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
        return (name: 'Excel', icon: Icons.table_chart);

      case 'application/json':
        return (name: 'JSON', icon: Icons.data_object);

      case 'application/zip':
      case 'application/x-rar-compressed':
      case 'application/x-7z-compressed':
      case 'application/x-tar':
      case 'application/gzip':
        return (name: 'Comprimido', icon: Icons.folder_zip);

      default:
        if (mimeType.contains('zip') || mimeType.contains('compressed')) {
          return (name: 'Comprimido', icon: Icons.folder_zip);
        }
        final ext = fileName.contains('.')
            ? fileName.split('.').last.toUpperCase()
            : 'FICHERO';
        return (name: ext, icon: Icons.insert_drive_file);
    }
  }
}
