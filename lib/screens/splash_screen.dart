import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:qapp/screens/welcome_screen.dart';
import 'package:qapp/theme/app_theme.dart';
import 'package:qapp/widgets/q_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _controller.addStatusListener(_onStatus);
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      Future<void>.delayed(const Duration(milliseconds: 80), _go);
    }
  }

  void _go() {
    if (!mounted || _left) {
      return;
    }
    _left = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) => const WelcomeScreen(),
        transitionDuration: const Duration(milliseconds: 140),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: QBackground(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _go,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final logoW = (constraints.maxWidth * 0.42).clamp(132.0, 176.0);
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final t = _controller.value;
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _AssemblingLogo(progress: t, width: logoW),
                          const SizedBox(height: 18),
                          _wordmark(t),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _wordmark(double t) {
    const word = 'Qapp';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(word.length, (i) {
        final local = _span(
          t,
          0.58 + i * 0.06,
          0.74 + i * 0.06,
          Curves.easeOutCubic,
        ).clamp(0.0, 1.0);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Opacity(
            opacity: local,
            child: Transform.translate(
              offset: Offset(0, (1 - local) * 18),
              child: Text(
                word[i],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _AssemblingLogo extends StatelessWidget {
  const _AssemblingLogo({required this.progress, required this.width});

  final double progress;
  final double width;

  @override
  Widget build(BuildContext context) {
    final height = width * 380 / 600;
    final draw = _span(progress, 0.0, 0.46);
    final logoIn = _span(progress, 0.38, 0.62, Curves.easeOutCubic).clamp(0.0, 1.0);
    final scaleT = _span(progress, 0.38, 0.66, Curves.easeOutBack);
    final scale = 0.84 + 0.16 * scaleT;
    final lineFade = (1 - _span(progress, 0.46, 0.64)).clamp(0.0, 1.0);
    final glow = (0.22 + 0.18 * math.sin(progress * math.pi * 2)).clamp(0.12, 0.5);
    final shine = _span(progress, 0.55, 0.78);

    final image = Image.asset(
      'assets/images/qapp_mark.png',
      width: width,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
    );

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: width * 0.92,
            height: width * 0.92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF1E9E86).withValues(alpha: glow),
                  const Color(0xFF155659).withValues(alpha: 0),
                ],
              ),
            ),
          ),
          Opacity(
            opacity: lineFade,
            child: CustomPaint(
              size: Size(width, height),
              painter: _MarkPainter(progress: draw),
            ),
          ),
          Opacity(
            opacity: logoIn,
            child: Transform.scale(
              scale: scale,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Hero(tag: 'qapp-mark', child: image),
                  if (shine > 0.02 && shine < 0.98)
                    IgnorePointer(
                      child: ShaderMask(
                        blendMode: BlendMode.dstIn,
                        shaderCallback: (rect) {
                          final x = -0.9 + shine * 2.6;
                          return LinearGradient(
                            begin: Alignment(x, -1),
                            end: Alignment(x + 0.4, 1),
                            colors: const [
                              Colors.transparent,
                              Colors.white,
                              Colors.transparent,
                            ],
                          ).createShader(rect);
                        },
                        child: ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                          child: Image.asset(
                            'assets/images/qapp_mark.png',
                            width: width,
                            height: height,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final eye = Offset(w * 0.34, h * 0.50);
    final right = Offset(w * 0.66, h * 0.46);
    final radius = w * 0.16;
    final mid = Offset((eye.dx + right.dx) / 2, (eye.dy + right.dy) / 2);
    canvas.save();
    canvas.translate(w / 2 - mid.dx, h / 2 - mid.dy);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.058
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF8DFFC0), Color(0xFF14A88A), Color(0xFF0C6E62)],
      ).createShader(Offset.zero & size);

    final leftT = _span(progress, 0.0, 0.55);
    if (leftT > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: eye, radius: radius),
        -math.pi / 2,
        math.pi * 2 * leftT,
        false,
        stroke,
      );
    }

    final eyeIn = _span(progress, 0.26, 0.46, Curves.easeOutBack).clamp(0.0, 1.08);
    if (eyeIn > 0) {
      var blink = 1.0;
      if (progress > 0.48 && progress < 0.60) {
        final b = (progress - 0.48) / 0.12;
        blink = b < 0.5 ? 1 - b * 2 : (b - 0.5) * 2;
      }
      canvas.save();
      canvas.translate(eye.dx, eye.dy);
      canvas.scale(eyeIn.clamp(0.0, 1.05), (eyeIn * blink).clamp(0.04, 1.05));
      canvas.drawCircle(
        Offset.zero,
        radius * 0.46,
        Paint()..color = const Color(0xFF08343A),
      );
      canvas.drawCircle(
        Offset.zero,
        radius * 0.32,
        Paint()..color = const Color(0xFF1DBF8A),
      );
      final blade = Paint()
        ..color = const Color(0xFFB8FFE0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.012
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 6; i++) {
        canvas.save();
        canvas.rotate(i * math.pi / 3 + progress * math.pi);
        canvas.drawLine(
          Offset(radius * 0.08, 0),
          Offset(radius * 0.28, 0),
          blade,
        );
        canvas.restore();
      }
      canvas.drawCircle(
        Offset.zero,
        radius * 0.12,
        Paint()..color = const Color(0xFF062428),
      );
      canvas.drawCircle(
        Offset(-radius * 0.05, -radius * 0.05),
        radius * 0.035,
        Paint()..color = Colors.white,
      );
      canvas.restore();
    }

    final rightT = _span(progress, 0.0, 0.55);
    if (rightT > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: right, radius: radius * 0.98),
        math.pi * 0.75,
        math.pi * 1.75 * rightT,
        false,
        stroke,
      );
    }

    final tailT = _span(progress, 0.62, 0.95);
    if (tailT > 0) {
      _drawTrimmed(
        canvas,
        Path()
          ..moveTo(eye.dx + radius * 0.45, eye.dy + radius * 0.82)
          ..quadraticBezierTo(w * 0.46, h * 0.98, w * 0.52, h * 0.70),
        tailT,
        stroke,
      );
      _drawTrimmed(
        canvas,
        Path()
          ..moveTo(right.dx - radius * 0.15, right.dy + radius * 0.9)
          ..quadraticBezierTo(
            right.dx + radius * 0.2,
            h * 0.98,
            right.dx + radius * 0.05,
            h * 0.72,
          ),
        tailT,
        stroke,
      );
    }

    canvas.restore();
    final ripple = _span(progress, 0.0, 0.34, Curves.easeOut);
    if (ripple > 0 && ripple < 1) {
      canvas.drawCircle(
        Offset(w * 0.5, h * 0.48),
        radius * 0.4 + ripple * w * 0.34,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFF3DDC97).withValues(alpha: (1 - ripple) * 0.55),
      );
    }
  }

  void _drawTrimmed(Canvas canvas, Path path, double t, Paint paint) {
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * t), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

double _span(double t, double start, double end, [Curve curve = Curves.linear]) {
  if (t <= start) {
    return 0;
  }
  if (t >= end) {
    return 1;
  }
  return curve.transform((t - start) / (end - start));
}
