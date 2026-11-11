import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qapp/l10n/app_lang.dart';
import 'package:qapp/theme/app_theme.dart';
import 'package:qapp/widgets/q_avatar.dart';

class QBottomBar extends StatelessWidget {
  const QBottomBar({
    super.key,
    required this.index,
    required this.onChanged,
    required this.onAdd,
    this.youName = '',
    this.youPhoto,
  });

  final int index;
  final ValueChanged<int> onChanged;
  final VoidCallback onAdd;
  final String youName;
  final Uint8List? youPhoto;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 96,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                left: 12,
                right: 12,
                bottom: 6,
                height: 68,
                child: CustomPaint(
                  painter: _NotchPainter(AppColors.bar),
                  child: const SizedBox.expand(),
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 10,
                height: 58,
                child: Row(
                  children: [
                    _tab(Icons.tips_and_updates_outlined, Icons.tips_and_updates_rounded, s.statusTitle, 0),
                    _tab(Icons.groups_outlined, Icons.groups_rounded, s.groups, 1),
                    const SizedBox(width: 68),
                    _tab(Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, s.chats, 2),
                    _you(s.you, 3),
                  ],
                ),
              ),
              Positioned(
                top: 2,
                child: GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.buttonGradient,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1FA37A).withValues(alpha: 0.45),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(IconData idle, IconData active, String label, int page) {
    final on = index == page;
    final color = on ? AppColors.accent : AppColors.inkSoft;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(page),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 180),
              scale: on ? 1.08 : 1,
              child: Icon(on ? active : idle, color: color, size: 24),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: on ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _you(String label, int page) {
    final on = index == page;
    final color = on ? AppColors.accent : AppColors.inkSoft;
    final name = youName.trim().isEmpty ? label : youName.trim();
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(page),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: on ? AppColors.accent : AppColors.line, width: 1.6),
              ),
              child: QAvatar(name: name, size: 24, bytes: youPhoto),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: on ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotchPainter extends CustomPainter {
  const _NotchPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = color;
    final w = size.width;
    final h = size.height;
    const corner = 26.0;
    final cx = w / 2;
    const notch = 36.0;
    const dip = 20.0;
    final path = Path()
      ..moveTo(0, corner)
      ..quadraticBezierTo(0, 0, corner, 0)
      ..lineTo(cx - notch - 16, 0)
      ..cubicTo(cx - notch, 0, cx - notch + 6, dip, cx, dip + 10)
      ..cubicTo(cx + notch - 6, dip, cx + notch, 0, cx + notch + 16, 0)
      ..lineTo(w - corner, 0)
      ..quadraticBezierTo(w, 0, w, corner)
      ..lineTo(w, h - corner)
      ..quadraticBezierTo(w, h, w - corner, h)
      ..lineTo(corner, h)
      ..quadraticBezierTo(0, h, 0, h - corner)
      ..close();
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.45), 10, true);
    canvas.drawPath(path, fill);
  }

  @override
  bool shouldRepaint(covariant _NotchPainter oldDelegate) => oldDelegate.color != color;
}
