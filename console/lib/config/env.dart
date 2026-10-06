// `window.env` (web/env.js) on web; outside the browser (tests on the VM) the
// `--dart-define`s or the local defaults
export 'env_vm.dart' if (dart.library.js_interop) 'env_web.dart';
