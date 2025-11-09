import 'package:frontend_proj/core/navigation/app_routes.dart';
import 'package:frontend_proj/core/navigation/router_notifier.dart';
import 'package:frontend_proj/features/auth/sign_in/view/sign_in_view.dart';
import 'package:frontend_proj/features/auth/sign_up/view/sign_up_view.dart';
import 'package:frontend_proj/features/video/view/get_video_page.dart';
import 'package:frontend_proj/features/video/view/loading_page.dart';
import 'package:frontend_proj/features/video/view/result_page.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/riverpod.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    refreshListenable: notifier,
    initialLocation: AppRoutes.signInPage.path,

    // Redirect logic для защиты маршрутов
    redirect: (context, state) {
      final isAuthenticated = notifier.isAuthenticated;
      final isAuthRoute =
          state.matchedLocation == AppRoutes.signInPage.path ||
          state.matchedLocation == AppRoutes.signUpPage.path;

      // Если пользователь не авторизован и пытается попасть на защищенную страницу
      if (!isAuthenticated && !isAuthRoute) {
        return AppRoutes.signInPage.path;
      }

      // Если пользователь авторизован и находится на странице входа/регистрации
      if (isAuthenticated && isAuthRoute) {
        return AppRoutes.getVideoPage.path;
      }

      return null; // No redirect needed
    },

    routes: [
      // Публичные маршруты (вход/регистрация)
      GoRoute(
        path: AppRoutes.signInPage.path,
        name: AppRoutes.signInPage.name,
        builder: (context, state) => const SignInPage(),
      ),
      GoRoute(
        path: AppRoutes.signUpPage.path,
        name: AppRoutes.signUpPage.name,
        builder: (context, state) => const SignUpPage(),
      ),

      // Защищенные маршруты (требуют аутентификации)
      GoRoute(
        path: AppRoutes.getVideoPage.path,
        name: AppRoutes.getVideoPage.name,
        builder: (context, state) => const GetVideoPage(),
      ),
      GoRoute(
        path: AppRoutes.loadingPage.path,
        name: AppRoutes.loadingPage.name,
        builder: (context, state) => const LoadingPage(),
      ),
      GoRoute(
        path: AppRoutes.resultPage.path,
        name: AppRoutes.resultPage.name,
        builder: (context, state) => const ResultPage(),
      ),
    ],
  );
});
