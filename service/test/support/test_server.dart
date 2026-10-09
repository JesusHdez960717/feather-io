import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:service/feather.dart';
import 'package:test/test.dart';

const String testAccess = 'test_access';
const String testSecret = 'test_secret';

/// Real server for a test file: its own port, its own folder in
/// `./uploads_test/<name>` and an in-memory SQLite database (or, with
/// [fileDatabase], the real one inside that folder).
class TestServer {
  final int port;
  final String storagePath;
  final bool fileDatabase;

  /// JWT obtained in [start] with the test credentials.
  late final String token;

  TestServer({
    required this.port,
    required String name,
    this.fileDatabase = false,
  }) : storagePath = './uploads_test/$name';

  Future<void> start() async {
    env.put('FEATHER_ACCESS', testAccess);
    env.put('FEATHER_SECRET', testSecret);
    env.put('JWT_SECRET', 'test-jwt-secret-$port');
    env.put('KEYS_ENCRYPTION_SECRET', 'test-keys-secret-$port');
    env.put('STORAGE_VOLUME_PATH', storagePath);
    // Only problems: every request would otherwise write two lines
    env.put('LOG_LEVEL', 'warning');

    await _deleteStorage();
    await FeatherIO.start(
      port: port,
      database: fileDatabase ? null : AppDatabase(NativeDatabase.memory()),
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
    // On Windows an open file can't be deleted
    if (fileDatabase) await di.find<AppDatabase>().close();
    await _deleteStorage();
  }

  Uri url(String path) => Uri.parse('http://localhost:$port$path');

  /// Headers with the JWT; [json] adds `Accept: application/json`.
  Map<String, String> auth({bool json = false}) => {
    'authorization': 'Bearer $token',
    if (json) 'accept': 'application/json',
  };

  /// Headers of a native S3 client: a SigV4 signature with the test keys.
  /// [path] goes as it is in the URL (already encoded). [at] changes the
  /// signature date (now by default) and [payloadHash] signs the body's sha256
  /// instead of `UNSIGNED-PAYLOAD`. [access] and [secret] sign with another
  /// key (an access key created in the test).
  Map<String, String> sigV4(
    String method,
    String path, {
    Map<String, String> query = const {},
    DateTime? at,
    String payloadHash = SigV4Signer.unsignedPayload,
    String access = testAccess,
    String secret = testSecret,
    Map<String, String> extraHeaders = const {},
  }) {
    final now = (at ?? DateTime.now()).toUtc();
    final amzDate = SigV4Signer.amzDate(now);
    final scope = SigV4Signer.scope(SigV4Signer.dateStamp(now));
    final headers = {
      'host': 'localhost:$port',
      'x-amz-date': amzDate,
      'x-amz-content-sha256': payloadHash,
      ...extraHeaders,
    };
    final signedHeaders = (headers.keys.toList()..sort()).join(';');
    final signature = SigV4Signer.signature(
      secret: secret,
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
          '${SigV4Signer.algorithm} Credential=$access/$scope, '
          'SignedHeaders=$signedHeaders, Signature=$signature',
    };
  }

  /// Creates the bucket unless it exists (a 409 means it was already there).
  Future<void> createBucket(String bucket) async {
    final response = await http.put(url('/$bucket'), headers: auth());
    expect(
      response.statusCode,
      anyOf(200, 409),
      reason: 'create $bucket: ${response.body}',
    );
  }

  /// Uploads an object (creating the bucket if needed). It goes as bytes
  /// without `Content-Type` (with a String, package:http would send
  /// `text/plain`), so on read the type comes from the extension. [headers] are
  /// added to the upload.
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
