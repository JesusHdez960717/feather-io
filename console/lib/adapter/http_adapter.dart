// The browser's HTTP adapter on web; outside the browser (tests on the VM) Dio
// keeps its default one
export 'http_adapter_vm.dart'
    if (dart.library.js_interop) 'http_adapter_web.dart';
