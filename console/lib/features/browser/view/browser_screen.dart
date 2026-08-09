import 'package:console/app_exporter.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class BrowserScreenNavigator {
  String get name => 'browser';

  String get path => '/browser';

  Widget builder(BuildContext context, GoRouterState state) {
    final viewTypeStr = state.uri.queryParameters['view_type'];
    final initialViewType = ViewType.fromName(viewTypeStr);

    return BlocProvider(
      create: (context) => BrowserCubit(
        auth: app.di.find(),
        repo: app.di.find(),
        initialViewType: initialViewType,
      ),
      lazy: false,
      child: const BrowserScreen(),
    );
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

  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  late final BrowserCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = context.read<BrowserCubit>();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BrowserCubit, BrowserState>(
      buildWhen: (previous, current) =>
          current is BrowserSearchState || current is BrowserInitialState,
      builder: (context, state) {
        if (state is BrowserInitialState) {
          cubit.init();
          return const LoadingPage();
        }

        if (state is BrowserSearchState) {
          final isBucketSelected = state.selectedBucket != null;
          return Scaffold(
            appBar: CustomAppBar.build(
              title: 'Browser',
              leading: isBucketSelected
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
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
                      onBack: () {
                        final parts = state.prefix
                            .split('/')
                            .where((s) => s.isNotEmpty)
                            .toList();
                        if (parts.isEmpty) {
                          cubit.reset();
                        } else {
                          parts.removeLast();
                          final newPrefix = parts.isEmpty
                              ? ''
                              : '${parts.join('/')}/';
                          cubit.listObjects(prefix: newPrefix);
                        }
                      },
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
                      state: state,
                      onRefresh: () => cubit.refresh(),
                      onRetry: () => cubit.init(),
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
