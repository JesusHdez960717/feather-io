import 'package:console/app_exporter.dart';
import 'package:console/features/browser/view/objects_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class BrowserScreenNavigator {
  String get name => 'browser';

  String get path => '/browser';

  Widget builder(BuildContext context, GoRouterState state) {
    return const BrowserScreen();
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
              title: isBucketSelected
                  ? 'Bucket: ${state.selectedBucket!.name}'
                  : 'Buckets',
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
                  ? ObjectsDataGrid(
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
                      onSelected: (obj) {
                        // TODO: Implement file selection
                      },
                    )
                  : BucketsSubScreen(
                      state: state,
                      onRefresh: () => cubit.refresh(),
                      onRetry: () => cubit.init(),
                      onSelected: (bucket) =>
                          cubit.selectBucket(bucket: bucket),
                    ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
