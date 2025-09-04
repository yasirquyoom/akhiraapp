import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../data/helper/dio_client.dart';
import '../../router/app_router.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Router
  getIt.registerLazySingleton<AppRouter>(() => AppRouter());

  // Dio and client
  getIt.registerLazySingleton<Dio>(() => Dio());
  getIt.registerLazySingleton<DioClient>(() => DioClient(getIt<Dio>()));

  // TODO: register APIs and repositories
}
