import 'package:akhira/data/repositories/collection_repository.dart';
import 'package:akhira/data/repositories/book_content_repository.dart';
import 'package:akhira/data/repositories/quiz_repository.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../data/cubits/audio/audio_cubit.dart';
import '../../data/cubits/auth/auth_cubit.dart';
import '../../data/cubits/book/book_state.dart';
import '../../data/cubits/book_content/book_content_state.dart';
import '../../data/cubits/home/home_cubit.dart';
import '../../data/cubits/images/images_cubit.dart';
import '../../data/cubits/pdf/pdf_cubit.dart';
import '../../data/cubits/quiz/quiz_cubit_new.dart';
import '../../data/cubits/videos/videos_cubit.dart';
import '../../data/helper/dio_client.dart';
import '../../data/repositories/auth_repository.dart';
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

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<CollectionRepository>(
    () => CollectionRepository(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<BookContentRepository>(
    () => BookContentRepository(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<QuizRepository>(
    () => QuizRepository(getIt<DioClient>()),
  );

  // Services
  getIt.registerLazySingleton<ImageDownloadService>(
    () => ImageDownloadService(),
  );

  // Cubits
  getIt.registerFactory<AuthCubit>(() => AuthCubit(getIt<AuthRepository>()));
  getIt.registerLazySingleton<BookCubit>(() => BookCubit());
  getIt.registerLazySingleton<HomeCubit>(
    () => HomeCubit(getIt<CollectionRepository>()),
  );
  getIt.registerFactory<BookContentCubit>(
    () => BookContentCubit(getIt<BookContentRepository>()),
  );
  getIt.registerLazySingleton<AudioCubit>(() => AudioCubit());
  getIt.registerLazySingleton<ImagesCubit>(() => ImagesCubit());
  getIt.registerLazySingleton<PdfCubit>(() => PdfCubit());
  getIt.registerFactory<QuizCubit>(() => QuizCubit(getIt<QuizRepository>()));
  getIt.registerLazySingleton<VideosCubit>(() => VideosCubit());
}
