import 'package:console/app_exporter.dart';
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
    cubit = context.read();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.build(
        title: 'Buckets',
        actions: [
          IconButton(
            onPressed: () => cubit.loadBuckets(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocBuilder<BrowserCubit, BrowserState>(
        builder: (context, state) {
          if (state is BrowserInitialState) {
            cubit.loadBuckets();
            return const LoadingPage();
          }

          if (state is BrowserLoadingInProgressState) {
            return const LoadingPage();
          }

          if (state is BrowserLoadingErrorState) {
            return ErrorPage(
              message: state.message,
              onRetry: () => cubit.loadBuckets(),
            );
          }

          if (state is BrowserLoadingSuccessState) {
            if (state.buckets.isEmpty) {
              return const NoDataPage(title: 'No buckets found');
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Objects')),
                  DataColumn(label: Text('Size')),
                  DataColumn(label: Text('Created At')),
                ],
                rows: state.buckets.map((bucket) {
                  return DataRow(
                    cells: [
                      DataCell(Text(bucket.name)),
                      DataCell(Text(bucket.objectCount.toString())),
                      DataCell(
                        Text(
                          '${(bucket.sizeBytes / 1024).toStringAsFixed(2)} KB',
                        ),
                      ),
                      DataCell(
                        Text(app.dateFormatter.l.format(bucket.creationDate)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
