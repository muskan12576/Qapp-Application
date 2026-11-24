import 'package:flutter/material.dart';
import 'package:qapp/Utills/app_colors.dart';
export 'package:qapp/Utills/app_colors.dart';

class AppLook extends ChangeNotifier {
  AppLook._();

  static final AppLook instance = AppLook._();

  bool dark = true;

  void useDark(bool value) {
    if (value == dark) {
      return;
    }
    dark = value;
    notifyListeners();
  }
}

abstract final class AppText {
  static TextStyle get title => TextStyle(
        color: AppColors.ink,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        height: 1.15,
        letterSpacing: -0.4,
      );

  static TextStyle get subtitle => const TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
        height: 1.35,
      ).copyWith(color: AppColors.muted);

  static const button = TextStyle(
    color: Colors.white,
    fontSize: 16.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );
}

ThemeData buildQappTheme() {
  final dark = AppLook.instance.dark;
  final scheme = ColorScheme(
    brightness: dark ? Brightness.dark : Brightness.light,
    primary: AppColors.accent,
    onPrimary: AppColors.onAccent,
    secondary: AppColors.accent,
    onSecondary: AppColors.onAccent,
    surface: AppColors.card,
    onSurface: AppColors.ink,
    error: const Color(0xFFE15D5D),
    onError: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: scheme.brightness,
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.background,
    colorScheme: scheme,
    splashColor: AppColors.line,
    highlightColor: AppColors.line,
    iconTheme: IconThemeData(color: AppColors.ink),
    dividerColor: AppColors.line,
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.card,
      textStyle: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: DialogThemeData(backgroundColor: AppColors.card),
    listTileTheme: ListTileThemeData(
      tileColor: AppColors.card,
      textColor: AppColors.ink,
      iconColor: AppColors.ink,
      selectedTileColor: AppColors.surface,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.accent,
      selectionColor: AppColors.accent.withValues(alpha: 0.28),
      selectionHandleColor: AppColors.accent,
    ),
  );
}
