/// Session of the console: the JWT of the login and when it expires. The keys
/// typed at login are not kept (the JWT is enough, and the secret must not
/// reach the browser's storage)
class AuthModel {
  final String accessToken;
  final DateTime expireAt;

  AuthModel({required this.accessToken, required this.expireAt});

  bool get isExpired => DateTime.now().isAfter(expireAt);
}
