import 'package:flutter/material.dart';
import 'package:frontend_proj/core/message/message_di.dart';
import 'package:frontend_proj/core/navigation/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final scaffoldManager = ref.watch(MessageDi.scaffoldMessengerManager);

    return MaterialApp.router(
      scaffoldMessengerKey: scaffoldManager.scaffoldMessengerKey,

      title: 'Flutter Demo',
      routerConfig: router,
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      theme: ThemeData.light(),
    );
  }
}
