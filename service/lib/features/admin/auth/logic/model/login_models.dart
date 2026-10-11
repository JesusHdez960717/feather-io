import 'package:service/feather.dart';

class LoginRequest {
  final String access;
  final String secret;

  LoginRequest({required this.access, required this.secret});

  factory LoginRequest.fromJson(Map<String, dynamic> json) {
    return LoginRequest(
      access: json.field<String>('access'),
      secret: json.field<String>('secret'),
    );
  }

  /// The example of the OpenAPI document (a request body only: no secret is
  /// ever written).
  static const Map<String, Object?> example = {
    'access': 'feather-access',
    'secret': 'feather-secret-key',
  };
}

class LoginResponse {
  final String accessToken;
  final int expiresIn;
  final DateTime expireAt;

  LoginResponse({
    required this.accessToken,
    required this.expiresIn,
    required this.expireAt,
  });

  /// The example of the OpenAPI document.
  static final LoginResponse example = LoginResponse(
    accessToken: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9…',
    expiresIn: const Duration(hours: 12).inMilliseconds,
    expireAt: DateTime.utc(2026, 10, 9, 12),
  );

  Map<String, Object?> toJson() {
    return {
      'access_token': accessToken,
      'expires_in': expiresIn,
      'expire_at': expireAt.millisecondsSinceEpoch,
    };
  }
}
