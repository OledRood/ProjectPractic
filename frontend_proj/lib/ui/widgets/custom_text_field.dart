import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final List<TextInputFormatter>? inputFormatters;
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final IconData? icon;
  final VoidCallback? onIconPressed;
  final int? maxLines;
  final FocusNode? focusNode;
  final void Function(String)? onChanged;
  final IconData? prefIcon;
  final void Function(String)? onSubmitted;
  final bool isLoading;

  final String? errorText;
  final IconData? suffixIcon;

  const CustomTextField({
    super.key,
    required this.label,
    this.inputFormatters,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.icon,
    this.maxLines = 1,
    this.onIconPressed,
    this.prefIcon,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    required this.isLoading,
    this.errorText,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        TextFormField(
          inputFormatters: inputFormatters,
          controller: controller,
          validator: validator,
          enabled: !isLoading,
          onChanged: onChanged,
          focusNode: focusNode,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          onFieldSubmitted: onSubmitted,

          // style: Theme.of(context).textTheme.bodySmall,
          decoration: InputDecoration(
            filled: true,
            hintText: hint,
            errorText: errorText,

            prefixIcon: _TextFieldIconWidget(
              icon: prefIcon,
              onIconPressed: onIconPressed,
            ),
            prefixIconConstraints: BoxConstraints(minWidth: 20, minHeight: 20),
            suffixIcon: _TextFieldIconWidget(
              icon: suffixIcon,
              onIconPressed: onIconPressed,
            ),
            errorStyle: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _TextFieldIconWidget extends StatelessWidget {
  final dynamic icon;
  final VoidCallback? onIconPressed;
  const _TextFieldIconWidget({
    super.key,
    required this.onIconPressed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return GestureDetector(onTap: onIconPressed, child: Icon(icon, size: 20));
    }
    return SizedBox.shrink();
  }
}
