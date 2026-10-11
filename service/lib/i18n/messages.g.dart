/// Generated file. Do not edit.
///
/// Source: lib/i18n
/// To regenerate, run: `dart run slang`

// coverage:ignore-file
// ignore_for_file: type=lint, unused_import

import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'package:slang/slang.dart';
export 'package:slang/slang.dart';

import 'messages_es.g.dart' as l_es;
part 'messages_en.g.dart';

/// Supported locales.
///
/// Usage:
/// - LocaleSettings.setLocale(ServiceMessagesLocale.en) // set locale
/// - Locale locale = ServiceMessagesLocale.en.flutterLocale // get flutter locale from enum
/// - if (LocaleSettings.currentLocale == ServiceMessagesLocale.en) // locale check
enum ServiceMessagesLocale
    with BaseAppLocale<ServiceMessagesLocale, ServiceMessages> {
  en(languageCode: 'en'),
  es(languageCode: 'es');

  const ServiceMessagesLocale({
    required this.languageCode,
    this.scriptCode, // ignore: unused_element, unused_element_parameter
    this.countryCode, // ignore: unused_element, unused_element_parameter
  });

  @override
  final String languageCode;
  @override
  final String? scriptCode;
  @override
  final String? countryCode;

  @override
  Future<ServiceMessages> build({
    Map<String, Node>? overrides,
    PluralResolver? cardinalResolver,
    PluralResolver? ordinalResolver,
  }) async {
    return buildSync(
      overrides: overrides,
      cardinalResolver: cardinalResolver,
      ordinalResolver: ordinalResolver,
    );
  }

  @override
  ServiceMessages buildSync({
    Map<String, Node>? overrides,
    PluralResolver? cardinalResolver,
    PluralResolver? ordinalResolver,
  }) {
    switch (this) {
      case ServiceMessagesLocale.en:
        return ServiceMessagesEn(
          overrides: overrides,
          cardinalResolver: cardinalResolver,
          ordinalResolver: ordinalResolver,
        );
      case ServiceMessagesLocale.es:
        return l_es.ServiceMessagesEs(
          overrides: overrides,
          cardinalResolver: cardinalResolver,
          ordinalResolver: ordinalResolver,
        );
    }
  }
}

/// Provides utility functions without any side effects.
class AppLocaleUtils
    extends BaseAppLocaleUtils<ServiceMessagesLocale, ServiceMessages> {
  AppLocaleUtils._()
    : super(
        baseLocale: ServiceMessagesLocale.en,
        locales: ServiceMessagesLocale.values,
      );

  static final instance = AppLocaleUtils._();

  // static aliases (checkout base methods for documentation)
  static ServiceMessagesLocale parse(String rawLocale) =>
      instance.parse(rawLocale);
  static ServiceMessagesLocale parseLocaleParts({
    required String languageCode,
    String? scriptCode,
    String? countryCode,
  }) => instance.parseLocaleParts(
    languageCode: languageCode,
    scriptCode: scriptCode,
    countryCode: countryCode,
  );
  static List<String> get supportedLocalesRaw => instance.supportedLocalesRaw;
}
