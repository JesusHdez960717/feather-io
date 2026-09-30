import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:service/feather.dart';
import 'package:test/test.dart';

const String testAccess = 'test_access';
const String testSecret = 'test_secret';

/// Servidor real para un fichero de tests: puerto propio, carpeta propia en
/// `./uploads_test/<name>` y BD SQLite en memoria.
class TestServer {
  final int port;
  final String storagePath;

  /// JWT obtenido en [start] con las credenciales de test.
  late final String token;

  TestServer({required this.port, required String name})
    : storagePath = './uploads_test/$name';

  Future<void> start() async {
    env.put('FEATHER_ACCESS', testAccess);
    env.put('FEATHER_SECRET', testSecret);
    env.put('JWT_SECRET', 'test-jwt-secret-$port');
    env.put('STORAGE_VOLUME_PATH', storagePath);

    await _deleteStorage();
    await FeatherIO.start(
      port: port,
      database: AppDatabase(NativeDatabase.memory()),
    );

    final login = await http.post(
      url('/${env.adminPrefix}/login'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'access': testAccess, 'secret': testSecret}),
    );
    expect(login.statusCode, 200, reason: 'login: ${login.body}');
    token = jsonDecode(login.body)['access_token'] as String;
  }

  Future<void> stop() async {
    await Winter.close(force: true);
    await _deleteStorage();
  }

  Uri url(String path) => Uri.parse('http://localhost:$port$path');

  /// Cabeceras con el JWT; [json] añade `Accept: application/json`.
  Map<String, String> auth({bool json = false}) => {
    'authorization': 'Bearer $token',
    if (json) 'accept': 'application/json',
  };

  /// Sube un objeto (y crea la carpeta del bucket si no existe).
  Future<void> putObject(String bucket, String key, String body) async {
    final response = await http.put(
      url('/$bucket/$key'),
      headers: auth(),
      body: body,
    );
    expect(response.statusCode, 200, reason: 'put $bucket/$key');
  }

  Future<void> _deleteStorage() async {
    final dir = Directory(storagePath);
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}
