import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'scaffold_messenger_manager.dart';

class MessageDi {
  MessageDi._();

  static final scaffoldMessengerManager = Provider(
    (ref) => ScaffoldMessengerManager(),
  );
}
