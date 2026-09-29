// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Feather IO';

  @override
  String get appNeedMoreSpace => 'Need more space';

  @override
  String get splashTitle => 'Admin';

  @override
  String get splashFooter => 'With ♥ from Maple';

  @override
  String get loading => 'Loading';

  @override
  String get error => 'Error';

  @override
  String get tryAgain => 'Try again';

  @override
  String get noData => 'No data';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get delete => 'Delete';

  @override
  String get refresh => 'Refresh';

  @override
  String get required => 'Required';

  @override
  String get preview => 'Preview';

  @override
  String get download => 'Download';

  @override
  String get upload => 'Upload';

  @override
  String get filter => 'Filter';

  @override
  String get name => 'Name';

  @override
  String get type => 'Type';

  @override
  String get size => 'Size';

  @override
  String get objects => 'Objects';

  @override
  String get createdAt => 'Created At';

  @override
  String get lastModified => 'Last Modified';

  @override
  String get errorRequestCancelled => 'Request to API server was cancelled';

  @override
  String get errorConnectionTimeout =>
      'Connection timeout with API server. Check your internet connection';

  @override
  String get errorNoConnection =>
      'Connection to API server failed due to internet connection';

  @override
  String get errorReceiveTimeout =>
      'Receive timeout in connection with API server';

  @override
  String get errorSendTimeout => 'Send timeout with API server';

  @override
  String get errorBadCertificate => 'Bad certificate';

  @override
  String get errorConnection => 'Connection error';

  @override
  String get errorValidation => 'Validation error';

  @override
  String get errorServer => 'Server error';

  @override
  String get errorUnknown => 'Unknown error';

  @override
  String get navBrowser => 'Browser';

  @override
  String get loginAccessKey => 'Access Key';

  @override
  String get loginAccessKeyHint => 'Enter your access key';

  @override
  String get loginSecretKey => 'Secret Key';

  @override
  String get loginSecretKeyHint => 'Enter your secret key';

  @override
  String get loginButton => 'Login';

  @override
  String get loginInProgress => 'Logging in...';

  @override
  String get bucketsTitle => 'Buckets';

  @override
  String get bucketsSubtitle =>
      'Manage your S3 compatible buckets and storage resources.';

  @override
  String get bucketsCreate => 'Create Bucket';

  @override
  String get bucketsTotalBuckets => 'Total Buckets';

  @override
  String get bucketsTotalObjects => 'Total Objects';

  @override
  String get bucketsTotalStorage => 'Total Storage';

  @override
  String get bucketsSearchHint => 'Search buckets...';

  @override
  String get bucketsEmpty => 'No buckets found';

  @override
  String bucketsNoMatch(String query) {
    return 'No buckets matching \"$query\"';
  }

  @override
  String get bucketsDeleteTitle => 'Delete bucket';

  @override
  String bucketsDeleteConfirm(String name) {
    return 'Are you sure you want to delete the $name bucket?';
  }

  @override
  String get bucketsReadWriteBadge => 'R/W';

  @override
  String get bucketsReadWriteTooltip =>
      'You have read and write access to this bucket';

  @override
  String bucketsCreatedAt(String date) {
    return 'Created $date';
  }

  @override
  String get bucketCreateDescription =>
      'Configure high-performance object storage parameters, redundancy, and protection policies.';

  @override
  String get bucketCreateSectionGeneral => '01 General Configuration';

  @override
  String get bucketCreateSectionAdditional => '02 Additional Info';

  @override
  String get bucketCreateNameLabel => 'Bucket Identifier';

  @override
  String get bucketCreateNameHint => 'my-bucket-name';

  @override
  String get bucketCreateDescriptionLabel => 'Description (Optional)';

  @override
  String get bucketCreateDescriptionHint =>
      'Brief description of the bucket usage';

  @override
  String get bucketNameRequired => 'Bucket name is required';

  @override
  String get bucketNameLength => 'Between 3 and 63 characters';

  @override
  String get bucketNameChars => 'Lowercase, numbers and hyphens only';

  @override
  String get bucketNameHyphenEdges => 'Cannot start or end with a hyphen';

  @override
  String get bucketRuleChars => 'Lowercase, numbers and hyphens only';

  @override
  String get bucketRuleHyphenEdges => 'No hyphen at start/end';

  @override
  String get objectsSearchHint => 'Search objects...';

  @override
  String get objectsEmpty => 'No objects found';

  @override
  String objectsNoMatch(String query) {
    return 'No objects matching \"$query\"';
  }

  @override
  String get objectsDragHint => 'Drag files here to upload';

  @override
  String get objectsDropHere => 'Drop here to upload';

  @override
  String get objectsDeleteTitle => 'Delete objects';

  @override
  String objectsDeleteConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Are you sure you want to delete $count objects?',
      one: 'Are you sure you want to delete 1 object?',
    );
    return '$_temp0';
  }

  @override
  String get objectsUploadFiles => 'Upload files';

  @override
  String get objectsUploadDirectory => 'Upload directory';

  @override
  String get fileTypeFolder => 'Folder';

  @override
  String get fileTypeFile => 'File';

  @override
  String get fileTypeImage => 'Image';

  @override
  String get fileTypeVideo => 'Video';

  @override
  String get fileTypeAudio => 'Audio';

  @override
  String get fileTypeText => 'Text';

  @override
  String get fileTypeDocument => 'Document';

  @override
  String get fileTypeSpreadsheet => 'Spreadsheet';

  @override
  String get fileTypeArchive => 'Archive';

  @override
  String get colorNone => 'No color';

  @override
  String get colorCustom => 'Custom color';

  @override
  String get colorApply => 'Apply';

  @override
  String get colorSaturationBrightness => 'Saturation and brightness';

  @override
  String get colorHue => 'Hue';

  @override
  String colorContrast(String ratio) {
    return 'Icon contrast: $ratio:1';
  }

  @override
  String colorContrastLow(String ratio) {
    return 'Low contrast with the icon ($ratio:1)';
  }

  @override
  String get colorHexInvalid =>
      'Enter a 6-digit HEX color, for example #0E7490';

  @override
  String get colorViolet => 'Violet';

  @override
  String get colorBlue => 'Blue';

  @override
  String get colorTeal => 'Teal';

  @override
  String get colorGreen => 'Green';

  @override
  String get colorAmber => 'Amber';

  @override
  String get colorRed => 'Red';

  @override
  String get colorPink => 'Pink';

  @override
  String get colorSlate => 'Slate';

  @override
  String get bucketCreateColorLabel => 'Color';

  @override
  String get bucketNameExists => 'A bucket with this name already exists';

  @override
  String get bucketCreateErrorTitle => 'Couldn\'t create the bucket';

  @override
  String get bucketsCreating => 'Creating...';

  @override
  String bucketCreatedSuccess(String name) {
    return 'Bucket \"$name\" created';
  }

  @override
  String bucketNamePathHint(String name) {
    return 'Used in S3 paths: /$name';
  }
}
