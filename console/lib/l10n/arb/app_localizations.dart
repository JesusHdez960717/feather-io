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

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

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

  /// No description provided for @bucketsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Bucket'**
  String get bucketsEdit;

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

  /// No description provided for @objectsNoMatchFilter.
  ///
  /// In en, this message translates to:
  /// **'No objects match the filters'**
  String get objectsNoMatchFilter;

  /// No description provided for @objectsFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get objectsFilterTitle;

  /// No description provided for @objectsFilterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get objectsFilterClear;

  /// No description provided for @objectsFilterType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get objectsFilterType;

  /// No description provided for @objectsFilterTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get objectsFilterTypeOther;

  /// No description provided for @objectsFilterSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get objectsFilterSize;

  /// No description provided for @objectsFilterSizeSmall.
  ///
  /// In en, this message translates to:
  /// **'Under 1 MB'**
  String get objectsFilterSizeSmall;

  /// No description provided for @objectsFilterSizeMedium.
  ///
  /// In en, this message translates to:
  /// **'1 MB – 100 MB'**
  String get objectsFilterSizeMedium;

  /// No description provided for @objectsFilterSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Over 100 MB'**
  String get objectsFilterSizeLarge;

  /// No description provided for @objectsFilterModified.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get objectsFilterModified;

  /// No description provided for @objectsFilterDate24h.
  ///
  /// In en, this message translates to:
  /// **'Last 24 hours'**
  String get objectsFilterDate24h;

  /// No description provided for @objectsFilterDate7d.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get objectsFilterDate7d;

  /// No description provided for @objectsFilterDate30d.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get objectsFilterDate30d;

  /// No description provided for @objectsFilterDateOlder.
  ///
  /// In en, this message translates to:
  /// **'Older than 30 days'**
  String get objectsFilterDateOlder;

  /// No description provided for @objectsFilterFoldersHidden.
  ///
  /// In en, this message translates to:
  /// **'Folders are hidden while a filter is active.'**
  String get objectsFilterFoldersHidden;

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

  /// No description provided for @bucketEditDescription.
  ///
  /// In en, this message translates to:
  /// **'Change the description and color of the {name} bucket. The name can\'t be changed.'**
  String bucketEditDescription(String name);

  /// No description provided for @bucketEditSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get bucketEditSave;

  /// No description provided for @bucketEditErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the bucket'**
  String get bucketEditErrorTitle;

  /// No description provided for @bucketUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Bucket \"{name}\" updated'**
  String bucketUpdatedSuccess(String name);

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

  /// No description provided for @navBuckets.
  ///
  /// In en, this message translates to:
  /// **'Buckets'**
  String get navBuckets;

  /// No description provided for @bucketAdminCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 bucket} other{{count} buckets}}'**
  String bucketAdminCount(int count);

  /// No description provided for @bucketAdminStats.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 object} other{{count} objects}} · {size}'**
  String bucketAdminStats(int count, String size);

  /// No description provided for @bucketAdminEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a bucket to configure it here.'**
  String get bucketAdminEmptyDescription;

  /// No description provided for @bucketAdminOpenInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get bucketAdminOpenInBrowser;

  /// No description provided for @bucketAdminTabGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get bucketAdminTabGeneral;

  /// No description provided for @bucketAdminTabAccess.
  ///
  /// In en, this message translates to:
  /// **'Anonymous access'**
  String get bucketAdminTabAccess;

  /// No description provided for @bucketAdminTabDanger.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get bucketAdminTabDanger;

  /// No description provided for @bucketDetailObjects.
  ///
  /// In en, this message translates to:
  /// **'Objects'**
  String get bucketDetailObjects;

  /// No description provided for @bucketDetailSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get bucketDetailSize;

  /// No description provided for @bucketDetailCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get bucketDetailCreated;

  /// No description provided for @bucketDetailLastModified.
  ///
  /// In en, this message translates to:
  /// **'Last modified'**
  String get bucketDetailLastModified;

  /// No description provided for @bucketDetailNeverModified.
  ///
  /// In en, this message translates to:
  /// **'No objects'**
  String get bucketDetailNeverModified;

  /// No description provided for @bucketDetailName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get bucketDetailName;

  /// No description provided for @bucketDetailS3Path.
  ///
  /// In en, this message translates to:
  /// **'S3 path'**
  String get bucketDetailS3Path;

  /// No description provided for @bucketDetailCopyPath.
  ///
  /// In en, this message translates to:
  /// **'Copy path'**
  String get bucketDetailCopyPath;

  /// No description provided for @bucketDetailPathCopied.
  ///
  /// In en, this message translates to:
  /// **'Path copied'**
  String get bucketDetailPathCopied;

  /// No description provided for @bucketDetailDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get bucketDetailDescription;

  /// No description provided for @bucketDetailNoDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get bucketDetailNoDescription;

  /// No description provided for @bucketDetailColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get bucketDetailColor;

  /// No description provided for @bucketEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Empty bucket'**
  String get bucketEmptyTitle;

  /// No description provided for @bucketEmptyAlreadyEmpty.
  ///
  /// In en, this message translates to:
  /// **'The bucket has no objects.'**
  String get bucketEmptyAlreadyEmpty;

  /// No description provided for @bucketEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Deletes {count, plural, =1{its only object} other{its {count} objects}} ({size}). The bucket, its settings and its access rules are kept. This can\'t be undone.'**
  String bucketEmptyDescription(int count, String size);

  /// No description provided for @bucketEmptyConfirm.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 object} other{{count} objects}} ({size}) will be deleted from {name}. This can\'t be undone.'**
  String bucketEmptyConfirm(int count, String size, String name);

  /// No description provided for @bucketEmptyTypeName.
  ///
  /// In en, this message translates to:
  /// **'Type {name} to confirm'**
  String bucketEmptyTypeName(String name);

  /// No description provided for @bucketEmptyTypeNameHelper.
  ///
  /// In en, this message translates to:
  /// **'The button turns on when the name matches.'**
  String get bucketEmptyTypeNameHelper;

  /// No description provided for @bucketDeleteDescription.
  ///
  /// In en, this message translates to:
  /// **'Deletes the bucket with its description, color and access rules. As in S3, only an empty bucket can be deleted.'**
  String get bucketDeleteDescription;

  /// No description provided for @bucketDeleteNotEmpty.
  ///
  /// In en, this message translates to:
  /// **'The bucket has {count, plural, =1{1 object} other{{count} objects}}. Empty it first.'**
  String bucketDeleteNotEmpty(int count);

  /// No description provided for @anonymousAccessDescription.
  ///
  /// In en, this message translates to:
  /// **'Each rule makes a prefix reachable without credentials. Anything no rule covers still needs authentication.'**
  String get anonymousAccessDescription;

  /// No description provided for @anonymousAccessPrivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Private bucket'**
  String get anonymousAccessPrivateTitle;

  /// No description provided for @anonymousAccessPrivateDescription.
  ///
  /// In en, this message translates to:
  /// **'Every request needs credentials. Add a rule to serve a prefix without authentication, for example a website\'s images.'**
  String get anonymousAccessPrivateDescription;

  /// No description provided for @anonymousAccessReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Read only'**
  String get anonymousAccessReadOnly;

  /// No description provided for @anonymousAccessWriteOnly.
  ///
  /// In en, this message translates to:
  /// **'Write only'**
  String get anonymousAccessWriteOnly;

  /// No description provided for @anonymousAccessReadWrite.
  ///
  /// In en, this message translates to:
  /// **'Read and write'**
  String get anonymousAccessReadWrite;

  /// No description provided for @anonymousAccessReadOnlyOps.
  ///
  /// In en, this message translates to:
  /// **'List and download objects'**
  String get anonymousAccessReadOnlyOps;

  /// No description provided for @anonymousAccessWriteOnlyOps.
  ///
  /// In en, this message translates to:
  /// **'Upload and delete objects'**
  String get anonymousAccessWriteOnlyOps;

  /// No description provided for @anonymousAccessReadWriteOps.
  ///
  /// In en, this message translates to:
  /// **'List, download, upload and delete'**
  String get anonymousAccessReadWriteOps;

  /// No description provided for @anonymousAccessReadOnlyDescription.
  ///
  /// In en, this message translates to:
  /// **'Anyone can list and download.'**
  String get anonymousAccessReadOnlyDescription;

  /// No description provided for @anonymousAccessWriteOnlyDescription.
  ///
  /// In en, this message translates to:
  /// **'Anyone can upload and delete, but not see.'**
  String get anonymousAccessWriteOnlyDescription;

  /// No description provided for @anonymousAccessReadWriteDescription.
  ///
  /// In en, this message translates to:
  /// **'Full access without credentials.'**
  String get anonymousAccessReadWriteDescription;

  /// No description provided for @anonymousAccessReadOnlyUseCase.
  ///
  /// In en, this message translates to:
  /// **'Websites, catalogs, public downloads.'**
  String get anonymousAccessReadOnlyUseCase;

  /// No description provided for @anonymousAccessWriteOnlyUseCase.
  ///
  /// In en, this message translates to:
  /// **'Upload inboxes, forms.'**
  String get anonymousAccessWriteOnlyUseCase;

  /// No description provided for @anonymousAccessReadWriteUseCase.
  ///
  /// In en, this message translates to:
  /// **'Use it only on temporary prefixes.'**
  String get anonymousAccessReadWriteUseCase;

  /// No description provided for @anonymousRuleAdd.
  ///
  /// In en, this message translates to:
  /// **'Add rule'**
  String get anonymousRuleAdd;

  /// No description provided for @anonymousRulePrefix.
  ///
  /// In en, this message translates to:
  /// **'Prefix'**
  String get anonymousRulePrefix;

  /// No description provided for @anonymousRuleAccess.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get anonymousRuleAccess;

  /// No description provided for @anonymousRuleOps.
  ///
  /// In en, this message translates to:
  /// **'Allowed without credentials'**
  String get anonymousRuleOps;

  /// No description provided for @anonymousRuleHint.
  ///
  /// In en, this message translates to:
  /// **'Prefixes are relative to the bucket and accept * as a wildcard. When several rules match, the first one applies.'**
  String get anonymousRuleHint;

  /// No description provided for @anonymousRuleDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete rule'**
  String get anonymousRuleDeleteTitle;

  /// No description provided for @anonymousRuleDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete the rule {prefix}? Objects under that prefix will need credentials again.'**
  String anonymousRuleDeleteConfirm(String prefix);

  /// No description provided for @anonymousRuleFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Add access rule'**
  String get anonymousRuleFormTitle;

  /// No description provided for @anonymousRuleFormDescription.
  ///
  /// In en, this message translates to:
  /// **'Make a prefix of {bucket} reachable without credentials.'**
  String anonymousRuleFormDescription(String bucket);

  /// No description provided for @anonymousRuleFormSectionPrefix.
  ///
  /// In en, this message translates to:
  /// **'01 Prefix'**
  String get anonymousRuleFormSectionPrefix;

  /// No description provided for @anonymousRuleFormSectionAccess.
  ///
  /// In en, this message translates to:
  /// **'02 Access type'**
  String get anonymousRuleFormSectionAccess;

  /// No description provided for @anonymousRulePrefixLabel.
  ///
  /// In en, this message translates to:
  /// **'Prefix or pattern'**
  String get anonymousRulePrefixLabel;

  /// No description provided for @anonymousRulePrefixHint.
  ///
  /// In en, this message translates to:
  /// **'public/'**
  String get anonymousRulePrefixHint;

  /// No description provided for @anonymousRulePrefixHelper.
  ///
  /// In en, this message translates to:
  /// **'Without *, it covers everything that starts with it (end it with / for a folder). With *, the whole key must match (for example, *.jpg covers only .jpg files).'**
  String get anonymousRulePrefixHelper;

  /// No description provided for @anonymousRulePrefixRequired.
  ///
  /// In en, this message translates to:
  /// **'The prefix is required'**
  String get anonymousRulePrefixRequired;

  /// No description provided for @anonymousRuleFormErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t add the rule'**
  String get anonymousRuleFormErrorTitle;

  /// No description provided for @anonymousRuleCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Rule {prefix} added'**
  String anonymousRuleCreatedSuccess(String prefix);

  /// No description provided for @bucketSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get bucketSettings;

  /// No description provided for @browserBucketNotFound.
  ///
  /// In en, this message translates to:
  /// **'Bucket \"{name}\" doesn\'t exist'**
  String browserBucketNotFound(String name);

  /// No description provided for @browserBucketNotFoundDescription.
  ///
  /// In en, this message translates to:
  /// **'It may have been deleted, or the link is misspelled.'**
  String get browserBucketNotFoundDescription;

  /// No description provided for @browserBackToBuckets.
  ///
  /// In en, this message translates to:
  /// **'View buckets'**
  String get browserBackToBuckets;

  /// No description provided for @browserFolderNotFound.
  ///
  /// In en, this message translates to:
  /// **'Folder \"{folder}\" doesn\'t exist in this bucket'**
  String browserFolderNotFound(String folder);

  /// No description provided for @browserFolderNotFoundDescription.
  ///
  /// In en, this message translates to:
  /// **'It may have been deleted, or the path is misspelled. In S3 a folder only exists while it has objects.'**
  String get browserFolderNotFoundDescription;

  /// No description provided for @browserGoToBucketRoot.
  ///
  /// In en, this message translates to:
  /// **'Go to the bucket root'**
  String get browserGoToBucketRoot;

  /// No description provided for @objectsNewFolder.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get objectsNewFolder;

  /// No description provided for @objectsNewFolderCreate.
  ///
  /// In en, this message translates to:
  /// **'Create folder'**
  String get objectsNewFolderCreate;

  /// No description provided for @objectsFolderNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get objectsFolderNameLabel;

  /// No description provided for @objectsFolderNameHint.
  ///
  /// In en, this message translates to:
  /// **'invoices-2026'**
  String get objectsFolderNameHint;

  /// No description provided for @objectsFolderPathHelper.
  ///
  /// In en, this message translates to:
  /// **'It will be created in {path}'**
  String objectsFolderPathHelper(String path);

  /// No description provided for @objectsFolderCreated.
  ///
  /// In en, this message translates to:
  /// **'Folder \"{name}\" created'**
  String objectsFolderCreated(String name);

  /// No description provided for @objectsFolderExists.
  ///
  /// In en, this message translates to:
  /// **'There\'s already a folder or object with that name here.'**
  String get objectsFolderExists;

  /// No description provided for @objectsRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get objectsRename;

  /// No description provided for @objectsRenameLabel.
  ///
  /// In en, this message translates to:
  /// **'New name'**
  String get objectsRenameLabel;

  /// No description provided for @objectsRenamePathHelper.
  ///
  /// In en, this message translates to:
  /// **'It stays at {path}'**
  String objectsRenamePathHelper(String path);

  /// No description provided for @objectsRenamed.
  ///
  /// In en, this message translates to:
  /// **'Renamed to \"{name}\"'**
  String objectsRenamed(String name);

  /// No description provided for @objectsNameExists.
  ///
  /// In en, this message translates to:
  /// **'There\'s already an object or folder with that name in this folder.'**
  String get objectsNameExists;

  /// No description provided for @objectsNameRequired.
  ///
  /// In en, this message translates to:
  /// **'The name is required'**
  String get objectsNameRequired;

  /// No description provided for @objectsNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Don\'t use / \\ or any of < > : \" | ? *'**
  String get objectsNameInvalid;

  /// No description provided for @objectsNameUnchanged.
  ///
  /// In en, this message translates to:
  /// **'It\'s the current name'**
  String get objectsNameUnchanged;

  /// No description provided for @objectsActionErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'The action couldn\'t be completed'**
  String get objectsActionErrorTitle;

  /// No description provided for @objectsDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get objectsDetails;

  /// No description provided for @objectsMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get objectsMove;

  /// No description provided for @objectsMoveSelection.
  ///
  /// In en, this message translates to:
  /// **'Move selection'**
  String get objectsMoveSelection;

  /// No description provided for @objectsMoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Move {count, plural, =1{1 object} other{{count} objects}}'**
  String objectsMoveTitle(int count);

  /// No description provided for @objectsMoveBucket.
  ///
  /// In en, this message translates to:
  /// **'Target bucket'**
  String get objectsMoveBucket;

  /// No description provided for @objectsMoveFolder.
  ///
  /// In en, this message translates to:
  /// **'Target folder'**
  String get objectsMoveFolder;

  /// No description provided for @objectsMoveNoFolders.
  ///
  /// In en, this message translates to:
  /// **'No subfolders'**
  String get objectsMoveNoFolders;

  /// No description provided for @objectsMoveHere.
  ///
  /// In en, this message translates to:
  /// **'Move here'**
  String get objectsMoveHere;

  /// No description provided for @objectsMoveHelper.
  ///
  /// In en, this message translates to:
  /// **'They\'ll be moved to {path}. Objects with the same name there are replaced.'**
  String objectsMoveHelper(String path);

  /// No description provided for @objectsMoveSameFolder.
  ///
  /// In en, this message translates to:
  /// **'They\'re already in this folder. Choose another one.'**
  String get objectsMoveSameFolder;

  /// No description provided for @objectsMoved.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 object moved} other{{count} objects moved}}'**
  String objectsMoved(int count);

  /// No description provided for @objectsMovePartial.
  ///
  /// In en, this message translates to:
  /// **'Only {moved} of {total} objects were moved.'**
  String objectsMovePartial(int moved, int total);

  /// No description provided for @objectDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{type} · {size}'**
  String objectDetailsSubtitle(String type, String size);

  /// No description provided for @objectDetailsKey.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get objectDetailsKey;

  /// No description provided for @objectDetailsType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get objectDetailsType;

  /// No description provided for @objectDetailsSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get objectDetailsSize;

  /// No description provided for @objectDetailsSizeBytes.
  ///
  /// In en, this message translates to:
  /// **'({bytes} bytes)'**
  String objectDetailsSizeBytes(int bytes);

  /// No description provided for @objectDetailsModified.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get objectDetailsModified;

  /// No description provided for @objectDetailsUrl.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get objectDetailsUrl;

  /// No description provided for @objectDetailsCopyUrl.
  ///
  /// In en, this message translates to:
  /// **'Copy URL'**
  String get objectDetailsCopyUrl;

  /// No description provided for @objectDetailsUrlCopied.
  ///
  /// In en, this message translates to:
  /// **'URL copied'**
  String get objectDetailsUrlCopied;

  /// No description provided for @objectsPageSize.
  ///
  /// In en, this message translates to:
  /// **'Rows per page:'**
  String get objectsPageSize;

  /// No description provided for @objectsPageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {total}'**
  String objectsPageOf(int page, int total);

  /// No description provided for @objectsPreviousPage.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get objectsPreviousPage;

  /// No description provided for @objectsNextPage.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get objectsNextPage;

  /// No description provided for @objectsPagerHint.
  ///
  /// In en, this message translates to:
  /// **'Search and filters only apply to the pages already loaded.'**
  String get objectsPagerHint;

  /// No description provided for @objectsPagerHintPages.
  ///
  /// In en, this message translates to:
  /// **'Search and filters only apply to the pages already loaded ({loaded} of {total}).'**
  String objectsPagerHintPages(int loaded, int total);

  /// No description provided for @objectsShareLink.
  ///
  /// In en, this message translates to:
  /// **'Share link'**
  String get objectsShareLink;

  /// No description provided for @shareLinkDescription.
  ///
  /// In en, this message translates to:
  /// **'Anyone with the link can download {name} until it expires, without signing in.'**
  String shareLinkDescription(String name);

  /// No description provided for @shareLinkExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'Expires in'**
  String get shareLinkExpiresIn;

  /// No description provided for @shareLinkHour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get shareLinkHour;

  /// No description provided for @shareLinkDay.
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get shareLinkDay;

  /// No description provided for @shareLinkWeek.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get shareLinkWeek;

  /// No description provided for @shareLinkValidUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String shareLinkValidUntil(String date);

  /// No description provided for @shareLinkCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get shareLinkCopy;

  /// No description provided for @shareLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get shareLinkCopied;

  /// No description provided for @transfersTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfers'**
  String get transfersTitle;

  /// No description provided for @transfersActive.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 transfer in progress} other{{count} transfers in progress}}'**
  String transfersActive(int count);

  /// No description provided for @transfersFailed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 transfer failed} other{{count} transfers failed}}'**
  String transfersFailed(int count);

  /// No description provided for @transfersAllDone.
  ///
  /// In en, this message translates to:
  /// **'All transfers finished'**
  String get transfersAllDone;

  /// No description provided for @transfersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No transfers yet. Uploads and downloads keep going in the background while you use the console.'**
  String get transfersEmpty;

  /// No description provided for @transfersUploadsAdded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file added to transfers} other{{count} files added to transfers}}'**
  String transfersUploadsAdded(int count);

  /// No description provided for @transfersDownloadAdded.
  ///
  /// In en, this message translates to:
  /// **'Downloading {name} in the background'**
  String transfersDownloadAdded(String name);

  /// No description provided for @transfersClearFinished.
  ///
  /// In en, this message translates to:
  /// **'Clear finished'**
  String get transfersClearFinished;

  /// No description provided for @transferUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get transferUpload;

  /// No description provided for @transferDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get transferDownload;

  /// No description provided for @transferStatusQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get transferStatusQueued;

  /// No description provided for @transferStatusPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing the zip…'**
  String get transferStatusPreparing;

  /// No description provided for @transferStatusProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} · {percent}%'**
  String transferStatusProgress(String done, String total, int percent);

  /// No description provided for @transferStatusUploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded · {size}'**
  String transferStatusUploaded(String size);

  /// No description provided for @transferStatusDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded · {size}'**
  String transferStatusDownloaded(String size);

  /// No description provided for @transferStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String transferStatusFailed(String message);

  /// No description provided for @transferStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get transferStatusCancelled;

  /// No description provided for @transferCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get transferCancel;

  /// No description provided for @transferRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from list'**
  String get transferRemove;

  /// No description provided for @navLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language: {name}'**
  String navLanguage(String name);

  /// No description provided for @navLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get navLogout;

  /// No description provided for @navAccessKeys.
  ///
  /// In en, this message translates to:
  /// **'Access keys'**
  String get navAccessKeys;

  /// No description provided for @accessKeysDescription.
  ///
  /// In en, this message translates to:
  /// **'Each key lets an S3 client (AWS CLI, rclone, SDKs) in, only to the buckets you give it.'**
  String get accessKeysDescription;

  /// No description provided for @accessKeysSecretOnce.
  ///
  /// In en, this message translates to:
  /// **'The secret is shown only once, when the key is created or its secret is regenerated.'**
  String get accessKeysSecretOnce;

  /// No description provided for @accessKeysSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or ID...'**
  String get accessKeysSearchHint;

  /// No description provided for @accessKeyCreate.
  ///
  /// In en, this message translates to:
  /// **'Create key'**
  String get accessKeyCreate;

  /// No description provided for @accessKeyColumnName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get accessKeyColumnName;

  /// No description provided for @accessKeyColumnId.
  ///
  /// In en, this message translates to:
  /// **'Access key ID'**
  String get accessKeyColumnId;

  /// No description provided for @accessKeyColumnPermissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get accessKeyColumnPermissions;

  /// No description provided for @accessKeyColumnLastUsed.
  ///
  /// In en, this message translates to:
  /// **'Last used'**
  String get accessKeyColumnLastUsed;

  /// No description provided for @accessKeyColumnStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get accessKeyColumnStatus;

  /// No description provided for @accessKeyRootName.
  ///
  /// In en, this message translates to:
  /// **'Root key'**
  String get accessKeyRootName;

  /// No description provided for @accessKeyRootBadge.
  ///
  /// In en, this message translates to:
  /// **'Root'**
  String get accessKeyRootBadge;

  /// No description provided for @accessKeyRootPermissions.
  ///
  /// In en, this message translates to:
  /// **'Everything, including the console'**
  String get accessKeyRootPermissions;

  /// No description provided for @accessKeyRootLocked.
  ///
  /// In en, this message translates to:
  /// **'Set with FEATHER_ACCESS and FEATHER_SECRET: it can\'t be edited or deleted'**
  String get accessKeyRootLocked;

  /// No description provided for @accessKeyCreatedOn.
  ///
  /// In en, this message translates to:
  /// **'Created {date}'**
  String accessKeyCreatedOn(String date);

  /// No description provided for @accessKeyCopyId.
  ///
  /// In en, this message translates to:
  /// **'Copy ID'**
  String get accessKeyCopyId;

  /// No description provided for @accessKeyIdCopied.
  ///
  /// In en, this message translates to:
  /// **'ID copied'**
  String get accessKeyIdCopied;

  /// No description provided for @accessKeyAllBuckets.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get accessKeyAllBuckets;

  /// No description provided for @accessKeyNoBuckets.
  ///
  /// In en, this message translates to:
  /// **'No buckets: edit it to give it access'**
  String get accessKeyNoBuckets;

  /// No description provided for @accessKeyCreatesBuckets.
  ///
  /// In en, this message translates to:
  /// **'+ create buckets'**
  String get accessKeyCreatesBuckets;

  /// No description provided for @accessKeyLevelReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Read only'**
  String get accessKeyLevelReadOnly;

  /// No description provided for @accessKeyLevelWriteOnly.
  ///
  /// In en, this message translates to:
  /// **'Write only'**
  String get accessKeyLevelWriteOnly;

  /// No description provided for @accessKeyLevelReadWrite.
  ///
  /// In en, this message translates to:
  /// **'Read and write'**
  String get accessKeyLevelReadWrite;

  /// No description provided for @accessKeyLevelShortRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get accessKeyLevelShortRead;

  /// No description provided for @accessKeyLevelShortWrite.
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get accessKeyLevelShortWrite;

  /// No description provided for @accessKeyLevelShortBoth.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get accessKeyLevelShortBoth;

  /// No description provided for @accessKeyLevelReadOnlyDescription.
  ///
  /// In en, this message translates to:
  /// **'List and download objects.'**
  String get accessKeyLevelReadOnlyDescription;

  /// No description provided for @accessKeyLevelWriteOnlyDescription.
  ///
  /// In en, this message translates to:
  /// **'Upload and delete objects, without seeing them.'**
  String get accessKeyLevelWriteOnlyDescription;

  /// No description provided for @accessKeyLevelReadWriteDescription.
  ///
  /// In en, this message translates to:
  /// **'List, download, upload and delete objects.'**
  String get accessKeyLevelReadWriteDescription;

  /// No description provided for @accessKeyStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get accessKeyStatusActive;

  /// No description provided for @accessKeyStatusDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get accessKeyStatusDisabled;

  /// No description provided for @accessKeyStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get accessKeyStatusExpired;

  /// No description provided for @accessKeyExpiresOn.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String accessKeyExpiresOn(String date);

  /// No description provided for @accessKeyExpiredOn.
  ///
  /// In en, this message translates to:
  /// **'Expired {date}'**
  String accessKeyExpiredOn(String date);

  /// No description provided for @accessKeyNeverUsed.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get accessKeyNeverUsed;

  /// No description provided for @accessKeyUsedNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get accessKeyUsedNow;

  /// No description provided for @accessKeyUsedMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String accessKeyUsedMinutes(int count);

  /// No description provided for @accessKeyUsedHours.
  ///
  /// In en, this message translates to:
  /// **'{count} h ago'**
  String accessKeyUsedHours(int count);

  /// No description provided for @accessKeyUsedDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String accessKeyUsedDays(int count);

  /// No description provided for @accessKeyActions.
  ///
  /// In en, this message translates to:
  /// **'Actions of {name}'**
  String accessKeyActions(String name);

  /// No description provided for @accessKeyEditPermissions.
  ///
  /// In en, this message translates to:
  /// **'Edit permissions'**
  String get accessKeyEditPermissions;

  /// No description provided for @accessKeyRegenerateSecret.
  ///
  /// In en, this message translates to:
  /// **'Regenerate secret'**
  String get accessKeyRegenerateSecret;

  /// No description provided for @accessKeyDisable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get accessKeyDisable;

  /// No description provided for @accessKeyEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get accessKeyEnable;

  /// No description provided for @accessKeysFooterHint.
  ///
  /// In en, this message translates to:
  /// **'Keys are only for S3 clients: the console opens with the root key. A disabled or expired key gets 403 InvalidAccessKeyId.'**
  String get accessKeysFooterHint;

  /// No description provided for @accessKeysEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Only the root key exists'**
  String get accessKeysEmptyTitle;

  /// No description provided for @accessKeysEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a key for each client or application, with access to its own buckets only. You can then revoke it without touching the others.'**
  String get accessKeysEmptyDescription;

  /// No description provided for @accessKeysCreateFirst.
  ///
  /// In en, this message translates to:
  /// **'Create the first key'**
  String get accessKeysCreateFirst;

  /// No description provided for @accessKeysNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No key matches the search'**
  String get accessKeysNoMatch;

  /// No description provided for @accessKeyDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete key'**
  String get accessKeyDeleteTitle;

  /// No description provided for @accessKeyDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete the key {name}? Clients using it will get 403 right away. To pause it, disable it instead.'**
  String accessKeyDeleteConfirm(String name);

  /// No description provided for @accessKeyRegenerateTitle.
  ///
  /// In en, this message translates to:
  /// **'Regenerate secret'**
  String get accessKeyRegenerateTitle;

  /// No description provided for @accessKeyRegenerateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Generate a new secret for {name}? The current one stops working right away.'**
  String accessKeyRegenerateConfirm(String name);

  /// No description provided for @accessKeyRegenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get accessKeyRegenerate;

  /// No description provided for @accessKeyDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Key {name} deleted'**
  String accessKeyDeletedSuccess(String name);

  /// No description provided for @accessKeyDisabledSuccess.
  ///
  /// In en, this message translates to:
  /// **'Key {name} disabled'**
  String accessKeyDisabledSuccess(String name);

  /// No description provided for @accessKeyEnabledSuccess.
  ///
  /// In en, this message translates to:
  /// **'Key {name} enabled'**
  String accessKeyEnabledSuccess(String name);

  /// No description provided for @accessKeySavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Key {name} saved'**
  String accessKeySavedSuccess(String name);

  /// No description provided for @accessKeyFormCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create access key'**
  String get accessKeyFormCreateTitle;

  /// No description provided for @accessKeyFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit access key'**
  String get accessKeyFormEditTitle;

  /// No description provided for @accessKeyFormCreateDescription.
  ///
  /// In en, this message translates to:
  /// **'The ID and the secret are generated when it is created.'**
  String get accessKeyFormCreateDescription;

  /// No description provided for @accessKeyFormEditDescription.
  ///
  /// In en, this message translates to:
  /// **'{id}. The secret doesn\'t change.'**
  String accessKeyFormEditDescription(String id);

  /// No description provided for @accessKeyFormSectionIdentity.
  ///
  /// In en, this message translates to:
  /// **'01 Identification'**
  String get accessKeyFormSectionIdentity;

  /// No description provided for @accessKeyFormSectionScope.
  ///
  /// In en, this message translates to:
  /// **'02 Scope'**
  String get accessKeyFormSectionScope;

  /// No description provided for @accessKeyFormSectionPermissions.
  ///
  /// In en, this message translates to:
  /// **'03 Permissions'**
  String get accessKeyFormSectionPermissions;

  /// No description provided for @accessKeyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get accessKeyNameLabel;

  /// No description provided for @accessKeyNameHint.
  ///
  /// In en, this message translates to:
  /// **'Backups NAS'**
  String get accessKeyNameHint;

  /// No description provided for @accessKeyNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Give the key a name'**
  String get accessKeyNameRequired;

  /// No description provided for @accessKeyExpiryLabel.
  ///
  /// In en, this message translates to:
  /// **'Expiration'**
  String get accessKeyExpiryLabel;

  /// No description provided for @accessKeyExpiryNever.
  ///
  /// In en, this message translates to:
  /// **'Never expires'**
  String get accessKeyExpiryNever;

  /// No description provided for @accessKeyExpiry30Days.
  ///
  /// In en, this message translates to:
  /// **'In 30 days'**
  String get accessKeyExpiry30Days;

  /// No description provided for @accessKeyExpiry90Days.
  ///
  /// In en, this message translates to:
  /// **'In 90 days'**
  String get accessKeyExpiry90Days;

  /// No description provided for @accessKeyExpiryYear.
  ///
  /// In en, this message translates to:
  /// **'In 1 year'**
  String get accessKeyExpiryYear;

  /// No description provided for @accessKeyExpiryKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep: {date}'**
  String accessKeyExpiryKeep(String date);

  /// No description provided for @accessKeyScopeAll.
  ///
  /// In en, this message translates to:
  /// **'All buckets'**
  String get accessKeyScopeAll;

  /// No description provided for @accessKeyScopeAllDescription.
  ///
  /// In en, this message translates to:
  /// **'Also the ones created later. With write access it can also create and delete buckets.'**
  String get accessKeyScopeAllDescription;

  /// No description provided for @accessKeyScopeSome.
  ///
  /// In en, this message translates to:
  /// **'Specific buckets'**
  String get accessKeyScopeSome;

  /// No description provided for @accessKeyScopeSomeDescription.
  ///
  /// In en, this message translates to:
  /// **'Only the ones you check, each with its level. It only sees those when listing.'**
  String get accessKeyScopeSomeDescription;

  /// No description provided for @accessKeyBucketsChecked.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} checked'**
  String accessKeyBucketsChecked(int count, int total);

  /// No description provided for @accessKeyBucketsRequired.
  ///
  /// In en, this message translates to:
  /// **'Check at least one bucket'**
  String get accessKeyBucketsRequired;

  /// No description provided for @accessKeyBucketsEmpty.
  ///
  /// In en, this message translates to:
  /// **'There are no buckets yet: create one, or give the key every bucket.'**
  String get accessKeyBucketsEmpty;

  /// No description provided for @accessKeyFormErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'The key couldn\'t be saved'**
  String get accessKeyFormErrorTitle;

  /// No description provided for @accessKeySecretCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Key created: {name}'**
  String accessKeySecretCreatedTitle(String name);

  /// No description provided for @accessKeySecretRegeneratedTitle.
  ///
  /// In en, this message translates to:
  /// **'New secret: {name}'**
  String accessKeySecretRegeneratedTitle(String name);

  /// No description provided for @accessKeySecretWarning.
  ///
  /// In en, this message translates to:
  /// **'Copy the secret now: this is the only time it is shown. If you lose it, you\'ll have to regenerate it.'**
  String get accessKeySecretWarning;

  /// No description provided for @accessKeySecretLabel.
  ///
  /// In en, this message translates to:
  /// **'Secret access key'**
  String get accessKeySecretLabel;

  /// No description provided for @accessKeyCopySecret.
  ///
  /// In en, this message translates to:
  /// **'Copy secret'**
  String get accessKeyCopySecret;

  /// No description provided for @accessKeySecretCopied.
  ///
  /// In en, this message translates to:
  /// **'Secret copied'**
  String get accessKeySecretCopied;

  /// No description provided for @accessKeyDownloadCsv.
  ///
  /// In en, this message translates to:
  /// **'Download as .csv'**
  String get accessKeyDownloadCsv;

  /// No description provided for @accessKeySecretSaved.
  ///
  /// In en, this message translates to:
  /// **'I\'ve saved the secret somewhere safe'**
  String get accessKeySecretSaved;
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
