import 'package:flutter/material.dart';

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

abstract final class AppColors {
  static bool get _dark => true;

  static const accent = Color(0xFF3DDC97);
  static const onAccent = Color(0xFF06221C);

  static Color get background => _dark ? const Color(0xFF0C1F26) : const Color(0xFFF3F6F5);
  static Color get surface => _dark ? const Color(0xFF155659) : const Color(0xFFFFFFFF);
  static Color get card => _dark ? const Color(0xFF102A32) : const Color(0xFFFFFFFF);
  static Color get field => _dark ? const Color(0xFF102A32) : const Color(0xFFE7EEEC);
  static Color get bar => _dark ? const Color(0xFF10262C) : const Color(0xFFFFFFFF);
  static Color get stage => _dark ? const Color(0xFF071418) : const Color(0xFFD5E3DF);
  static Color get ink => _dark ? const Color(0xFFFFFFFF) : const Color(0xFF10262C);
  static Color get inkSoft => _dark ? const Color(0xB3FFFFFF) : const Color(0xFF3C5550);
  static Color get faint => _dark ? const Color(0x8AFFFFFF) : const Color(0xFF5E7570);
  static Color get muted => _dark ? const Color(0xFFB7C9C6) : const Color(0xFF5E7570);
  static Color get line => _dark ? const Color(0x1FFFFFFF) : const Color(0x140C1F26);
  static Color get bubbleIn => _dark ? const Color(0xFF14343C) : const Color(0xFFFFFFFF);
  static Color get incoming => _dark ? const Color(0xFF155659) : const Color(0xFFFFFFFF);
  static Color get outgoing => _dark ? const Color(0xFF1A7A6C) : const Color(0xFFD7F6EE);

  static Color bubbleMine(Color theme) => _dark ? theme : const Color(0xFFD7F6EE);

  static const chatThemes = <Color>[
    Color(0xFF1A7A6C),
    Color(0xFF1C6B8A),
    Color(0xFF6A4C93),
    Color(0xFF8A5A2B),
  ];

  static const buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF3EE6B4), Color(0xFF149E86)],
  );
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
