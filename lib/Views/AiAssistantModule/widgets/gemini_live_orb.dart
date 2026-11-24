import 'dart:math' as math;
import 'package:flutter/material.dart';

class GeminiLiveOrb extends StatefulWidget {
  final double size;
  final bool isListening;
  final bool isSpeaking;
  final VoidCallback? onTap;

  const GeminiLiveOrb({
    super.key,
    this.size = 180,
    this.isListening = true,
    this.isSpeaking = false,
    this.onTap,
  });

  @override
  State<GeminiLiveOrb> createState() => _GeminiLiveOrbState();
}

class _GeminiLiveOrbState extends State<GeminiLiveOrb>
    with TickerProviderStateMixin {
  late final AnimationController _waveCtrl;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_waveCtrl, _pulseCtrl]),
        builder: (context, child) {
          final pulse = widget.isListening
              ? 0.95 + (_pulseCtrl.value * 0.12)
              : (widget.isSpeaking ? 1.0 + (_pulseCtrl.value * 0.18) : 1.0);

          return Transform.scale(
            scale: pulse,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer soft halo glow
                  Container(
                    width: widget.size * 0.92,
                    height: widget.size * 0.92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4285F4).withValues(alpha: 0.45),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                        BoxShadow(
                          color: const Color(0xFF8AB4F8).withValues(alpha: 0.35),
                          blurRadius: 70,
                          spreadRadius: 18,
                        ),
                      ],
                    ),
                  ),

                  // The Gemini Orb Canvas
                  CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _GeminiOrbPainter(
                      progress: _waveCtrl.value,
                      isListening: widget.isListening,
                      isSpeaking: widget.isSpeaking,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GeminiOrbPainter extends CustomPainter {
  final double progress;
  final bool isListening;
  final bool isSpeaking;

  _GeminiOrbPainter({
    required this.progress,
    required this.isListening,
    required this.isSpeaking,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Clip to Circle
    final circlePath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.save();
    canvas.clipPath(circlePath);

    // 2. Base Radial Gradient (Vibrant Deep Blue -> Ethereal Azure)
    final baseShader = RadialGradient(
      center: const Alignment(-0.2, -0.3),
      radius: 1.0,
      colors: const [
        Color(0xFF6BA4F8), // Sky blue highlight
        Color(0xFF3367D6), // Mid royal blue
        Color(0xFF1A73E8), // Vibrant Google blue
        Color(0xFF1557B0), // Deep blue base
      ],
      stops: const [0.0, 0.4, 0.75, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    final basePaint = Paint()..shader = baseShader;
    canvas.drawCircle(center, radius, basePaint);

    // 3. Fluid Undulating White Wave & Fog Bands (Matching reference image)
    final time = progress * 2 * math.pi;

    // Layer 1: Bottom fluid misty wave
    final wavePath1 = Path();
    wavePath1.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 4) {
      final y = center.dy +
          math.sin(time + (x / size.width * 2 * math.pi)) * 14 +
          math.cos(time * 0.7 + (x / size.width * math.pi)) * 10;
      wavePath1.lineTo(x, y);
    }
    wavePath1.lineTo(size.width, size.height);
    wavePath1.close();

    final wavePaint1 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.55),
          const Color(0xFFAECBFA).withValues(alpha: 0.35),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawPath(wavePath1, wavePaint1);

    // Layer 2: Top rolling luminous wave crest (The white cloud ribbon from screenshot)
    final wavePath2 = Path();
    wavePath2.moveTo(0, 0);
    wavePath2.lineTo(0, center.dy * 0.7);
    for (double x = 0; x <= size.width; x += 4) {
      final y = (center.dy * 0.65) +
          math.sin(time * 1.3 + (x / size.width * 2.5 * math.pi)) * 18 +
          math.cos(time * 0.9 + (x / size.width * 1.5 * math.pi)) * 8;
      wavePath2.lineTo(x, y);
    }
    wavePath2.lineTo(size.width, 0);
    wavePath2.close();

    final wavePaint2 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Colors.white.withValues(alpha: 0.85),
          const Color(0xFFD2E3FC).withValues(alpha: 0.4),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawPath(wavePath2, wavePaint2);

    // Layer 3: Central ethereal cloud bloom
    final bloomPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          math.sin(time * 0.8) * 0.3,
          -0.2 + math.cos(time * 0.6) * 0.15,
        ),
        radius: 0.55,
        colors: [
          Colors.white.withValues(alpha: 0.9),
          Colors.white.withValues(alpha: 0.2),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.6))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(center, radius * 0.45, bloomPaint);

    canvas.restore();

    // 4. Subtle Outer Specular Edge Rim
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = SweepGradient(
        colors: [
          Colors.white.withValues(alpha: 0.6),
          Colors.white.withValues(alpha: 0.1),
          const Color(0xFF8AB4F8).withValues(alpha: 0.4),
          Colors.white.withValues(alpha: 0.6),
        ],
        transform: GradientRotation(progress * 2 * math.pi),
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius - 1, rimPaint);
  }

  @override
  bool shouldRepaint(covariant _GeminiOrbPainter oldDelegate) => true;
}
