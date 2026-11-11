import 'package:flutter/material.dart';
import 'package:qapp/data/demo_data.dart';
import 'package:qapp/theme/app_theme.dart';

class TickMark extends StatelessWidget {
  const TickMark(this.tick, {super.key, this.size = 16});

  final Tick tick;
  final double size;

  @override
  Widget build(BuildContext context) {
    final read = tick == Tick.read;
    return Icon(
      tick == Tick.sent ? Icons.check_rounded : Icons.done_all_rounded,
      size: size,
      color: read ? AppColors.accent : AppColors.inkSoft,
    );
  }
}
