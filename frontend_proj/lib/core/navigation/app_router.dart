import 'package:frontend_proj/core/navigation/app_routes.dart';
import 'package:frontend_proj/core/navigation/router_notifier.dart';
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
    initialLocation: AppRoutes.signUpPage.path,
    routes: [
      GoRoute(
        path: AppRoutes.signUpPage.path,
        name: AppRoutes.signUpPage.name,
        builder: (context, state) {
          return SignUpPage();
        },
      ),
      GoRoute(
        path: AppRoutes.getVideoPage.path,
        name: AppRoutes.getVideoPage.name,
        builder: (context, state) {
          return GetVideoPage();
        },
      ),
      GoRoute(
        path: AppRoutes.loadingPage.path,
        name: AppRoutes.loadingPage.name,
        builder: (context, state) {
          return LoadingPage();
        },
      ),
      GoRoute(
        path: AppRoutes.resultPage.path,
        name: AppRoutes.resultPage.name,
        builder: (context, state) {
          return ResultPage();
        },
      ),
    ],
  );
});
