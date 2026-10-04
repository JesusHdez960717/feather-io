import 'dart:math';

import 'package:service/feather.dart';

/// Access keys for native S3 clients. The root key (`FEATHER_ACCESS`) is not
/// one of them: it lives in the env and only it opens the console.
class AccessKeyService {
  /// Prefix of every generated access key id.
  static const String idPrefix = 'FIOK';

  /// Characters after [idPrefix] (20 in all, like AWS's).
  static const int idRandomLength = 16;

  static const int secretLength = 40;

  /// `lastUsedAt` is saved at most this often per key, not on every request.
  static const Duration lastUsedPrecision = Duration(minutes: 1);

  static const String _idAlphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  static const String _secretAlphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

  final AccessKeyTableRepo repo;
  final FileManagementService fileManagement;
  final SecretCipher cipher;

  final Random _random = Random.secure();

  /// Last `lastUsedAt` saved per key, so a burst of requests writes once.
  static final Map<String, DateTime> _lastTouched = {};

  AccessKeyService()
    : repo = AccessKeyTableRepo(di.find()),
      fileManagement = di.find(),
      cipher = di.find();

  Future<AccessKeyListModel> list() async {
    final rows = await repo.getAll();
    return AccessKeyListModel(
      rootAccessKeyId: env.access,
      keys: rows.map(_toModel).toList(),
    );
  }

  /// Creates the key; the result carries the secret, which is never shown again.
  Future<AccessKeyModel> create(AccessKeyRequest request) async {
    final expiresAt = request.expiresAtDate;
    _checkFutureExpiry(expiresAt);
    final grants = request.grants;
    await _checkBuckets(grants);

    final id = await _newId();
    final secret = _randomString(_secretAlphabet, secretLength);
    await repo.insert(
      id: id,
      name: request.name!.trim(),
      secretEncrypted: cipher.encrypt(secret, associatedData: id),
      allBuckets: request.allBucketsLevel,
      grants: grants,
      expiresAt: expiresAt,
    );
    return (await _get(id)).withSecret(secret);
  }

  /// Replaces the name, state, scope and expiration. The secret stays.
  Future<AccessKeyModel> update(String id, AccessKeyRequest request) async {
    final current = await _get(id);
    final expiresAt = request.expiresAtDate;
    // An expired key can be renamed without moving its date
    if (expiresAt != current.expiresAt) _checkFutureExpiry(expiresAt);
    final grants = request.grants;
    await _checkBuckets(grants);

    await repo.update(
      id: id,
      name: request.name!.trim(),
      enabled: request.enabled ?? current.enabled,
      allBuckets: request.allBucketsLevel,
      grants: grants,
      expiresAt: expiresAt,
    );
    return _get(id);
  }

  /// A new secret for the key: the old one stops working at once.
  Future<AccessKeyModel> regenerateSecret(String id) async {
    final key = await _get(id);
    final secret = _randomString(_secretAlphabet, secretLength);
    await repo.updateSecret(
      id: id,
      secretEncrypted: cipher.encrypt(secret, associatedData: id),
    );
    return key.withSecret(secret);
  }

  Future<void> delete(String id) async {
    await _get(id);
    await repo.delete(id);
    _lastTouched.remove(id);
  }

  /// The key [id] with its secret in plain text, to check a signature, or null
  /// if it doesn't exist. Throws if the secret can't be decrypted (another
  /// `KEYS_ENCRYPTION_SECRET`, or the row was altered).
  Future<({AccessKeyModel key, String secret})?> findForSignature(
    String id,
  ) async {
    final row = await repo.get(id);
    if (row == null) return null;
    return (
      key: _toModel(row),
      secret: cipher.decrypt(row.key.secretEncrypted, associatedData: id),
    );
  }

  /// Records that the key signed a request, at most every [lastUsedPrecision].
  Future<void> touch(String id) async {
    final now = DateTime.now();
    final last = _lastTouched[id];
    if (last != null && now.difference(last) < lastUsedPrecision) return;
    _lastTouched[id] = now;
    await repo.updateLastUsed(id: id, at: now);
  }

  Future<AccessKeyModel> _get(String id) async {
    final row = await repo.get(id);
    if (row == null) throw NotFoundException(body: 'Access key not found');
    return _toModel(row);
  }

  AccessKeyModel _toModel(AccessKeyRow row) {
    return AccessKeyModel(
      id: row.key.id,
      name: row.key.name,
      enabled: row.key.enabled,
      allBuckets: row.key.allBuckets,
      grants: [
        for (final grant in row.grants)
          AccessKeyGrant(grant.bucketName, grant.access),
      ]..sort((a, b) => a.bucket.compareTo(b.bucket)),
      expiresAt: row.key.expiresAt,
      createdAt: row.key.createdAt,
      lastUsedAt: row.key.lastUsedAt,
    );
  }

  void _checkFutureExpiry(DateTime? expiresAt) {
    if (expiresAt != null && !expiresAt.isAfter(DateTime.now())) {
      throw ValidationException(
        violations: [
          ConstrainViolation(
            value: expiresAt.toIso8601String(),
            fieldName: 'expires_at',
            message: 'The expiration date must be in the future',
          ),
        ],
      );
    }
  }

  Future<void> _checkBuckets(List<AccessKeyGrant> grants) async {
    for (final grant in grants) {
      if (!await fileManagement.bucketExists(grant.bucket)) {
        throw S3Exception.noSuchBucket(grant.bucket);
      }
    }
  }

  Future<String> _newId() async {
    while (true) {
      final id = idPrefix + _randomString(_idAlphabet, idRandomLength);
      if (id != env.access && await repo.get(id) == null) return id;
    }
  }

  String _randomString(String alphabet, int length) => String.fromCharCodes(
    List.generate(
      length,
      (_) => alphabet.codeUnitAt(_random.nextInt(alphabet.length)),
    ),
  );
}
