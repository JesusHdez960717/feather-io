import 'package:service/feather.dart';

/// Pide una URL prefirmada para descargar [key] durante [expiresIn] segundos
class PresignRequest implements Validatable {
  final String? key;
  final int? expiresIn;

  PresignRequest({this.key, this.expiresIn});

  factory PresignRequest.fromJson(Map<String, dynamic> json) {
    return PresignRequest(
      key: json['key'] as String?,
      expiresIn: json['expires_in'] as int?,
    );
  }

  @override
  ConstraintValidatorContext validate() {
    final cvc = ConstraintValidatorContext();

    cvc.buildValidator('key').notNull().size(min: 1, max: 1024).validate(key);

    cvc
        .buildValidator('expires_in')
        .notNull()
        .min(1)
        .max(SigV4Signer.maxExpiration.inSeconds)
        .validate(expiresIn);

    return cvc;
  }
}
