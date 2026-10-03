/// How long a shared link lasts
enum ShareLinkExpiration {
  hour(Duration(hours: 1)),
  day(Duration(days: 1)),
  week(Duration(days: 7));

  final Duration duration;

  const ShareLinkExpiration(this.duration);
}

/// Link (presigned URL) to download an object without credentials
class SharedLinkModel {
  final String url;
  final DateTime expiresAt;

  SharedLinkModel({required this.url, required this.expiresAt});
}
