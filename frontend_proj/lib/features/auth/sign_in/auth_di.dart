import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_proj/features/auth/sign_in/domain/sign_in_view_model.dart';
import 'package:frontend_proj/features/auth/sign_in/models/sign_in_model.dart';

class SignInDi {
  static final signInViewmodelProvider =
      NotifierProvider<SignInViewModel, SignInState>(SignInViewModel.new);
}
