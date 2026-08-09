import 'package:console/app_exporter.dart';
import '../rest/auth_client.dart';
import '../../logic/model/auth_model.dart';

class AuthRepo {
  final AuthClient client;

  AuthRepo(this.client);

  Future<AuthModel> login({
    required String access,
    required String secret,
  }) async {
    try {
      final response = await client.login(
        LoginRequest(access: access, secret: secret),
      );
      return response.toModel(access, secret);
    } catch (e) {
      throw ExceptionConverter.parse(e);
    }
  }
}

extension LoginResponseMapping on LoginResponse {
  AuthModel toModel(String accessKey, String secretKey) {
    return AuthModel(
      accessToken: accessToken,
      expireAt: expireAt,
      accessKey: accessKey,
      secretKey: secretKey,
    );
  }
}
