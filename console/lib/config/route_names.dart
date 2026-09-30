import 'package:console/app_exporter.dart';

///Nombres de las rutas y de sus parametros. Una feature navega a la pantalla
///de otra por su nombre de ruta, sin importarla
abstract class RouteNames {
  static const String login = 'login';
  static const String browser = 'browser';
  static const String buckets = 'buckets';

  ///`?bucket=` de [browser]: el bucket abierto; sin el, el listado de buckets
  static const String browserBucketParam = 'bucket';

  ///`?folder=` de [browser]: la carpeta abierta dentro del bucket
  ///(`fotos/2026`, sin barra final); sin el, la raiz del bucket
  static const String browserFolderParam = 'folder';

  ///`?view_type=` de [browser]: lista o cuadricula
  static const String browserViewTypeParam = 'view_type';

  ///`?bucket=` de [buckets]: el bucket seleccionado
  static const String bucketsBucketParam = 'bucket';

  ///`?tab=` de [buckets]: la pestaña del detalle (por defecto, la general)
  static const String bucketsTabParam = 'tab';

  ///Abre la seccion *Buckets* con [bucket] seleccionado, en su pestaña general
  static void openBucketSettings(String bucket) {
    app.navigator.go(buckets, queryParameters: {bucketsBucketParam: bucket});
  }
}
