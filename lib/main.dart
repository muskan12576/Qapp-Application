import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qapp/l10n/app_lang.dart';
import 'package:qapp/screens/welcome_screen.dart';
import 'package:qapp/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _paintBars();
  runApp(const Qapp());
  SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
}

void _paintBars() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF0C1F26),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
}

class Qapp extends StatelessWidget {
  const Qapp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLook.instance,
      builder: (context, _) {
        _paintBars();
        return MaterialApp(
          title: 'Qapp',
          debugShowCheckedModeBanner: false,
          theme: buildQappTheme(),
          builder: (context, child) {
            return LangScope(
              child: _AppDirection(
                child: _Stage(child: child ?? const SizedBox.shrink()),
              ),
            );
          },
          home: const WelcomeScreen(),
        );
      },
    );
  }
}

class _AppDirection extends StatelessWidget {
  const _AppDirection({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final rtl = AppLang.instance.rtl;
    LangScope.codeOf(context);
    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: child,
    );
  }
}

class _Stage extends StatelessWidget {
  const _Stage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth > 480 ? 480.0 : constraints.maxWidth;
        final media = MediaQuery.of(context);
        return ColoredBox(
          color: AppColors.stage,
          child: Center(
            child: MediaQuery(
              data: media.copyWith(size: Size(width, constraints.maxHeight)),
              child: SizedBox(
                width: width,
                height: constraints.maxHeight,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
