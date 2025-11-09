enum AppRoutes {
  signUpPage('/signUpPage'),
  signInPage('/signInPage'),

  getVideoPage('/getVidoPage'),
  loadingPage('/loadingPage'),
  resultPage('/resultPage');

  final String path;

  const AppRoutes(this.path);
}
