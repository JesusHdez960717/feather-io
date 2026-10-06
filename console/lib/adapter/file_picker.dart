// The browser's file dialog on web; outside the browser (tests on the VM) it
// picks nothing
export 'file_picker_vm.dart'
    if (dart.library.js_interop) 'file_picker_web.dart';
