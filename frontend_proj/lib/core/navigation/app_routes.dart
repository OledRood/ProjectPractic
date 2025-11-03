import 'package:frontend_proj/features/video/view/get_video_page.dart';
import 'package:go_router/go_router.dart';

enum AppRoutes {
  getVideoPage('/getVidoPage'),
  loadingPage('/loadingPage'),
  resultPage('/resultPage');

  final String path;

  const AppRoutes(this.path);
}
