import 'package:flutter/material.dart';
import 'package:qapp/theme/app_theme.dart';

class QBackground extends StatelessWidget {
  const QBackground({
    super.key,
    required this.child,
    this.login = false,
    this.watermark = false,
  });

  final Widget child;
  final bool login;
  final bool watermark;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: login ? null : AppColors.background,
        gradient: login
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0C1F26),
                  Color(0xFF0C1F26),
                  Color(0xFF10343A),
                  Color(0xFF155659),
                ],
                stops: [0, 0.4, 0.72, 1],
              )
            : null,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (login || watermark) const Positioned.fill(child: _HalfMarks()),
          child,
        ],
      ),
    );
  }
}

class _HalfMarks extends StatelessWidget {
  const _HalfMarks();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Stack(
        children: [
          Positioned(top: -130, right: -80, child: _Blob(size: 280, alpha: 0.14)),
          Positioned(bottom: -90, left: -120, child: _Blob(size: 240, alpha: 0.10)),
          Positioned(top: 210, left: -60, child: _Blob(size: 150, alpha: 0.08)),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.alpha});

  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFB8F5D8).withValues(alpha: alpha),
      ),
    );
  }
}
