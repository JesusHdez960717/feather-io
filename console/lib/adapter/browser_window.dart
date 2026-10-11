// The browser window on web; outside the browser (tests on the VM) it does
// nothing
export 'browser_window_vm.dart'
    if (dart.library.js_interop) 'browser_window_web.dart';
