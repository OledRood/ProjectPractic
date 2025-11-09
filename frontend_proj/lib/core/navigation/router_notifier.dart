import 'package:flutter/material.dart';
import 'package:frontend_proj/core/auth/auth_di.dart';
import 'package:riverpod/riverpod.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref ref;

  RouterNotifier(this.ref) {
    // Слушаем изменения состояния аутентификации
    ref.listen(authNotifierProvider, (previous, next) {
      notifyListeners();
    });
  }

  bool get isAuthenticated {
    return ref.read(authNotifierProvider.notifier).isAuthenticated;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>(
  (ref) => RouterNotifier(ref),
);
