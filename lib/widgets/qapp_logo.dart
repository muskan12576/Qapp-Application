import 'package:flutter/material.dart';
import 'package:qapp/theme/app_theme.dart';

class QappLogo extends StatelessWidget {
  const QappLogo({super.key, required this.width, this.hero = false});

  final double width;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/images/qapp_mark.png',
      width: width,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.all_inclusive_rounded,
          size: width * 0.42,
          color: AppColors.accent,
        );
      },
    );
    if (!hero) {
      return image;
    }
    return Hero(tag: 'qapp-mark', child: image);
  }
}
