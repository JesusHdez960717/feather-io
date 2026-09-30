///Cuanto dura un enlace compartido
enum ShareLinkExpiration {
  hour(Duration(hours: 1)),
  day(Duration(days: 1)),
  week(Duration(days: 7));

  final Duration duration;

  const ShareLinkExpiration(this.duration);
}

///Enlace (URL prefirmada) para descargar un objeto sin credenciales
class SharedLinkModel {
  final String url;
  final DateTime expiresAt;

  SharedLinkModel({required this.url, required this.expiresAt});
}
