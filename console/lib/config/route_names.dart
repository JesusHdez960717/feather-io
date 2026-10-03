import 'package:console/app_exporter.dart';

/// Names of the routes and their parameters. A feature navigates to another
/// feature's screen by its route name, without importing it
abstract class RouteNames {
  static const String login = 'login';
  static const String browser = 'browser';
  static const String buckets = 'buckets';

  /// `?bucket=` of [browser]: the open bucket; without it, the bucket list
  static const String browserBucketParam = 'bucket';

  /// `?folder=` of [browser]: the open folder inside the bucket
  /// (`photos/2026`, without a trailing slash); without it, the bucket root
  static const String browserFolderParam = 'folder';

  /// `?view_type=` of [browser]: list or grid
  static const String browserViewTypeParam = 'view_type';

  /// `?bucket=` of [buckets]: the selected bucket
  static const String bucketsBucketParam = 'bucket';

  /// `?tab=` of [buckets]: the details tab (the general one by default)
  static const String bucketsTabParam = 'tab';

  /// Opens the browser at [folder] (`photos/2026/`, empty for the root) of [bucket]
  static void openBrowserFolder(String bucket, String folder) {
    final path = folder.endsWith('/')
        ? folder.substring(0, folder.length - 1)
        : folder;
    app.navigator.go(
      browser,
      queryParameters: {
        browserBucketParam: bucket,
        if (path.isNotEmpty) browserFolderParam: path,
      },
    );
  }

  /// Opens the *Buckets* section with [bucket] selected, on its general tab
  static void openBucketSettings(String bucket) {
    app.navigator.go(buckets, queryParameters: {bucketsBucketParam: bucket});
  }
}
