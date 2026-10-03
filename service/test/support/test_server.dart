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

  /// Cabeceras de un cliente S3 nativo: firma SigV4 con las claves de test.
  /// [path] va tal cual en la URL (ya codificado). [at] cambia la fecha de la
  /// firma (ahora por defecto) y [payloadHash] firma el sha256 del cuerpo en
  /// vez de `UNSIGNED-PAYLOAD`.
  Map<String, String> sigV4(
    String method,
    String path, {
    Map<String, String> query = const {},
    DateTime? at,
    String payloadHash = SigV4Signer.unsignedPayload,
  }) {
    final now = (at ?? DateTime.now()).toUtc();
    final amzDate = SigV4Signer.amzDate(now);
    final scope = SigV4Signer.scope(SigV4Signer.dateStamp(now));
    final headers = {
      'host': 'localhost:$port',
      'x-amz-date': amzDate,
      'x-amz-content-sha256': payloadHash,
    };
    const signedHeaders = 'host;x-amz-content-sha256;x-amz-date';
    final signature = SigV4Signer.signature(
      secret: testSecret,
      amzDate: amzDate,
      scope: scope,
      canonicalRequest: SigV4Signer.canonicalRequest(
        method: method,
        path: path,
        query: query,
        headers: headers,
        signedHeaders: signedHeaders,
        payloadHash: payloadHash,
      ),
    );
    return {
      ...headers,
      'authorization':
          '${SigV4Signer.algorithm} Credential=$testAccess/$scope, '
          'SignedHeaders=$signedHeaders, Signature=$signature',
    };
  }

  /// Crea el bucket si no existe (un 409 es que ya estaba).
  Future<void> createBucket(String bucket) async {
    final response = await http.put(url('/$bucket'), headers: auth());
    expect(
      response.statusCode,
      anyOf(200, 409),
      reason: 'create $bucket: ${response.body}',
    );
  }

  /// Sube un objeto (y crea el bucket si no existe). Va en bytes y sin
  /// `Content-Type` (con un String, package:http mandaria `text/plain`), asi
  /// que al leerlo el tipo sale de la extension. [headers] se añaden a la subida
  Future<void> putObject(
    String bucket,
    String key,
    String body, {
    Map<String, String> headers = const {},
  }) async {
    await createBucket(bucket);
    final response = await http.put(
      url('/$bucket/$key'),
      headers: {...auth(), ...headers},
      body: utf8.encode(body),
    );
    expect(response.statusCode, 200, reason: 'put $bucket/$key');
  }

  Future<void> _deleteStorage() async {
    final dir = Directory(storagePath);
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}
