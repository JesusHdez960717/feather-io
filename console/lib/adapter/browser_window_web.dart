import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// The browser window: new tabs and the warning before leaving
class BrowserWindow {
  /// Opens [bytes] in a new tab, shown by the browser as [contentType]
  static void openBytes(List<int> bytes, {String? contentType}) {
    final blob = web.Blob(
      [Uint8List.fromList(bytes).toJS].toJS,
      web.BlobPropertyBag(type: contentType ?? 'application/octet-stream'),
    );
    web.window.open(web.URL.createObjectURL(blob), '_blank');
  }

  static final JSFunction _beforeUnload = ((web.Event event) {
    event.preventDefault();
  }).toJS;

  /// With [on], the browser asks before closing or reloading the tab
  static void guardLeave(bool on) {
    if (on) {
      web.window.addEventListener('beforeunload', _beforeUnload);
    } else {
      web.window.removeEventListener('beforeunload', _beforeUnload);
    }
  }
}
