import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class BucketAdminScreenNavigator {
  String get name => RouteNames.buckets;

  String get path => '/buckets';

  Widget builder(BuildContext context, GoRouterState state) {
    final params = state.uri.queryParameters;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => BucketCubit(app.di.find(), app.di.find()),
        ),
        BlocProvider(
          create: (context) =>
              AnonymousAccessCubit(app.di.find(), app.di.find()),
        ),
      ],
      child: BucketAdminScreen(
        bucket: params[RouteNames.bucketsBucketParam],
        tab:
            BucketAdminTab.values
                .asNameMap()[params[RouteNames.bucketsTabParam]] ??
            BucketAdminTab.general,
      ),
    );
  }

  /// Changes the bucket or tab shown; the URL is the source of truth
  void show({required String bucket, required BucketAdminTab tab}) {
    app.navigator.go(
      name,
      queryParameters: {
        RouteNames.bucketsBucketParam: bucket,
        RouteNames.bucketsTabParam: tab.name,
      },
    );
  }
}

/// *Buckets* section: the bucket list on the left and the details of the
/// selected one, with its tabs, on the right. The bucket and the tab come from
/// the URL (`?bucket=&tab=`): selecting another one or switching tabs navigates
class BucketAdminScreen extends StatefulWidget {
  static final BucketAdminScreenNavigator navigator =
      BucketAdminScreenNavigator();

  /// Selected bucket; if null or it no longer exists, the first one is shown
  final String? bucket;
  final BucketAdminTab tab;

  const BucketAdminScreen({required this.tab, this.bucket, super.key});

  @override
  State<BucketAdminScreen> createState() => _BucketAdminScreenState();
}

class _BucketAdminScreenState extends State<BucketAdminScreen> {
  late final BucketCubit cubit;
  late final AnonymousAccessCubit accessCubit;

  @override
  void initState() {
    super.initState();
    cubit = context.read<BucketCubit>()..load();
    accessCubit = context.read<AnonymousAccessCubit>();
  }

  @override
  void didUpdateWidget(covariant BucketAdminScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bucket != oldWidget.bucket) _syncRules(cubit.state.buckets);
  }

  /// The one in the URL or, if there is none or it no longer exists (e.g. just deleted), the first
  BucketModel? _selected(List<BucketModel> buckets) {
    if (buckets.isEmpty) return null;
    return buckets.firstWhere(
      (b) => b.name == widget.bucket,
      orElse: () => buckets.first,
    );
  }

  /// Loads the rules of the shown bucket (for its tab's counter)
  void _syncRules(List<BucketModel> buckets) {
    final selected = _selected(buckets);
    if (selected != null && accessCubit.state.bucket != selected.name) {
      accessCubit.load(bucket: selected.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.build(title: app.intl.navBuckets),
      body: BlocConsumer<BucketCubit, BucketState>(
        listener: (context, state) {
          if (state is BucketProcessInProgressState) {
            app.loading.show(id: loadingOverlayGlobalId);
          } else {
            app.loading.hide(id: loadingOverlayGlobalId);
          }
          if (state is BucketProcessingErrorState) {
            app.snack.showError(message: state.message, context: context);
          }
          if (state is BucketLoadingSuccessState) _syncRules(state.buckets);
        },
        builder: (context, state) {
          final selected = _selected(state.buckets);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BucketAdminList(
                state: state,
                selected: selected,
                onSelected: (bucket) => BucketAdminScreen.navigator.show(
                  bucket: bucket.name,
                  tab: widget.tab,
                ),
              ),
              VerticalDivider(
                thickness: 1,
                width: 1,
                color: app.colors.neutral.grey5,
              ),
              Expanded(child: _buildDetail(state, selected)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetail(BucketState state, BucketModel? selected) {
    if (selected != null) {
      return BucketAdminDetail(
        bucket: selected,
        tab: widget.tab,
        onTabChanged: (tab) =>
            BucketAdminScreen.navigator.show(bucket: selected.name, tab: tab),
      );
    }
    if (state is BucketLoadingErrorState) {
      return ErrorPage(message: state.exception.message, onRetry: cubit.load);
    }
    if (state is BucketLoadingSuccessState) {
      return NoDataPage(
        title: app.intl.bucketsEmpty,
        description: app.intl.bucketAdminEmptyDescription,
      );
    }
    return const LoadingPage();
  }
}
