import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_proj/features/video/video_di.dart';

class ResultPage extends ConsumerWidget {
  const ResultPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(VideoDi.videoViewmodelProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text('Result Page')),
      body: Center(
        child: FilledButton(
          onPressed: () => vm.onRestartVideoSendButtonTap(),
          child: Text("Загрузить еще видео"),
        ),
      ),
    );
  }
}
