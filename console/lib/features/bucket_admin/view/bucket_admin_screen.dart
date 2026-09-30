import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class BucketAdminScreenNavigator {
  String get name => 'buckets';

  String get path => '/buckets';

  Widget builder(BuildContext context, GoRouterState state) {
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
        initialBucket: state.uri.queryParameters['bucket'],
      ),
    );
  }
}

///Seccion *Buckets*: a la izquierda la lista de buckets y a la derecha el
///detalle del seleccionado, con sus pestañas
class BucketAdminScreen extends StatefulWidget {
  static final BucketAdminScreenNavigator navigator =
      BucketAdminScreenNavigator();

  ///Nombre del bucket a seleccionar al entrar (`?bucket=`)
  final String? initialBucket;

  const BucketAdminScreen({this.initialBucket, super.key});

  @override
  State<BucketAdminScreen> createState() => _BucketAdminScreenState();
}

class _BucketAdminScreenState extends State<BucketAdminScreen> {
  late final BucketCubit cubit;
  late final AnonymousAccessCubit accessCubit;

  String? _selectedName;
  BucketAdminTab _tab = BucketAdminTab.general;

  @override
  void initState() {
    super.initState();
    _selectedName = widget.initialBucket;
    cubit = context.read<BucketCubit>()..load();
    accessCubit = context.read<AnonymousAccessCubit>();
  }

  ///El seleccionado o, si ya no existe (p. ej. se acaba de borrar), el primero
  BucketModel? _selected(List<BucketModel> buckets) {
    if (buckets.isEmpty) return null;
    return buckets.firstWhere(
      (b) => b.name == _selectedName,
      orElse: () => buckets.first,
    );
  }

  void _select(BucketModel bucket) {
    if (bucket.name == _selectedName) return;
    setState(() => _selectedName = bucket.name);
    accessCubit.load(bucket: bucket.name);
  }

  ///Carga las reglas del bucket mostrado (para el contador de su pestaña)
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
                onSelected: _select,
                onRetry: cubit.load,
              ),
              VerticalDivider(
                thickness: 1,
                width: 1,
                color: app.colors.neutral.grey5,
              ),
              Expanded(
                child: _buildDetail(state, selected),
              ),
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
        tab: _tab,
        onTabChanged: (tab) => setState(() => _tab = tab),
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
