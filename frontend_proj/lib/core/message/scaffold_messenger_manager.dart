import 'package:flutter/material.dart';

class ScaffoldMessengerManager {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  void showSnackBar(String message) {
    final snackBar = SnackBar(content: Text(message));
    scaffoldMessengerKey.currentState?.showSnackBar(snackBar);
  }

  void showErrorSnackBar(String message) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: ThemeData.light().textTheme.bodyMedium?.copyWith(
          color: Colors.white,
        ),
      ),
      backgroundColor: ThemeData.light().colorScheme.error,
    );
    scaffoldMessengerKey.currentState?.showSnackBar(snackBar);
  }

  void hideCurrentSnackBar() {
    scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
  }
}
