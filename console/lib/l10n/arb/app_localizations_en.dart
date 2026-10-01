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
  String get edit => 'Edit';

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
  String get bucketsTitle => 'Buckets';

  @override
  String get bucketsSubtitle =>
      'Manage your S3 compatible buckets and storage resources.';

  @override
  String get bucketsCreate => 'Create Bucket';

  @override
  String get bucketsEdit => 'Edit Bucket';

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
  String get objectsNoMatchFilter => 'No objects match the filters';

  @override
  String get objectsFilterTitle => 'Filters';

  @override
  String get objectsFilterClear => 'Clear';

  @override
  String get objectsFilterType => 'Type';

  @override
  String get objectsFilterTypeOther => 'Other';

  @override
  String get objectsFilterSize => 'Size';

  @override
  String get objectsFilterSizeSmall => 'Under 1 MB';

  @override
  String get objectsFilterSizeMedium => '1 MB – 100 MB';

  @override
  String get objectsFilterSizeLarge => 'Over 100 MB';

  @override
  String get objectsFilterModified => 'Modified';

  @override
  String get objectsFilterDate24h => 'Last 24 hours';

  @override
  String get objectsFilterDate7d => 'Last 7 days';

  @override
  String get objectsFilterDate30d => 'Last 30 days';

  @override
  String get objectsFilterDateOlder => 'Older than 30 days';

  @override
  String get objectsFilterFoldersHidden =>
      'Folders are hidden while a filter is active.';

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
  String bucketEditDescription(String name) {
    return 'Change the description and color of the $name bucket. The name can\'t be changed.';
  }

  @override
  String get bucketEditSave => 'Save changes';

  @override
  String get bucketEditErrorTitle => 'Couldn\'t save the bucket';

  @override
  String bucketUpdatedSuccess(String name) {
    return 'Bucket \"$name\" updated';
  }

  @override
  String bucketCreatedSuccess(String name) {
    return 'Bucket \"$name\" created';
  }

  @override
  String bucketNamePathHint(String name) {
    return 'Used in S3 paths: /$name';
  }

  @override
  String get navBuckets => 'Buckets';

  @override
  String bucketAdminCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count buckets',
      one: '1 bucket',
    );
    return '$_temp0';
  }

  @override
  String bucketAdminStats(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count objects',
      one: '1 object',
    );
    return '$_temp0 · $size';
  }

  @override
  String get bucketAdminEmptyDescription =>
      'Create a bucket to configure it here.';

  @override
  String get bucketAdminOpenInBrowser => 'Open in browser';

  @override
  String get bucketAdminTabGeneral => 'General';

  @override
  String get bucketAdminTabAccess => 'Anonymous access';

  @override
  String get bucketAdminTabDanger => 'Danger zone';

  @override
  String get bucketDetailObjects => 'Objects';

  @override
  String get bucketDetailSize => 'Size';

  @override
  String get bucketDetailCreated => 'Created';

  @override
  String get bucketDetailLastModified => 'Last modified';

  @override
  String get bucketDetailNeverModified => 'No objects';

  @override
  String get bucketDetailName => 'Name';

  @override
  String get bucketDetailS3Path => 'S3 path';

  @override
  String get bucketDetailCopyPath => 'Copy path';

  @override
  String get bucketDetailPathCopied => 'Path copied';

  @override
  String get bucketDetailDescription => 'Description';

  @override
  String get bucketDetailNoDescription => 'No description';

  @override
  String get bucketDetailColor => 'Color';

  @override
  String get bucketEmptyTitle => 'Empty bucket';

  @override
  String get bucketEmptyAlreadyEmpty => 'The bucket has no objects.';

  @override
  String bucketEmptyDescription(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'its $count objects',
      one: 'its only object',
    );
    return 'Deletes $_temp0 ($size). The bucket, its settings and its access rules are kept. This can\'t be undone.';
  }

  @override
  String bucketEmptyConfirm(int count, String size, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count objects',
      one: '1 object',
    );
    return '$_temp0 ($size) will be deleted from $name. This can\'t be undone.';
  }

  @override
  String bucketEmptyTypeName(String name) {
    return 'Type $name to confirm';
  }

  @override
  String get bucketEmptyTypeNameHelper =>
      'The button turns on when the name matches.';

  @override
  String get bucketDeleteDescription =>
      'Deletes the bucket with its description, color and access rules. As in S3, only an empty bucket can be deleted.';

  @override
  String bucketDeleteNotEmpty(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count objects',
      one: '1 object',
    );
    return 'The bucket has $_temp0. Empty it first.';
  }

  @override
  String get anonymousAccessDescription =>
      'Each rule makes a prefix reachable without credentials. Anything no rule covers still needs authentication.';

  @override
  String get anonymousAccessPrivateTitle => 'Private bucket';

  @override
  String get anonymousAccessPrivateDescription =>
      'Every request needs credentials. Add a rule to serve a prefix without authentication, for example a website\'s images.';

  @override
  String get anonymousAccessReadOnly => 'Read only';

  @override
  String get anonymousAccessWriteOnly => 'Write only';

  @override
  String get anonymousAccessReadWrite => 'Read and write';

  @override
  String get anonymousAccessReadOnlyOps => 'List and download objects';

  @override
  String get anonymousAccessWriteOnlyOps => 'Upload and delete objects';

  @override
  String get anonymousAccessReadWriteOps => 'List, download, upload and delete';

  @override
  String get anonymousAccessReadOnlyDescription =>
      'Anyone can list and download.';

  @override
  String get anonymousAccessWriteOnlyDescription =>
      'Anyone can upload and delete, but not see.';

  @override
  String get anonymousAccessReadWriteDescription =>
      'Full access without credentials.';

  @override
  String get anonymousAccessReadOnlyUseCase =>
      'Websites, catalogs, public downloads.';

  @override
  String get anonymousAccessWriteOnlyUseCase => 'Upload inboxes, forms.';

  @override
  String get anonymousAccessReadWriteUseCase =>
      'Use it only on temporary prefixes.';

  @override
  String get anonymousRuleAdd => 'Add rule';

  @override
  String get anonymousRulePrefix => 'Prefix';

  @override
  String get anonymousRuleAccess => 'Access';

  @override
  String get anonymousRuleOps => 'Allowed without credentials';

  @override
  String get anonymousRuleHint =>
      'Prefixes are relative to the bucket and accept * as a wildcard. When several rules match, the first one applies.';

  @override
  String get anonymousRuleDeleteTitle => 'Delete rule';

  @override
  String anonymousRuleDeleteConfirm(String prefix) {
    return 'Delete the rule $prefix? Objects under that prefix will need credentials again.';
  }

  @override
  String get anonymousRuleFormTitle => 'Add access rule';

  @override
  String anonymousRuleFormDescription(String bucket) {
    return 'Make a prefix of $bucket reachable without credentials.';
  }

  @override
  String get anonymousRuleFormSectionPrefix => '01 Prefix';

  @override
  String get anonymousRuleFormSectionAccess => '02 Access type';

  @override
  String get anonymousRulePrefixLabel => 'Prefix or pattern';

  @override
  String get anonymousRulePrefixHint => 'public/';

  @override
  String get anonymousRulePrefixHelper =>
      'End it with / for a folder, or use * as a wildcard (for example, *.jpg).';

  @override
  String get anonymousRulePrefixRequired => 'The prefix is required';

  @override
  String get anonymousRuleFormErrorTitle => 'Couldn\'t add the rule';

  @override
  String anonymousRuleCreatedSuccess(String prefix) {
    return 'Rule $prefix added';
  }

  @override
  String get bucketSettings => 'Settings';

  @override
  String browserBucketNotFound(String name) {
    return 'Bucket \"$name\" doesn\'t exist';
  }

  @override
  String get browserBucketNotFoundDescription =>
      'It may have been deleted, or the link is misspelled.';

  @override
  String get browserBackToBuckets => 'View buckets';

  @override
  String browserFolderNotFound(String folder) {
    return 'Folder \"$folder\" doesn\'t exist in this bucket';
  }

  @override
  String get browserFolderNotFoundDescription =>
      'It may have been deleted, or the path is misspelled. In S3 a folder only exists while it has objects.';

  @override
  String get browserGoToBucketRoot => 'Go to the bucket root';

  @override
  String get objectsNewFolder => 'New folder';

  @override
  String get objectsNewFolderCreate => 'Create folder';

  @override
  String get objectsFolderNameLabel => 'Folder name';

  @override
  String get objectsFolderNameHint => 'invoices-2026';

  @override
  String objectsFolderPathHelper(String path) {
    return 'It will be created in $path';
  }

  @override
  String objectsFolderCreated(String name) {
    return 'Folder \"$name\" created';
  }

  @override
  String get objectsFolderExists =>
      'There\'s already a folder or object with that name here.';

  @override
  String get objectsRename => 'Rename';

  @override
  String get objectsRenameLabel => 'New name';

  @override
  String objectsRenamePathHelper(String path) {
    return 'It stays at $path';
  }

  @override
  String objectsRenamed(String name) {
    return 'Renamed to \"$name\"';
  }

  @override
  String get objectsNameExists =>
      'There\'s already an object or folder with that name in this folder.';

  @override
  String get objectsNameRequired => 'The name is required';

  @override
  String get objectsNameInvalid => 'Don\'t use / \\ or any of < > : \" | ? *';

  @override
  String get objectsNameUnchanged => 'It\'s the current name';

  @override
  String get objectsActionErrorTitle => 'The action couldn\'t be completed';

  @override
  String get objectsDetails => 'Details';

  @override
  String get objectsMove => 'Move';

  @override
  String get objectsMoveSelection => 'Move selection';

  @override
  String objectsMoveTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count objects',
      one: '1 object',
    );
    return 'Move $_temp0';
  }

  @override
  String get objectsMoveBucket => 'Target bucket';

  @override
  String get objectsMoveFolder => 'Target folder';

  @override
  String get objectsMoveNoFolders => 'No subfolders';

  @override
  String get objectsMoveHere => 'Move here';

  @override
  String objectsMoveHelper(String path) {
    return 'They\'ll be moved to $path. Objects with the same name there are replaced.';
  }

  @override
  String get objectsMoveSameFolder =>
      'They\'re already in this folder. Choose another one.';

  @override
  String objectsMoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count objects moved',
      one: '1 object moved',
    );
    return '$_temp0';
  }

  @override
  String objectsMovePartial(int moved, int total) {
    return 'Only $moved of $total objects were moved.';
  }

  @override
  String objectDetailsSubtitle(String type, String size) {
    return '$type · $size';
  }

  @override
  String get objectDetailsKey => 'Key';

  @override
  String get objectDetailsType => 'Type';

  @override
  String get objectDetailsSize => 'Size';

  @override
  String objectDetailsSizeBytes(int bytes) {
    return '($bytes bytes)';
  }

  @override
  String get objectDetailsModified => 'Modified';

  @override
  String get objectDetailsUrl => 'URL';

  @override
  String get objectDetailsCopyUrl => 'Copy URL';

  @override
  String get objectDetailsUrlCopied => 'URL copied';

  @override
  String get objectsPageSize => 'Rows per page:';

  @override
  String objectsPageOf(int page, int total) {
    return 'Page $page of $total';
  }

  @override
  String get objectsPreviousPage => 'Previous page';

  @override
  String get objectsNextPage => 'Next page';

  @override
  String get objectsPagerHint =>
      'Search and filters only apply to the pages already loaded.';

  @override
  String objectsPagerHintPages(int loaded, int total) {
    return 'Search and filters only apply to the pages already loaded ($loaded of $total).';
  }

  @override
  String get objectsShareLink => 'Share link';

  @override
  String shareLinkDescription(String name) {
    return 'Anyone with the link can download $name until it expires, without signing in.';
  }

  @override
  String get shareLinkExpiresIn => 'Expires in';

  @override
  String get shareLinkHour => '1 hour';

  @override
  String get shareLinkDay => '1 day';

  @override
  String get shareLinkWeek => '7 days';

  @override
  String shareLinkValidUntil(String date) {
    return 'Valid until $date';
  }

  @override
  String get shareLinkCopy => 'Copy link';

  @override
  String get shareLinkCopied => 'Link copied';

  @override
  String get transfersTitle => 'Transfers';

  @override
  String transfersActive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transfers in progress',
      one: '1 transfer in progress',
    );
    return '$_temp0';
  }

  @override
  String transfersFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transfers failed',
      one: '1 transfer failed',
    );
    return '$_temp0';
  }

  @override
  String get transfersAllDone => 'All transfers finished';

  @override
  String get transfersEmpty =>
      'No transfers yet. Uploads and downloads keep going in the background while you use the console.';

  @override
  String transfersUploadsAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files added to transfers',
      one: '1 file added to transfers',
    );
    return '$_temp0';
  }

  @override
  String transfersDownloadAdded(String name) {
    return 'Downloading $name in the background';
  }

  @override
  String get transfersClearFinished => 'Clear finished';

  @override
  String get transferUpload => 'Upload';

  @override
  String get transferDownload => 'Download';

  @override
  String get transferStatusQueued => 'Queued';

  @override
  String get transferStatusPreparing => 'Preparing the zip…';

  @override
  String transferStatusProgress(String done, String total, int percent) {
    return '$done of $total · $percent%';
  }

  @override
  String transferStatusUploaded(String size) {
    return 'Uploaded · $size';
  }

  @override
  String transferStatusDownloaded(String size) {
    return 'Downloaded · $size';
  }

  @override
  String transferStatusFailed(String message) {
    return 'Error: $message';
  }

  @override
  String get transferStatusCancelled => 'Cancelled';

  @override
  String get transferCancel => 'Cancel';

  @override
  String get transferRemove => 'Remove from list';

  @override
  String navLanguage(String name) {
    return 'Language: $name';
  }

  @override
  String get navLogout => 'Log out';
}
