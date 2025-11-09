import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_proj/features/auth/sign_up/domain/sign_up_view_model.dart';
import 'package:frontend_proj/features/auth/sign_up/models/sign_up_model.dart';

class AuthDi {
  static final signUpViewmodelProvider =
      NotifierProvider<SignUpViewModel, SignUpState>(SignUpViewModel.new);
}
