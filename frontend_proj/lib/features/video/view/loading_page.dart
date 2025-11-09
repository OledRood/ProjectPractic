import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_proj/core/auth/auth_di.dart';
import 'package:frontend_proj/core/navigation/app_routes.dart';
import 'package:frontend_proj/features/video/video_di.dart';
import 'package:go_router/go_router.dart';

class LoadingPage extends ConsumerWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(VideoDi.videoViewmodelProvider);

    // Добавляем отладочный вывод
    debugPrint(
      'LoadingPage: status=${state.status}, videoFromServerPath=${state.videoFromServerPath}',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loading Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) {
                context.go(AppRoutes.signInPage.path);
              }
            },
          ),
        ],
      ),
      body: Center(
        child: SizedBox(
          width: 400,
          child: const LinearProgressIndicator(
            minHeight: 8,
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
      ),
    );
  }
}
