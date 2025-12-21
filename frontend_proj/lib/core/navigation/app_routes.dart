/// Маршруты приложения (MVP без авторизации)
enum AppRoutes {
  getVideoPage('/'),
  loadingPage('/loading'),
  resultPage('/result');

  final String path;

  const AppRoutes(this.path);
}
