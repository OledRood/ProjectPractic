import 'package:frontend_proj/core/navigation/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_proj/core/navigation/app_routes.dart';
import 'package:riverpod/riverpod.dart';
import 'package:flutter/foundation.dart';

class AppNavigation {
  final GoRouter _router;

  AppNavigation(this._router);

  void goToGetVideo() {
    debugPrint(
      'Navigation: going to GetVideoPage (${AppRoutes.getVideoPage.path})',
    );
    _router.go(AppRoutes.getVideoPage.path);
  }

  void goToLoading() {
    debugPrint(
      'Navigation: going to LoadingPage (${AppRoutes.loadingPage.path})',
    );
    _router.go(AppRoutes.loadingPage.path);
  }

  void goToResult() {
    debugPrint(
      'Navigation: going to ResultPage (${AppRoutes.resultPage.path})',
    );
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
