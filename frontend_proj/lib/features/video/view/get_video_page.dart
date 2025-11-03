import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_proj/features/video/video_di.dart';

class GetVideoPage extends ConsumerWidget {
  const GetVideoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(VideoDi.videoViewmodelProvider.notifier);
    final state = ref.watch(VideoDi.videoViewmodelProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Get Video Page')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (state.errorMessage != null)
              Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  state.errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FilledButton(
                  onPressed: () => vm.onUploadVideoTap("asdfsadf"),
                  child: Text("Upload Video"),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: () => vm.onSendButtonTap(),
                  child: Text("Send Video"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
