import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

///Columna izquierda de la seccion *Buckets*: buscador, crear y la lista
class BucketAdminList extends StatefulWidget {
  static const double width = 320;

  final BucketState state;
  final BucketModel? selected;
  final ValueChanged<BucketModel> onSelected;

  const BucketAdminList({
    required this.state,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  @override
  State<BucketAdminList> createState() => _BucketAdminListState();
}

class _BucketAdminListState extends State<BucketAdminList> {
  final _searchController = TextEditingController();

  ///Texto buscado, en minusculas
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BucketModel> get _filtered {
    if (_query.isEmpty) return widget.state.buckets;
    return widget.state.buckets
        .where((b) => b.name.toLowerCase().contains(_query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final buckets = _filtered;
    return Container(
      width: BucketAdminList.width,
      color: app.colors.primary.background2,
      padding: EdgeInsets.all(app.dimensions.padding.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AppTextSearchField(
                  controller: _searchController,
                  //filtra la lista ya cargada: sin espera
                  delay: 0,
                  onSearch: (value) =>
                      setState(() => _query = value.toLowerCase()),
                  hint: app.intl.bucketsSearchHint,
                ),
              ),
              app.dimensions.padding.s.gap(),
              Tooltip(
                message: app.intl.bucketsCreate,
                child: PrimaryButton.svgIcon(
                  onPressed: () => BucketForm.open(context),
                  icon: app.assets.icons.actions.add,
                  backgroundColor: app.colors.palette.violet,
                  iconColor: app.colors.neutral.white,
                  buttonSize: 42,
                  iconSize: 18,
                ),
              ),
            ],
          ),
          app.dimensions.padding.l.gap(),
          Text(
            app.intl.bucketAdminCount(widget.state.buckets.length).toUpperCase(),
            style: app.textTheme.labelMedium?.copyWith(
              color: app.colors.primary.primaryFaded,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          app.dimensions.padding.s.gap(),
          Expanded(
            child: LoadingOverlay(
              visible: widget.state is BucketLoadingInProgressState,
              overlayWidgetBuilder: LoadingOverlayStyles.table,
              disableBackButton: false,
              child: buckets.isEmpty && _query.isNotEmpty
                  ? Center(
                      child: Text(
                        app.intl.bucketsNoMatch(_searchController.text),
                        textAlign: TextAlign.center,
                        style: app.textTheme.bodyMedium?.copyWith(
                          color: app.colors.neutral.grey3,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: buckets.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final bucket = buckets[index];
                        return _BucketTile(
                          bucket: bucket,
                          selected: bucket.name == widget.selected?.name,
                          onTap: () => widget.onSelected(bucket),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BucketTile extends StatelessWidget {
  final BucketModel bucket;
  final bool selected;
  final VoidCallback onTap;

  const _BucketTile({
    required this.bucket,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: app.dimensions.border.borderRadius.m,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: app.dimensions.padding.m,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: selected
                ? app.colors.primary.background3
                : app.colors.neutral.transparent,
            borderRadius: app.dimensions.border.borderRadius.m,
            border: Border.all(
              color: selected
                  ? app.colors.primary.primaryFaded
                  : app.colors.neutral.transparent,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      bucket.uiColor ??
                      app.colors.primary.purple.withValues(alpha: 0.6),
                  borderRadius: app.dimensions.border.borderRadius.s,
                ),
                child: app.assets.icons.storage.bucket.build(
                  size: 20,
                  color: app.colors.neutral.white,
                ),
              ),
              app.dimensions.padding.m.gap(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bucket.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: app.textTheme.bodyLarge?.copyWith(
                        fontWeight: selected ? FontWeight.bold : null,
                      ),
                    ),
                    Text(
                      app.intl.bucketAdminStats(
                        bucket.objectCount,
                        app.storageFormatter.formatSize(bucket.sizeBytes),
                      ),
                      style: app.textTheme.bodySmall?.copyWith(
                        color: selected
                            ? app.colors.neutral.grey2
                            : app.colors.neutral.grey3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
