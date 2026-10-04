import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

/// Encrypts the secrets of the access keys before they reach the database
/// (AES-256-GCM). SigV4 signs with the secret itself, so it can't be stored as
/// a hash like a password: the service needs it back to check each signature.
///
/// The key is the sha256 of `KEYS_ENCRYPTION_SECRET`. Each value carries its
/// random nonce (`base64(nonce + ciphertext + tag)`), and [associatedData]
/// (the access key id) binds it to its row: a secret copied onto another key
/// doesn't decrypt.
class SecretCipher {
  static const int _nonceLength = 12;
  static const int _tagBits = 128;

  final Uint8List _key;
  final Random _random = Random.secure();

  SecretCipher(String passphrase)
    : _key = Uint8List.fromList(sha256.convert(utf8.encode(passphrase)).bytes);

  String encrypt(String plain, {required String associatedData}) {
    final nonce = Uint8List.fromList(
      List.generate(_nonceLength, (_) => _random.nextInt(256)),
    );
    final sealed = _cipher(
      forEncryption: true,
      nonce: nonce,
      associatedData: associatedData,
    ).process(Uint8List.fromList(utf8.encode(plain)));
    return base64.encode([...nonce, ...sealed]);
  }

  /// Throws if [stored] was altered, belongs to another key or was encrypted
  /// with another `KEYS_ENCRYPTION_SECRET`.
  String decrypt(String stored, {required String associatedData}) {
    final bytes = base64.decode(stored);
    if (bytes.length <= _nonceLength) {
      throw const FormatException('Encrypted secret too short');
    }
    final plain = _cipher(
      forEncryption: false,
      nonce: Uint8List.sublistView(bytes, 0, _nonceLength),
      associatedData: associatedData,
    ).process(Uint8List.sublistView(bytes, _nonceLength));
    return utf8.decode(plain);
  }

  GCMBlockCipher _cipher({
    required bool forEncryption,
    required Uint8List nonce,
    required String associatedData,
  }) {
    return GCMBlockCipher(AESEngine())..init(
      forEncryption,
      AEADParameters(
        KeyParameter(_key),
        _tagBits,
        nonce,
        Uint8List.fromList(utf8.encode(associatedData)),
      ),
    );
  }
}
