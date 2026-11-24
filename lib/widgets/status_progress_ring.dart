import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A sleek, customizable circular progress / story ring inspired by modern neon UI.
/// - When [hasUnviewed] is true: draws a vivid multi-colored gradient ring (or segmented arc)
/// - When [hasUnviewed] is false: draws a muted sleek grey ring
/// - When [hasStatus] is false: renders the child without any ring
class StatusProgressRing extends StatelessWidget {
  const StatusProgressRing({
    super.key,
    required this.child,
    this.hasStatus = false,
    this.hasUnviewed = true,
    this.totalStatuses = 1,
    this.size,
    this.ringWidth = 2.6,
    this.padding = 3.0,
    this.onTap,
  });

  final Widget child;
  final bool hasStatus;
  final bool hasUnviewed;
  final int totalStatuses;
  final double? size;
  final double ringWidth;
  final double padding;
  final VoidCallback? onTap;

  // Vibrant neon gradient palette matching Image 1
  static const List<Color> unviewedGradient = [
    Color(0xFF00F2FE), // Electric Cyan
    Color(0xFF4FACFE), // Vivid Blue
    Color(0xFF9B51E0), // Neon Purple
    Color(0xFFFF2A6D), // Hot Pink
    Color(0xFFFF9F43), // Sunset Amber
    Color(0xFF00F2FE), // Complete cycle
  ];

  static const Color viewedColor = Color(0xFF6B7280); // Subtle dark grey

  @override
  Widget build(BuildContext context) {
    if (!hasStatus) {
      return GestureDetector(
        onTap: onTap,
        child: child,
      );
    }

    final effectiveCount = totalStatuses < 1 ? 1 : totalStatuses;

    Widget ringAvatar = CustomPaint(
      painter: _StatusRingPainter(
        hasUnviewed: hasUnviewed,
        totalSegments: effectiveCount,
        ringWidth: ringWidth,
        gradientColors: unviewedGradient,
        seenColor: viewedColor,
      ),
      child: Padding(
        padding: EdgeInsets.all(ringWidth + padding),
        child: child,
      ),
    );

    if (size != null) {
      ringAvatar = SizedBox(
        width: size,
        height: size,
        child: Center(child: ringAvatar),
      );
    }

    if (onTap != null) {
      ringAvatar = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ringAvatar,
      );
    }

    return ringAvatar;
  }
}

class _StatusRingPainter extends CustomPainter {
  const _StatusRingPainter({
    required this.hasUnviewed,
    required this.totalSegments,
    required this.ringWidth,
    required this.gradientColors,
    required this.seenColor,
  });

  final bool hasUnviewed;
  final int totalSegments;
  final double ringWidth;
  final List<Color> gradientColors;
  final Color seenColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - ringWidth) / 2;

    if (radius <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth
      ..strokeCap = totalSegments > 1 ? StrokeCap.round : StrokeCap.round;

    if (hasUnviewed) {
      paint.shader = SweepGradient(
        colors: gradientColors,
        startAngle: 0.0,
        endAngle: math.pi * 2,
      ).createShader(rect);
    } else {
      paint.color = seenColor;
    }

    if (totalSegments <= 1) {
      // Single continuous ring
      canvas.drawCircle(center, radius, paint);
    } else {
      // Segmented ring
      const gapAngle = 0.09; // gap in radians (~5 degrees)
      final totalGap = gapAngle * totalSegments;
      final sweepAngle = (2 * math.pi - totalGap) / totalSegments;

      var startAngle = -math.pi / 2; // Start from top

      for (int i = 0; i < totalSegments; i++) {
        canvas.drawArc(
          rect,
          startAngle,
          sweepAngle,
          false,
          paint,
        );
        startAngle += sweepAngle + gapAngle;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StatusRingPainter oldDelegate) {
    return oldDelegate.hasUnviewed != hasUnviewed ||
        oldDelegate.totalSegments != totalSegments ||
        oldDelegate.ringWidth != ringWidth ||
        oldDelegate.seenColor != seenColor;
  }
}
