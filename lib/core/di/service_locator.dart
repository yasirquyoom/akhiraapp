import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../data/cubits/home/home_cubit.dart';
import '../../data/helper/dio_client.dart';
import '../../router/app_router.dart';
import '../language/language_manager.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Language Manager
  getIt.registerLazySingleton<LanguageManager>(() => LanguageManager());

  // Router
  getIt.registerLazySingleton<AppRouter>(() => AppRouter());

  // Dio and client
  getIt.registerLazySingleton<Dio>(() => Dio());
  getIt.registerLazySingleton<DioClient>(() => DioClient(getIt<Dio>()));

  // Cubits
  getIt.registerFactory<HomeCubit>(() => HomeCubit());

  // TODO: register APIs and repositories
}
