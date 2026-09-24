import 'package:service/feather.dart';

class LoginRequest {
  final String access;
  final String secret;

  LoginRequest({required this.access, required this.secret});

  factory LoginRequest.fromJson(Map<String, dynamic> json) {
    return LoginRequest(
      access: json['access'] as String,
      secret: json['secret'] as String,
    );
  }
}

class LoginResponse implements Serializable {
  final String accessToken;
  final int expiresIn;
  final DateTime expireAt;

  LoginResponse({
    required this.accessToken,
    required this.expiresIn,
    required this.expireAt,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'expires_in': expiresIn,
      'expire_at': expireAt.millisecondsSinceEpoch,
    };
  }
}
