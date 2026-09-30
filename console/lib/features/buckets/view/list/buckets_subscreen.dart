import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'buckets_grid_datasource.dart';
import 'buckets_table_datasource.dart';

class BucketsSubScreen extends StatefulWidget {
  final ViewType viewType;
  final Function(BucketModel) onSelected;
  final Function(ViewType) onViewTypeChanged;

  const BucketsSubScreen({
    required this.viewType,
    required this.onSelected,
    required this.onViewTypeChanged,
    super.key,
  });

  @override
  State<BucketsSubScreen> createState() => _BucketsSubScreenState();
}

class _BucketsSubScreenState extends State<BucketsSubScreen> {
  late final BucketCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = context.read<BucketCubit>();
    cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BucketCubit, BucketState>(
      listener: (context, state) {
        if (state is BucketProcessInProgressState) {
          app.loading.show(id: loadingOverlayGlobalId);
        } else {
          app.loading.hide(id: loadingOverlayGlobalId);
        }

        if (state is BucketProcessingErrorState) {
          app.snack.showError(message: state.message, context: context);
        }
      },
      builder: (context, state) {
        return _BucketsView(
          state: state,
          viewType: widget.viewType,
          onRefresh: cubit.load,
          onRetry: cubit.load,
          onSelected: widget.onSelected,
          onDelete: (bucket) => cubit.deleteBucket(bucket: bucket),
          onViewTypeChanged: widget.onViewTypeChanged,
        );
      },
    );
  }
}

class _BucketsView extends StatefulWidget {
  final BucketState state;
  final ViewType viewType;
  final VoidCallback onRefresh;
  final VoidCallback onRetry;
  final Function(BucketModel) onSelected;
  final Function(BucketModel) onDelete;
  final Function(ViewType) onViewTypeChanged;

  const _BucketsView({
    required this.state,
    required this.viewType,
    required this.onRefresh,
    required this.onRetry,
    required this.onSelected,
    required this.onDelete,
    required this.onViewTypeChanged,
  });

  @override
  State<_BucketsView> createState() => _BucketsViewState();
}

class _BucketsViewState extends State<_BucketsView> {
  final TextEditingController _searchController = TextEditingController();
  List<BucketModel> _filteredBuckets = [];

  @override
  void initState() {
    super.initState();
    _filteredBuckets = widget.state.buckets;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(covariant _BucketsView oldWidget) {
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

  void _onDeleteSelected(BucketModel selected) {
    ConfirmDialog.show(
      title: app.intl.bucketsDeleteTitle,
      description: app.intl.bucketsDeleteConfirm(selected.name),
      confirmTitle: app.intl.delete,
      confirmColor: app.colors.primary.errorAction,
      confirmAction: () => widget.onDelete(selected),
    );
  }

  void _onShowBucketOptions(BucketModel bucket, RenderBox buttonBox) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        buttonBox.localToGlobal(Offset.zero, ancestor: overlay),
        buttonBox.localToGlobal(
          buttonBox.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      color: app.colors.primary.background2,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: app.dimensions.border.borderRadius.s,
        side: BorderSide(color: app.colors.neutral.grey5),
      ),
      items: [
        PopupMenuItem(
          value: 'edit',
          onTap: () => BucketForm.open(context, bucket: bucket),
          child: Row(
            children: [
              app.assets.icons.actions.edit.build(
                size: 18,
                color: app.colors.neutral.white,
              ),
              app.dimensions.padding.m.gap(),
              Text(
                app.intl.edit,
                style: app.textTheme.bodyMedium?.copyWith(
                  color: app.colors.neutral.white,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          onTap: () {
            _onDeleteSelected(bucket);
          },
          child: Row(
            children: [
              app.assets.icons.actions.delete.build(
                size: 18,
                color: app.colors.primary.error,
              ),
              app.dimensions.padding.m.gap(),
              Text(
                app.intl.delete,
                style: app.textTheme.bodyMedium?.copyWith(
                  color: app.colors.primary.error,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
                LoadingOverlay(
                  visible: widget.state is BucketLoadingInProgressState,
                  overlayWidgetBuilder: LoadingOverlayStyles.table,
                  disableBackButton: false,
                  child: IgnorePointer(
                    ignoring: widget.state is! BucketLoadingSuccessState,
                    child: Column(
                      children: [
                        _buildSearchSection(),
                        Expanded(
                          child: widget.viewType == ViewType.list
                              ? BucketsTableDatasource(
                                  state: widget.state,
                                  filteredBuckets: _filteredBuckets,
                                  searchController: _searchController,
                                  onSelected: widget.onSelected,
                                  onShowOptions: _onShowBucketOptions,
                                )
                              : BucketsGridDatasource(
                                  state: widget.state,
                                  filteredBuckets: _filteredBuckets,
                                  searchController: _searchController,
                                  onSelected: widget.onSelected,
                                  onShowOptions: _onShowBucketOptions,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.state is BucketLoadingErrorState)
                  Positioned.fill(
                    child: ErrorPage(
                      message: (widget.state as BucketLoadingErrorState)
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
              app.intl.bucketsTitle,
              style: app.textTheme.headlineMedium?.copyWith(
                color: app.colors.neutral.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              app.intl.bucketsSubtitle,
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
              title: app.intl.refresh,
              h: 42,
              w: 120,
              icon: app.assets.icons.actions.refresh,
            ),
            app.dimensions.padding.m.gap(),
            PrimaryButton.primary(
              onPressed: () {
                BucketForm.open(context);
              },
              title: app.intl.bucketsCreate,
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
          title: app.intl.bucketsTotalBuckets,
          value: totalBuckets.toString(),
          icon: app.assets.icons.storage.bucket,
        ),
        app.dimensions.padding.l.gap(),
        buildSummaryCard(
          title: app.intl.bucketsTotalObjects,
          value: totalObjects.toString(),
          icon: app.assets.icons.storage.object,
        ),
        app.dimensions.padding.l.gap(),
        buildSummaryCard(
          title: app.intl.bucketsTotalStorage,
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
              child: AppTextSearchField(
                controller: _searchController,
                onSearch: (value) {
                  // Handled by listener
                },
                hint: app.intl.bucketsSearchHint,
              ),
            ),
            app.dimensions.padding.l.gap(),
            ViewTypeSelector(
              currentType: widget.viewType,
              onChanged: widget.onViewTypeChanged,
            ),
          ],
        ),
      ),
    );
  }
}
