import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class BrowserScreenNavigator {
  String get name => RouteNames.browser;

  String get path => '/browser';

  Widget builder(BuildContext context, GoRouterState state) {
    final params = state.uri.queryParameters;
    final viewType = ViewType.fromName(params[RouteNames.browserViewTypeParam]);

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => BrowserCubit(
            auth: app.di.find(),
            repo: app.di.find(),
            initialViewType: viewType,
          ),
          lazy: false,
        ),
        BlocProvider(
          create: (context) => BucketCubit(app.di.find(), app.di.find()),
        ),
      ],
      child: BrowserScreen(
        bucket: params[RouteNames.browserBucketParam],
        folder: _toPrefix(params[RouteNames.browserFolderParam]),
        viewType: viewType,
      ),
    );
  }

  /// Navigates to the bucket list or, with [bucket], to its folder [folder]
  /// (a prefix such as `photos/2026/`). The URL is the source of truth
  void show({String? bucket, String folder = '', ViewType? viewType}) {
    final folderParam = _toParam(folder);
    app.navigator.go(
      name,
      queryParameters: {
        RouteNames.browserBucketParam: ?bucket,
        if (bucket != null && folderParam.isNotEmpty)
          RouteNames.browserFolderParam: folderParam,
        RouteNames.browserViewTypeParam: ?viewType?.name,
      },
    );
  }

  /// Opens the browser at the root of [bucket]
  void openBucket(BucketModel bucket) => show(bucket: bucket.name);

  /// `photos/2026` (URL) → `photos/2026/` (S3 prefix)
  static String _toPrefix(String? folder) {
    final trimmed = (folder ?? '').replaceAll(RegExp(r'^/+|/+$'), '');
    return trimmed.isEmpty ? '' : '$trimmed/';
  }

  /// `photos/2026/` (S3 prefix) → `photos/2026` (URL)
  static String _toParam(String prefix) =>
      prefix.replaceAll(RegExp(r'^/+|/+$'), '');
}

/// Browser: the bucket list or the folders and objects of one. What is shown
/// comes from the URL (`?bucket=&folder=&view_type=`): every navigation
/// changes the URL and the screen follows it
class BrowserScreen extends StatefulWidget {
  static final BrowserScreenNavigator navigator = BrowserScreenNavigator();

  /// Open bucket; null shows the bucket list
  final String? bucket;

  /// Open folder as an S3 prefix (`photos/2026/`); empty is the root
  final String folder;
  final ViewType? viewType;

  const BrowserScreen({
    this.bucket,
    this.folder = '',
    this.viewType,
    super.key,
  });

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  late final BrowserCubit cubit;
  late final BucketCubit bucketCubit;

  @override
  void initState() {
    super.initState();
    cubit = context.read<BrowserCubit>();
    bucketCubit = context.read<BucketCubit>();
    _sync();
  }

