import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qapp/theme/app_theme.dart';

class QField extends StatelessWidget {
  const QField({
    super.key,
    required this.controller,
    required this.hint,
    this.prefix,
    this.suffix,
    this.keyboardType,
    this.maxLines = 1,
    this.dense = false,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String hint;
  final Widget? prefix;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool dense;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textCapitalization: textCapitalization,
      textAlignVertical: TextAlignVertical.center,
      style: TextStyle(
        color: AppColors.ink,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      cursorColor: AppColors.accent,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.ink.withValues(alpha: 0.42),
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: AppColors.surface,
        prefixIcon: prefix,
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: suffix,
        isDense: dense,
        contentPadding: EdgeInsets.symmetric(
          horizontal: prefix == null ? 18 : 8,
          vertical: dense ? 14 : 18,
        ),
        border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppColors.accent, width: 1.2),
        ),
      ),
    );
  }
}
