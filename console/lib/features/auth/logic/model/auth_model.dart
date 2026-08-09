class AuthModel {
  final String accessToken;
  final DateTime expireAt;
  final String accessKey;
  final String secretKey;

  AuthModel({
    required this.accessToken,
    required this.expireAt,
    required this.accessKey,
    required this.secretKey,
  });

  bool get isExpired => DateTime.now().isAfter(expireAt);
}