  @override
  void didUpdateWidget(covariant BrowserScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.viewType != oldWidget.viewType) {
      cubit.changeViewType(widget.viewType ?? ViewType.list);
    }
    if (widget.bucket != oldWidget.bucket ||
        widget.folder != oldWidget.folder) {
      _sync();
    }
  }

  /// The bucket of the URL, if the bucket list is already known and it exists
  BucketModel? _urlBucket(BucketState state) {
    for (final bucket in state.buckets) {
      if (bucket.name == widget.bucket) return bucket;
    }
    return null;
  }

  /// Matches the [BrowserCubit] to the URL. Opening a bucket needs its model,
  /// so the bucket list is loaded first
  void _sync() {
    if (widget.bucket == null) {
      cubit.init();
      return;
    }
    final bucketState = bucketCubit.state;
    if (bucketState is BucketInitialState) {
      bucketCubit.load();
      return;
    }
    final bucket = _urlBucket(bucketState);
    if (bucket != null) cubit.open(bucket: bucket, prefix: widget.folder);
  }

  void _navigate({String? bucket, String folder = ''}) {
    BrowserScreen.navigator.show(
      bucket: bucket,
      folder: folder,
      viewType: widget.viewType,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BucketCubit, BucketState>(
      listenWhen: (previous, current) => current is BucketLoadingSuccessState,
      listener: (context, state) => _sync(),
      child: Scaffold(
        appBar: CustomAppBar.build(
          title: app.intl.navBrowser,
          leading: widget.bucket == null
              ? null
              : IconButton(
                  icon: app.assets.icons.navigation.left.build(
                    size: 22,
                    color: app.colors.neutral.white,
                  ),
                  onPressed: () => _navigate(),
                ),
        ),
        body: Padding(
          padding: EdgeInsets.only(
            left: app.dimensions.padding.l,
            right: app.dimensions.padding.l,
            top: app.dimensions.padding.l,
          ),
          child: widget.bucket == null ? _buildBuckets() : _buildBucket(),
        ),
      ),
    );
  }

  Widget _buildBuckets() {
    return BlocBuilder<BrowserCubit, BrowserState>(
      builder: (context, state) {
        final viewType = state is BrowserSearchState
            ? state.viewType
            : widget.viewType ?? ViewType.list;
        return BucketsSubScreen(
          viewType: viewType,
          onSelected: (bucket) => _navigate(bucket: bucket.name),
          onViewTypeChanged: (type) =>
              BrowserScreen.navigator.show(viewType: type),
        );
      },
    );
  }

  Widget _buildBucket() {
    return BlocBuilder<BucketCubit, BucketState>(
      builder: (context, bucketState) {
        if (_urlBucket(bucketState) == null) {
          if (bucketState is BucketLoadingSuccessState) {
            return BrowserNotFoundPage(
              title: app.intl.browserBucketNotFound(widget.bucket!),
              description: app.intl.browserBucketNotFoundDescription,
              action: app.intl.browserBackToBuckets,
              onAction: () => _navigate(),
            );
          }
          if (bucketState is BucketLoadingErrorState) {
            return ErrorPage(
              message: bucketState.exception.message,
              onRetry: bucketCubit.load,
            );
          }
          return const LoadingPage();
        }
        return BlocBuilder<BrowserCubit, BrowserState>(
          builder: (context, state) {
            if (state is! BrowserSearchState ||
                state.selectedBucket?.name != widget.bucket) {
              return const LoadingPage();
            }
            final bucket = state.selectedBucket!;
            return ObjectsSubscreen(
              state: state,
              onNavigate: (prefix) =>
                  _navigate(bucket: bucket.name, folder: prefix),
              onRefresh: cubit.refresh,
              onBack: () {
                final parent = cubit.goUp();
                if (parent == null) {
                  _navigate();
                } else {
                  _navigate(bucket: bucket.name, folder: parent);
                }
              },
              onForward: () {
                final next = cubit.goForward();
                if (next != null) _navigate(bucket: bucket.name, folder: next);
              },
              onSelected: (obj) {},
              onExit: () => _navigate(),
              onDelete: (keys) =>
                  cubit.deleteObjects(bucket: bucket, keys: keys),
              onUpload: (files) {
                app.di.find<TransferCubit>().upload(
                  bucket: bucket.name,
                  prefix: state.prefix,
                  files: files,
                );
                app.snack.showSuccess(
                  message: app.intl.transfersUploadsAdded(files.length),
                  context: context,
                );
              },
              onDownload: (keys, {zipName}) {
                // Once: without a name it carries the time, and the snackbar
                // must show the same one as the transfers panel
                final name = TransferCubit.zipFileName(keys, zipName: zipName);
                app.di.find<TransferCubit>().download(
                  bucket: bucket.name,
                  keys: keys,
                  zipName: name,
                );
                app.snack.showSuccess(
                  message: app.intl.transfersDownloadAdded(name),
                  context: context,
                );
              },
              onView: (key) => cubit.viewObject(bucket: bucket, key: key),
              onViewTypeChanged: (type) => BrowserScreen.navigator.show(
                bucket: bucket.name,
                folder: state.prefix,
                viewType: type,
              ),
              onNextPage: cubit.nextPage,
              onPreviousPage: cubit.previousPage,
              onPageSizeChanged: cubit.changePageSize,
              bucketNames: [for (final b in bucketCubit.state.buckets) b.name],
            );
          },
        );
      },
    );
  }
}
