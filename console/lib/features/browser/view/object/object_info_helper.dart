import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mime/mime.dart';

class ObjectInfoHelper {
  static ({String name, IconData icon}) getFileInfo(
    BrowserObjectWrapper wrapper,
  ) {
    if (wrapper.isFolder) {
      return (name: app.intl.fileTypeFolder, icon: Icons.folder);
    }

    final fileName = wrapper.name;
    final mimeType = lookupMimeType(fileName);

    if (mimeType == null) {
      final ext = fileName.contains('.')
          ? fileName.split('.').last.toUpperCase()
          : app.intl.fileTypeFile;
      return (name: ext, icon: Icons.insert_drive_file);
    }

    // 1. Main categories by MIME type
    if (mimeType.startsWith('image/')) {
      return (name: app.intl.fileTypeImage, icon: Icons.image);
    }
    if (mimeType.startsWith('video/')) {
      return (name: app.intl.fileTypeVideo, icon: Icons.movie);
    }
    if (mimeType.startsWith('audio/')) {
      return (name: app.intl.fileTypeAudio, icon: Icons.audiotrack);
    }
    if (mimeType.startsWith('text/')) {
      return (name: app.intl.fileTypeText, icon: Icons.description);
    }

    // 2. Application-specific formats
    switch (mimeType) {
      case 'application/pdf':
        return (name: 'PDF', icon: Icons.picture_as_pdf);

      case 'application/msword':
      case 'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
        return (name: app.intl.fileTypeDocument, icon: Icons.article);

      case 'application/vnd.ms-excel':
      case 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
        return (name: app.intl.fileTypeSpreadsheet, icon: Icons.table_chart);

      case 'application/json':
        return (name: 'JSON', icon: Icons.data_object);

      case 'application/zip':
      case 'application/x-rar-compressed':
      case 'application/x-7z-compressed':
      case 'application/x-tar':
      case 'application/gzip':
        return (name: app.intl.fileTypeArchive, icon: Icons.folder_zip);

      default:
        if (mimeType.contains('zip') || mimeType.contains('compressed')) {
          return (name: app.intl.fileTypeArchive, icon: Icons.folder_zip);
        }
        final ext = fileName.contains('.')
            ? fileName.split('.').last.toUpperCase()
            : app.intl.fileTypeFile;
        return (name: ext, icon: Icons.insert_drive_file);
    }
  }
}
