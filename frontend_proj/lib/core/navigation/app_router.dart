import 'package:frontend_proj/core/navigation/app_routes.dart';
import 'package:frontend_proj/features/video/view/get_video_page.dart';
import 'package:frontend_proj/features/video/view/loading_page.dart';
import 'package:frontend_proj/features/video/view/result_page.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/riverpod.dart';

/// MVP роутер без авторизации
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.getVideoPage.path,
    routes: [
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
