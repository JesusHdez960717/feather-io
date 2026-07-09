import 'dart:io';

import 'package:dio/dio.dart';
import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FeaturesInit {
  static Future<void> init() async {
    FlutterSecureStorage storage = const FlutterSecureStorage(
      webOptions: WebOptions(publicKey: 'exp-man-admin'),
    );
    app.di.put(storage);

    Dio dio = Dio();
    dio
      ..options.connectTimeout = const Duration(seconds: 10)
      ..options.receiveTimeout = const Duration(seconds: 10)
      ..httpClientAdapter
      ..options.headers = {
        HttpHeaders.contentTypeHeader: ContentType.json.mimeType,
      };
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException e, ErrorInterceptorHandler handler) async {
          if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
            app.di.find<AuthCubit>().logout();
          }
          return handler.next(e);
        },
      ),
    );
    app.di.put(dio);

    await AuthInit.init();
    await LanguageInit.init();

    await Future.wait([
      UsersInit.init(),
    ]);

    //once the auth is initialized, I subscribe to listen to logout changes to reset cubits
    /*app.di.find<AuthCubit>().stream.listen((event) async {
      if (event is AuthLogoutOkState) {
        app.loading.hide();
        await _resetCubits();
        LoginScreen.navigator.neglectGo();
      }
    });*/
  }

  static Future<void> _resetCubits() async {
  }

  static List<BlocProvider> blocProviders = [
    //AUTH
    //BlocProvider<AuthCubit>(create: (context) => app.di.find<AuthCubit>()),
    //LANGUAGE
    BlocProvider<LanguageCubit>(
      create: (context) => app.di.find<LanguageCubit>(),
    ),
  ];
}
