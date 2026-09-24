import 'package:console/app_exporter.dart';
import 'package:dio/dio.dart';

class AuthClient extends BaseClient {
  @override
  String get baseUrl => Environment.serviceUrl;

  AuthClient(super.dio);

  Future<LoginResponse> login(LoginRequest request) async {
    final admin = Environment.adminPrefix;
    Response rawResponse = await dio.post(
      '$baseUrl/$admin/login',
      data: request.toJson(),
      options: options(),
    );

    return LoginResponse.fromJson(rawResponse.data);
  }
}

//---------- LOGIN REQUEST ----------
class LoginRequest {
  final String access;
  final String secret;

  LoginRequest({required this.access, required this.secret});

  Map<String, dynamic> toJson() {
    return {'access': access, 'secret': secret};
  }
}

//---------- LOGIN RESPONSE ----------
class LoginResponse {
  final String accessToken;
  final int expiresIn;
  final DateTime expireAt;

  LoginResponse({
    required this.accessToken,
    required this.expiresIn,
    required this.expireAt,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access_token'],
      expiresIn: json['expires_in'],
      expireAt: DateTime.fromMillisecondsSinceEpoch(json['expire_at']),
    );
  }
}
