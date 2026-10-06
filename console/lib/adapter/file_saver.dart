// The browser's download on web; outside the browser (tests on the VM) it
// saves nothing
export 'file_saver_vm.dart' if (dart.library.js_interop) 'file_saver_web.dart';
