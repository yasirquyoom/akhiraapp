import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../data/cubits/audio/audio_cubit.dart';
import '../../data/cubits/home/home_cubit.dart';
import '../../data/cubits/images/images_cubit.dart';
import '../../data/helper/dio_client.dart';
import '../../data/services/image_download_service.dart';
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

  // Services
  getIt.registerLazySingleton<ImageDownloadService>(
    () => ImageDownloadService(),
  );

  // Cubits
  getIt.registerFactory<HomeCubit>(() => HomeCubit());
  getIt.registerLazySingleton<AudioCubit>(() => AudioCubit());
  getIt.registerLazySingleton<ImagesCubit>(() => ImagesCubit());

  // TODO: register APIs and repositories
}
