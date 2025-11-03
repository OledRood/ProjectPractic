import 'package:frontend_proj/core/navigation/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_proj/core/navigation/app_routes.dart';
import 'package:riverpod/riverpod.dart';

class AppNavigation {
  final GoRouter _router;

  AppNavigation(this._router);

  void goToGetVideo() {
    _router.go(AppRoutes.getVideoPage.path);
  }

  void goToLoading() {
    _router.go(AppRoutes.loadingPage.path);
  }

  void goToResult() {
    _router.go(AppRoutes.resultPage.path);
  }

  void goBack() {
    if (_router.canPop()) {
      _router.pop();
    }
  }
}

/// Провайдер AppNavigation
final appNavigationProvider = Provider<AppNavigation>((ref) {
  final router = ref.watch(routerProvider);
  return AppNavigation(router);
});
