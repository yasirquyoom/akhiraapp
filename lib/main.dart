import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'constants/app_constants.dart';
import 'core/di/service_locator.dart';
import 'core/language/language_manager.dart';
import 'data/cubits/audio/audio_cubit.dart';
import 'data/cubits/images/images_cubit.dart';
import 'data/cubits/quiz/quiz_cubit.dart';
import 'data/cubits/videos/videos_cubit.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupServiceLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, child) {
        final appRouter = getIt<AppRouter>().router;
        final languageManager = getIt<LanguageManager>();

        return AnimatedBuilder(
          animation: languageManager,
          builder: (context, child) {
            return MultiBlocProvider(
              providers: [
                BlocProvider<AudioCubit>(
                  create: (context) => getIt<AudioCubit>(),
                ),
                BlocProvider<ImagesCubit>(
                  create: (context) => getIt<ImagesCubit>(),
                ),
                BlocProvider<QuizCubit>(
                  create: (context) => getIt<QuizCubit>(),
                ),
                BlocProvider<VideosCubit>(
                  create: (context) => getIt<VideosCubit>(),
                ),
              ],
              child: MaterialApp.router(
                debugShowCheckedModeBanner: false,
                title: AppConstants.appName,
                theme: AppTheme.light(),
                routerConfig: appRouter,
                locale: languageManager.getLocale(),
                supportedLocales: const [Locale('en'), Locale('fr')],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
              ),
            );
          },
        );
      },
    );
  }
}
