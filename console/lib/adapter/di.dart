import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

/// The only dependency on Get, the framework underneath, must live ONLY in this class

/// DI stands for Dependency Injection
/// The facade reduces the coupling of the app with the dependency injection
/// plugin in use.
/// Get is used here, but switching to another one, such as get_it, only means
/// changing the implementation of `find` and `put`.
///
/// To switch to get_it, for example, replace the implementation
/// of `put` with: `getIt.registerSingleton<SomeDependency>(SomeDependency());`
/// and of `find` with: `getIt<AppModel>();`
/// or their equivalents in each case
class DI {
  static final DI _instance = DI._internal();

  DI._internal();

  factory DI() => _instance;

  S put<S>(S dependency, {String? tag}) => Get.put<S>(dependency, tag: tag);

  S find<S>({String? tag}) => Get.find<S>(tag: tag);
}

/// CubitView is a great way of quickly access your Cubit
/// without having to call app.di.find&lt;AwesomeCubit&gt;() yourself.
///
/// Sample:
/// ```
/// class AwesomeCubit extends Cubit<SomeState> {
///   final String title = 'My Awesome View';
/// }
///
/// class AwesomeView extends CubitView<AwesomeCubit> {
///   AwesomeView({Key key}):super(key:key);
///
///   @override
///   Widget build(BuildContext context) {
///     return Container(
///       padding: EdgeInsets.all(20),
///       child: Text( cubit.title ),
///     );
///   }
/// }
/// ``
abstract class CubitView<T> extends StatelessWidget {
  const CubitView({super.key});

  T get cubit => Get.find<T>()!;

  @override
  Widget build(BuildContext context);
}
