import 'package:service/feather.dart';

/// Asks for a presigned URL to download [key] for [expiresIn] seconds.
class PresignRequest implements Validatable {
  final String? key;
  final int? expiresIn;

  PresignRequest({this.key, this.expiresIn});

  /// The example of the OpenAPI document.
  static final PresignRequest example = PresignRequest(
    key: 'photos/beach.jpg',
    expiresIn: 3600,
  );

  factory PresignRequest.fromJson(Map<String, dynamic> json) {
    return PresignRequest(
      key: json.field<String?>('key'),
      expiresIn: json.field<int?>('expires_in'),
    );
  }

  @override
  ConstraintValidatorContext validate() => ConstraintValidatorContext()
    ..field('key', key).notNull().size(min: 1, max: 1024)
    ..field(
      'expires_in',
      expiresIn,
    ).notNull().min(1).max(SigV4Signer.maxExpiration.inSeconds);

  Map<String, Object?> toJson() {
    return {'key': key, 'expires_in': expiresIn};
  }
}
