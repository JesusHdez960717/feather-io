import 'package:console/app_exporter.dart';

///Que le ha pasado a un bucket
enum BucketChange {
  created,

  ///Cambio su descripcion o su color
  updated,

  ///Se borraron todos sus objetos
  emptied,
  deleted,

  ///Se subieron o borraron objetos (cambian sus estadisticas)
  objectsChanged,
}

///Aviso por el bus global de que un bucket ha cambiado. Cada seccion
///(explorador, *Buckets*) tiene sus propios cubits y con esto se mantienen al dia
class BucketChangedEvent {
  ///El cubit que hizo el cambio: ya se actualiza por su cuenta y lo ignora
  final Object source;
  final BucketChange change;
  final String bucketName;

  ///El bucket ya actualizado, en [BucketChange.updated]
  final BucketModel? bucket;

  const BucketChangedEvent({
    required this.source,
    required this.change,
    required this.bucketName,
    this.bucket,
  });
}
