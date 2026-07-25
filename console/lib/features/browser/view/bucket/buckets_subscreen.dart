import 'dart:ui';

import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';

import 'buckets_grid_datasource.dart';
import 'buckets_table_datasource.dart';

class BucketsSubScreen extends StatefulWidget {
  final BrowserSearchState state;
  final VoidCallback onRefresh;
  final VoidCallback onRetry;
  final Function(BucketModel) onSelected;
  final Function(ViewType) onViewTypeChanged;

  const BucketsSubScreen({
    required this.state,
    required this.onRefresh,
    required this.onRetry,
    required this.onSelected,
    required this.onViewTypeChanged,
    super.key,
  });

  @override
  State<BucketsSubScreen> createState() => _BucketsSubScreenState();
}

class _BucketsSubScreenState extends State<BucketsSubScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<BucketModel> _filteredBuckets = [];

  @override
  void initState() {
    super.initState();
    _filteredBuckets = widget.state.buckets;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(covariant BucketsSubScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.buckets != widget.state.buckets) {
      _onSearchChanged();
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredBuckets = widget.state.buckets;
      } else {
        _filteredBuckets = widget.state.buckets
            .where((b) => b.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        app.dimensions.padding.xl.gap(),
        _buildSummaryCards(),
        (1.5 * app.dimensions.padding.xl).gap(),
        Expanded(
          child: ClipRect(
            child: Stack(
              children: [
                IgnorePointer(
                  ignoring: widget.state is! BrowserSearchOkState,
                  child: Column(
                    children: [
                      _buildSearchSection(),
                      Expanded(
                        child: widget.state.viewType == ViewType.list
                            ? BucketsTableDatasource(
                                state: widget.state,
                                filteredBuckets: _filteredBuckets,
                                searchController: _searchController,
                                onSelected: widget.onSelected,
                              )
                            : BucketsGridDatasource(
                                state: widget.state,
                                filteredBuckets: _filteredBuckets,
                                searchController: _searchController,
                                onSelected: widget.onSelected,
                              ),
                      ),
                    ],
                  ),
                ),
                if (widget.state is BrowserSearchingState)
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                      child: Container(
                        color: app.colors.neutral.black.withValues(alpha: 0.08),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: app.colors.primary.purple,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (widget.state is BrowserSearchErrorState)
                  Positioned.fill(
                    child: ErrorPage(
                      message: (widget.state as BrowserSearchErrorState)
                          .exception
                          .message,
                      onRetry: widget.onRetry,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Buckets',
              style: app.textTheme.headlineMedium?.copyWith(
                color: app.colors.neutral.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Manage your S3 compatible buckets and storage resources.',
              style: app.textTheme.bodyMedium?.copyWith(
                color: app.colors.neutral.grey3,
              ),
            ),
          ],
        ),
        const Spacer(),
        Row(
          children: [
            PrimaryButton.secondary(
              onPressed: widget.onRefresh,
              title: 'Refresh',
              h: 42,
              w: 120,
              icon: app.assets.icons.actions.refresh,
            ),
            app.dimensions.padding.m.gap(),
            PrimaryButton.primary(
              onPressed: () {},
              title: 'Create Bucket',
              h: 42,
              w: 160,
              icon: app.assets.icons.actions.add,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    Widget buildSummaryCard({
      required String title,
      required String value,
      required SvgAsset icon,
    }) {
      return Expanded(
        child: Container(
          padding: EdgeInsets.all(app.dimensions.padding.l),
          decoration: BoxDecoration(
            color: app.colors.primary.background2,
            borderRadius: app.dimensions.border.borderRadius.m,
            border: Border.all(color: app.colors.neutral.grey5),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(app.dimensions.padding.m),
                decoration: BoxDecoration(
                  color: Color.lerp(
                    app.colors.primary.purple,
                    app.colors.neutral.white,
                    0.1,
                  )!.withValues(alpha: 0.2),
                  borderRadius: app.dimensions.border.borderRadius.m,
                ),
                child: icon.build(size: 24, color: app.colors.neutral.grey1),
              ),
              app.dimensions.padding.l.gap(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: app.textTheme.bodyMedium?.copyWith(
                      color: app.colors.neutral.grey1,
                    ),
                  ),
                  Text(
                    value,
                    style: app.textTheme.headlineSmall?.copyWith(
                      color: app.colors.neutral.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final totalBuckets = widget.state.buckets.length;
    final totalObjects = widget.state.buckets.fold<int>(
      0,
      (sum, b) => sum + b.objectCount,
    );
    final totalSizeBytes = widget.state.buckets.fold<int>(
      0,
      (sum, b) => sum + b.sizeBytes,
    );

    return Row(
      children: [
        buildSummaryCard(
          title: 'Total Buckets',
          value: totalBuckets.toString(),
          icon: app.assets.icons.storage.bucket,
        ),
        app.dimensions.padding.l.gap(),
        buildSummaryCard(
          title: 'Total Objects',
          value: totalObjects.toString(),
          icon: app.assets.icons.storage.object,
        ),
        app.dimensions.padding.l.gap(),
        buildSummaryCard(
          title: 'Total Storage',
          value: app.storageFormatter.formatSize(totalSizeBytes),
          icon: app.assets.icons.storage.storage,
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    return Container(
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
                  // Handled by listener
                },
                hint: 'Search buckets...',
              ),
            ),
            app.dimensions.padding.l.gap(),
            ViewTypeSelector(
              currentType: widget.state.viewType,
              onChanged: widget.onViewTypeChanged,
            ),
          ],
        ),
      ),
    );
  }
}
