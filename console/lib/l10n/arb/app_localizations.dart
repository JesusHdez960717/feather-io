import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'arb/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Feather IO'**
  String get appName;

  /// No description provided for @appNeedMoreSpace.
  ///
  /// In en, this message translates to:
  /// **'Need more space'**
  String get appNeedMoreSpace;

  /// No description provided for @splashTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get splashTitle;

  /// No description provided for @splashFooter.
  ///
  /// In en, this message translates to:
  /// **'With ♥ from Maple'**
  String get splashFooter;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// No description provided for @objects.
  ///
  /// In en, this message translates to:
  /// **'Objects'**
  String get objects;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get createdAt;

  /// No description provided for @lastModified.
  ///
  /// In en, this message translates to:
  /// **'Last Modified'**
  String get lastModified;

  /// No description provided for @errorRequestCancelled.
  ///
  /// In en, this message translates to:
  /// **'Request to API server was cancelled'**
  String get errorRequestCancelled;

  /// No description provided for @errorConnectionTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timeout with API server. Check your internet connection'**
  String get errorConnectionTimeout;

  /// No description provided for @errorNoConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection to API server failed due to internet connection'**
  String get errorNoConnection;

  /// No description provided for @errorReceiveTimeout.
  ///
  /// In en, this message translates to:
  /// **'Receive timeout in connection with API server'**
  String get errorReceiveTimeout;

  /// No description provided for @errorSendTimeout.
  ///
  /// In en, this message translates to:
  /// **'Send timeout with API server'**
  String get errorSendTimeout;

  /// No description provided for @errorBadCertificate.
  ///
  /// In en, this message translates to:
  /// **'Bad certificate'**
  String get errorBadCertificate;

  /// No description provided for @errorConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get errorConnection;

  /// No description provided for @errorValidation.
  ///
  /// In en, this message translates to:
  /// **'Validation error'**
  String get errorValidation;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'Server error'**
  String get errorServer;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get errorUnknown;

  /// No description provided for @navBrowser.
  ///
  /// In en, this message translates to:
  /// **'Browser'**
  String get navBrowser;

  /// No description provided for @loginAccessKey.
  ///
  /// In en, this message translates to:
  /// **'Access Key'**
  String get loginAccessKey;

  /// No description provided for @loginAccessKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your access key'**
  String get loginAccessKeyHint;

  /// No description provided for @loginSecretKey.
  ///
  /// In en, this message translates to:
  /// **'Secret Key'**
  String get loginSecretKey;

  /// No description provided for @loginSecretKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your secret key'**
  String get loginSecretKeyHint;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @loginInProgress.
  ///
  /// In en, this message translates to:
  /// **'Logging in...'**
  String get loginInProgress;

  /// No description provided for @bucketsTitle.
  ///
  /// In en, this message translates to:
  /// **'Buckets'**
  String get bucketsTitle;

  /// No description provided for @bucketsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your S3 compatible buckets and storage resources.'**
  String get bucketsSubtitle;

  /// No description provided for @bucketsCreate.
  ///
  /// In en, this message translates to:
  /// **'Create Bucket'**
  String get bucketsCreate;

  /// No description provided for @bucketsTotalBuckets.
  ///
  /// In en, this message translates to:
  /// **'Total Buckets'**
  String get bucketsTotalBuckets;

  /// No description provided for @bucketsTotalObjects.
  ///
  /// In en, this message translates to:
  /// **'Total Objects'**
  String get bucketsTotalObjects;

  /// No description provided for @bucketsTotalStorage.
  ///
  /// In en, this message translates to:
  /// **'Total Storage'**
  String get bucketsTotalStorage;

  /// No description provided for @bucketsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search buckets...'**
  String get bucketsSearchHint;

  /// No description provided for @bucketsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No buckets found'**
  String get bucketsEmpty;

  /// No description provided for @bucketsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No buckets matching \"{query}\"'**
  String bucketsNoMatch(String query);

  /// No description provided for @bucketsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete bucket'**
  String get bucketsDeleteTitle;

  /// No description provided for @bucketsDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the {name} bucket?'**
  String bucketsDeleteConfirm(String name);

  /// No description provided for @bucketsReadWriteBadge.
  ///
  /// In en, this message translates to:
  /// **'R/W'**
  String get bucketsReadWriteBadge;

  /// No description provided for @bucketsReadWriteTooltip.
  ///
  /// In en, this message translates to:
  /// **'You have read and write access to this bucket'**
  String get bucketsReadWriteTooltip;

  /// No description provided for @bucketsCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Created {date}'**
  String bucketsCreatedAt(String date);

  /// No description provided for @bucketCreateDescription.
  ///
  /// In en, this message translates to:
  /// **'Configure high-performance object storage parameters, redundancy, and protection policies.'**
  String get bucketCreateDescription;

  /// No description provided for @bucketCreateSectionGeneral.
  ///
  /// In en, this message translates to:
  /// **'01 General Configuration'**
  String get bucketCreateSectionGeneral;

  /// No description provided for @bucketCreateSectionAdditional.
  ///
  /// In en, this message translates to:
  /// **'02 Additional Info'**
  String get bucketCreateSectionAdditional;

  /// No description provided for @bucketCreateNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Bucket Identifier'**
  String get bucketCreateNameLabel;

  /// No description provided for @bucketCreateNameHint.
  ///
  /// In en, this message translates to:
  /// **'my-bucket-name'**
  String get bucketCreateNameHint;

  /// No description provided for @bucketCreateDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get bucketCreateDescriptionLabel;

  /// No description provided for @bucketCreateDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Brief description of the bucket usage'**
  String get bucketCreateDescriptionHint;

  /// No description provided for @bucketNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Bucket name is required'**
  String get bucketNameRequired;

  /// No description provided for @bucketNameLength.
  ///
  /// In en, this message translates to:
  /// **'Between 3 and 63 characters'**
  String get bucketNameLength;

  /// No description provided for @bucketNameChars.
  ///
  /// In en, this message translates to:
  /// **'Lowercase, numbers and hyphens only'**
  String get bucketNameChars;

  /// No description provided for @bucketNameHyphenEdges.
  ///
  /// In en, this message translates to:
  /// **'Cannot start or end with a hyphen'**
  String get bucketNameHyphenEdges;

  /// No description provided for @bucketRuleChars.
  ///
  /// In en, this message translates to:
  /// **'Lowercase, numbers and hyphens only'**
  String get bucketRuleChars;

  /// No description provided for @bucketRuleHyphenEdges.
  ///
  /// In en, this message translates to:
  /// **'No hyphen at start/end'**
  String get bucketRuleHyphenEdges;

  /// No description provided for @objectsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search objects...'**
  String get objectsSearchHint;

  /// No description provided for @objectsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No objects found'**
  String get objectsEmpty;

  /// No description provided for @objectsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No objects matching \"{query}\"'**
  String objectsNoMatch(String query);

  /// No description provided for @objectsDragHint.
  ///
  /// In en, this message translates to:
  /// **'Drag files here to upload'**
  String get objectsDragHint;

  /// No description provided for @objectsDropHere.
  ///
  /// In en, this message translates to:
  /// **'Drop here to upload'**
  String get objectsDropHere;

  /// No description provided for @objectsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete objects'**
  String get objectsDeleteTitle;

  /// No description provided for @objectsDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Are you sure you want to delete 1 object?} other{Are you sure you want to delete {count} objects?}}'**
  String objectsDeleteConfirm(int count);

  /// No description provided for @objectsUploadFiles.
  ///
  /// In en, this message translates to:
  /// **'Upload files'**
  String get objectsUploadFiles;

  /// No description provided for @objectsUploadDirectory.
  ///
  /// In en, this message translates to:
  /// **'Upload directory'**
  String get objectsUploadDirectory;

  /// No description provided for @fileTypeFolder.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get fileTypeFolder;

  /// No description provided for @fileTypeFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get fileTypeFile;

  /// No description provided for @fileTypeImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get fileTypeImage;

  /// No description provided for @fileTypeVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get fileTypeVideo;

  /// No description provided for @fileTypeAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get fileTypeAudio;

  /// No description provided for @fileTypeText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get fileTypeText;

  /// No description provided for @fileTypeDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get fileTypeDocument;

  /// No description provided for @fileTypeSpreadsheet.
  ///
  /// In en, this message translates to:
  /// **'Spreadsheet'**
  String get fileTypeSpreadsheet;

  /// No description provided for @fileTypeArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get fileTypeArchive;

  /// No description provided for @colorNone.
  ///
  /// In en, this message translates to:
  /// **'No color'**
  String get colorNone;

  /// No description provided for @colorCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom color'**
  String get colorCustom;

  /// No description provided for @colorApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get colorApply;

  /// No description provided for @colorSaturationBrightness.
  ///
  /// In en, this message translates to:
  /// **'Saturation and brightness'**
  String get colorSaturationBrightness;

  /// No description provided for @colorHue.
  ///
  /// In en, this message translates to:
  /// **'Hue'**
  String get colorHue;

  /// No description provided for @colorContrast.
  ///
  /// In en, this message translates to:
  /// **'Icon contrast: {ratio}:1'**
  String colorContrast(String ratio);

  /// No description provided for @colorContrastLow.
  ///
  /// In en, this message translates to:
  /// **'Low contrast with the icon ({ratio}:1)'**
  String colorContrastLow(String ratio);

  /// No description provided for @colorHexInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a 6-digit HEX color, for example #0E7490'**
  String get colorHexInvalid;

  /// No description provided for @colorViolet.
  ///
  /// In en, this message translates to:
  /// **'Violet'**
  String get colorViolet;

  /// No description provided for @colorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get colorBlue;

  /// No description provided for @colorTeal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get colorTeal;

  /// No description provided for @colorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colorGreen;

  /// No description provided for @colorAmber.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get colorAmber;

  /// No description provided for @colorRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get colorRed;

  /// No description provided for @colorPink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get colorPink;

  /// No description provided for @colorSlate.
  ///
  /// In en, this message translates to:
  /// **'Slate'**
  String get colorSlate;

  /// No description provided for @bucketCreateColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get bucketCreateColorLabel;

  /// No description provided for @bucketNameExists.
  ///
  /// In en, this message translates to:
  /// **'A bucket with this name already exists'**
  String get bucketNameExists;

  /// No description provided for @bucketCreateErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the bucket'**
  String get bucketCreateErrorTitle;

  /// No description provided for @bucketCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Bucket \"{name}\" created'**
  String bucketCreatedSuccess(String name);

  /// No description provided for @bucketNamePathHint.
  ///
  /// In en, this message translates to:
  /// **'Used in S3 paths: /{name}'**
  String bucketNamePathHint(String name);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
