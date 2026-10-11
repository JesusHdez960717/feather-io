import 'package:service/feather.dart';
import 'package:service/i18n/messages.g.dart';

export 'package:service/i18n/messages.g.dart' show ServiceMessages;

/// One instance per language, built once
final Map<ServiceMessagesLocale, ServiceMessages> _cache = {
  for (final locale in ServiceMessagesLocale.values) locale: locale.buildSync(),
};

/// Messages of the service in the language of the request in progress
/// (`requestLocale`, from `Accept-Language`; English outside a request).
///
/// A getter, never a `final`: it is evaluated on every use, with the locale of
/// that moment. A region uses its language (`es-MX` → `es`) and an unknown
/// language the base one (`en`).
ServiceMessages get intl =>
    _cache[AppLocaleUtils.parseLocaleParts(
      languageCode: requestLocale.languageCode,
      countryCode: requestLocale.countryCode,
    )]!;

/// The languages the service answers in (`Winter.context.setUp(localeConfig:)`).
LocaleConfig serviceLocales() => LocaleConfig(
  supported: [WinterLocale.english, WinterLocale.spanish],
  fallback: WinterLocale.english,
);
