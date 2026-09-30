import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class BrowserScreenNavigator {
  String get name => 'browser';

  String get path => '/browser';

  Widget builder(BuildContext context, GoRouterState state) {
    final viewTypeStr = state.uri.queryParameters['view_type'];
    final initialViewType = ViewType.fromName(viewTypeStr);

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => BrowserCubit(
            auth: app.di.find(),
            repo: app.di.find(),
            initialViewType: initialViewType,
          ),
          lazy: false,
        ),
        BlocProvider(
          create: (context) => BucketCubit(app.di.find(), app.di.find()),
        ),
      ],
      child: BrowserScreen(initialBucket: state.extra as BucketModel?),
    );
  }

  ///Abre el explorador dentro de [bucket]
  void openBucket(BucketModel bucket) {
    app.navigator.go(name, extra: bucket);
  }

  void updateViewType(ViewType viewType) {
    app.navigator.go(name, queryParameters: {'view_type': viewType.name});
  }

  void neglectGo() {
    Router.neglect(app.context, () {
      app.navigator.go(name);
    });
  }
}

class BrowserScreen extends StatefulWidget {
  static final BrowserScreenNavigator navigator = BrowserScreenNavigator();

  ///Bucket que se abre al entrar (p. ej. desde la seccion *Buckets*)
  final BucketModel? initialBucket;

  const BrowserScreen({this.initialBucket, super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  late final BrowserCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = context.read<BrowserCubit>();
    final bucket = widget.initialBucket;
    if (bucket != null) {
      cubit.selectBucket(bucket: bucket);
    } else {
      cubit.init();
    }
  }

  @override
  void didUpdateWidget(covariant BrowserScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bucket = widget.initialBucket;
    if (bucket != null && bucket != oldWidget.initialBucket) {
      cubit.selectBucket(bucket: bucket);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BrowserCubit, BrowserState>(
      builder: (context, state) {
        if (state is BrowserInitialState) {
          return const LoadingPage();
        }

        if (state is BrowserSearchState) {
          final isBucketSelected = state.selectedBucket != null;
          return Scaffold(
            appBar: CustomAppBar.build(
              title: app.intl.navBrowser,
              leading: isBucketSelected
                  ? IconButton(
                      icon: app.assets.icons.navigation.left.build(
                        size: 22,
                        color: app.colors.neutral.white,
                      ),
                      onPressed: () => cubit.reset(),
                    )
                  : null,
            ),
            body: Padding(
              padding: EdgeInsets.only(
                left: app.dimensions.padding.l,
                right: app.dimensions.padding.l,
                top: app.dimensions.padding.l,
              ),
              child: isBucketSelected
                  ? ObjectsSubscreen(
                      state: state,
                      onNavigate: (prefix) => cubit.listObjects(prefix: prefix),
                      onRefresh: () => cubit.listObjects(prefix: state.prefix),
                      onBack: () => cubit.goUp(),
                      onForward: () => cubit.goForward(),
                      canGoForward: cubit.canGoForward,
                      onSelected: (obj) {},
                      onExit: () => cubit.reset(),
                      onDelete: (keys) => cubit.deleteObjects(
                        bucket: state.selectedBucket!,
                        keys: keys,
                      ),
                      onUpload: (files) => cubit.uploadFiles(
                        bucket: state.selectedBucket!,
                        prefix: state.prefix,
                        files: files,
                      ),
                      onDownload: (keys, {zipName}) => cubit.download(
                        bucket: state.selectedBucket!,
                        keys: keys,
                        zipName: zipName,
                      ),
                      onView: (key) => cubit.viewObject(
                        bucket: state.selectedBucket!,
                        key: key,
                      ),
                      onViewTypeChanged: (type) {
                        cubit.changeViewType(type);
                        BrowserScreen.navigator.updateViewType(type);
                      },
                    )
                  : BucketsSubScreen(
                      viewType: state.viewType,
                      onSelected: (bucket) =>
                          cubit.selectBucket(bucket: bucket),
                      onViewTypeChanged: (type) {
                        cubit.changeViewType(type);
                        BrowserScreen.navigator.updateViewType(type);
                      },
                    ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
