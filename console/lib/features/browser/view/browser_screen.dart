import 'dart:ui';

import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

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
  final TextEditingController _searchController = TextEditingController();

  Map<String, double?> columnWidths = {
    'name': null,
    'objects': null,
    'size': null,
    'created_at': null,
  };

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
          return Scaffold(
            appBar: CustomAppBar.build(title: 'Buckets'),
            body: Padding(
              padding: EdgeInsets.only(
                left: app.dimensions.padding.l,
                right: app.dimensions.padding.l,
                top: app.dimensions.padding.l,
              ),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: app.colors.primary.background2,
                      borderRadius: BorderRadius.only(
                        topLeft: app.dimensions.border.radius.m,
                        topRight: app.dimensions.border.radius.m,
                      ),
                      border: Border.all(color: app.colors.neutral.grey5),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(app.dimensions.padding.l),
                      child: Row(
                        children: [
                          Expanded(
                            child: EMTextSearchField(
                              controller: _searchController,
                              onSearch: (value) {
                                cubit.applySearch(query: value);
                              },
                              hint: 'Search buckets...',
                            ),
                          ),
                          app.dimensions.padding.l.gap(),
                          PrimaryButton.secondary(
                            onPressed: () {
                              cubit.refresh();
                            },
                            title: 'Refresh',
                            h: 42,
                            icon: app.assets.icons.actions.refresh,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return ClipRect(
                          child: Stack(
                            children: [
                              IgnorePointer(
                                ignoring: state is! BrowserSearchOkState,
                                child: _buildBucketsDataGrid(
                                  state,
                                  constraints,
                                ),
                              ),
                              if (state is BrowserSearchingState)
                                Positioned.fill(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 0.5,
                                      sigmaY: 0.5,
                                    ),
                                    child: Container(
                                      color: app.colors.neutral.black
                                          .withValues(alpha: 0.08),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: app.colors.primary.purple,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (state is BrowserSearchErrorState)
                                Positioned.fill(
                                  child: ErrorPage(
                                    message: state.exception.message,
                                    onRetry: () => cubit.init(),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  TablePagedFooter(
                    currentPageSize: state.currentPageSize,
                    pageSizes: state.pageSizes,
                    currentPage: state.currentPage,
                    totalPages: state.totalPages,
                    onPageSizeChanged: (newPageSize) {
                      cubit.init(pageSize: newPageSize);
                    },
                    onPageChanged: (newPage) {
                      cubit.init(page: newPage);
                    },
                  ),
                ],
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildBucketsDataGrid(
    BrowserSearchState state,
    BoxConstraints constraints,
  ) {
    final totalWidth = constraints.maxWidth;

    final nameWidth = totalWidth * 0.4;
    final objectsWidth = totalWidth * 0.15;
    final sizeWidth = totalWidth * 0.2;
    final createdAtWidth = (totalWidth - (nameWidth + objectsWidth + sizeWidth))
        .clamp(130.0, totalWidth);

    Widget header(String text) {
      return Padding(
        padding: EdgeInsets.all(app.dimensions.padding.s),
        child: Text(
          text,
          style: app.textTheme.bodyLarge!.copyWith(
            color: app.colors.neutral.grey3,
          ),
        ),
      );
    }

    final buckets = state.bucketsPerPage[state.currentPage] ?? [];

    if (buckets.isEmpty &&
        _searchController.text.isEmpty &&
        state is BrowserSearchOkState) {
      return const NoDataPage(title: 'No buckets found');
    }

    _BucketsDataSource dataSource = _BucketsDataSource(buckets: buckets);

    return SfDataGrid(
      source: dataSource,
      headerRowHeight: 42,
      rowHeight: 42,
      allowColumnsResizing: true,
      onColumnResizeUpdate: (details) {
        setState(() {
          columnWidths[details.column.columnName] = details.width;

          final sum = columnWidths.values.fold(
            0.0,
            (previousValue, element) => previousValue + (element ?? 0),
          );

          final dif = totalWidth - sum;
          if (columnWidths['created_at'] == null) {
            columnWidths['created_at'] = createdAtWidth + dif;
          } else {
            columnWidths['created_at'] = columnWidths['created_at']! + dif;
          }
        });
        return true;
      },
      columns: [
        GridColumn(
          columnName: 'name',
          width: columnWidths['name'] ?? nameWidth,
          minimumWidth: 150,
          label: header('Name'),
        ),
        GridColumn(
          columnName: 'objects',
          width: columnWidths['objects'] ?? objectsWidth,
          minimumWidth: 100,
          label: header('Objects'),
        ),
        GridColumn(
          columnName: 'size',
          width: columnWidths['size'] ?? sizeWidth,
          minimumWidth: 100,
          label: header('Size'),
        ),
        GridColumn(
          columnName: 'created_at',
          width: columnWidths['created_at'] ?? createdAtWidth,
          minimumWidth: 150,
          label: header('Created At'),
        ),
      ],
    );
  }
}

class _BucketsDataSource extends DataGridSource {
  final List<BucketModel> buckets;

  _BucketsDataSource({required this.buckets}) {
    _rows = buckets.map(_buildRow).toList();
  }

  late final List<DataGridRow> _rows;

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((cell) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              cell.value.toString(),
              style: app.textTheme.bodyMedium?.copyWith(
                color: app.colors.neutral.white,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  DataGridRow _buildRow(BucketModel bucket) {
    return DataGridRow(
      cells: [
        DataGridCell<String>(columnName: 'name', value: bucket.name),
        DataGridCell<int>(columnName: 'objects', value: bucket.objectCount),
        DataGridCell<String>(
          columnName: 'size',
          value: '${(bucket.sizeBytes / 1024).toStringAsFixed(2)} KB',
        ),
        DataGridCell<String>(
          columnName: 'created_at',
          value: app.dateFormatter.l.format(bucket.creationDate),
        ),
      ],
    );
  }
}
