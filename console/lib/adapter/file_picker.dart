import 'dart:async';
import 'dart:js_interop';

import 'package:cross_file/cross_file.dart';
import 'package:web/web.dart' as web;

// webkitRelativePath is not part of the standard File API,
// so it is exposed as an extension type over web.File.
extension type _FileWithRelativePath(web.File file) implements web.File {
  external String? get webkitRelativePath;
}

class FilePicker {
  static Future<XFile> _webFileToXFile(web.File file) async {
    final buffer = await file.arrayBuffer().toDart;
    final bytes = buffer.toDart.asUint8List();

    final relativePath = _FileWithRelativePath(file).webkitRelativePath;
    final name = (relativePath != null && relativePath.isNotEmpty)
        ? relativePath
        : file.name;

    return XFile.fromData(
      bytes,
      name: name,
      length: bytes.length,
      lastModified: DateTime.fromMillisecondsSinceEpoch(file.lastModified),
      mimeType: file.type,
    );
  }

  static Future<List<XFile>> pickFiles({bool multiple = true}) async {
    return _pickFiles(directory: false, multiple: true);
  }

  static Future<List<XFile>> pickDirectory() async {
    return _pickFiles(directory: true, multiple: false);
  }

  static Future<List<XFile>> _pickFiles({
    bool directory = false,
    bool multiple = true,
  }) async {
    final input = web.HTMLInputElement()..type = 'file';
    if (directory) {
      input.setAttribute('webkitdirectory', 'true');
      input.setAttribute('directory', 'true');
    } else {
      input.multiple = multiple;
    }

    final completer = Completer<void>();
    input.addEventListener(
      'change',
      (web.Event event) {
        completer.complete();
      }.toJS,
    );

    input.click();
    await completer.future;

    final fileList = input.files;
    if (fileList == null) return [];

    final xFiles = <XFile>[];
    for (var i = 0; i < fileList.length; i++) {
      final file = fileList.item(i);
      if (file == null) continue;
      xFiles.add(await _webFileToXFile(file));
    }
    return xFiles;
  }
}
