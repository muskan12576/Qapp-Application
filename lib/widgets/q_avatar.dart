import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qapp/theme/app_theme.dart';

class QAvatar extends StatelessWidget {
  const QAvatar({
    super.key,
    required this.name,
    this.size = 48,
    this.colorIndex = 0,
    this.photo,
    this.bytes,
    this.online = false,
  });

  final String name;
  final double size;
  final int colorIndex;
  final String? photo;
  final Uint8List? bytes;
  final bool online;

  static const _colors = <List<Color>>[
    [Color(0xFF3DDC97), Color(0xFF0E6A58)],
    [Color(0xFF2BB5A0), Color(0xFF0C4C48)],
    [Color(0xFF7CFFB2), Color(0xFF14785E)],
    [Color(0xFF1AA6A0), Color(0xFF0A3C42)],
    [Color(0xFF5EEAD4), Color(0xFF115E56)],
  ];

  String get _initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return 'Q';
    }
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }
    return (parts[0].characters.first + parts[1].characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colors[colorIndex.abs() % _colors.length];
    final cache = (size * 3).clamp(64, 480).round();
    Widget face;
    if (bytes != null) {
      face = Image.memory(
        bytes!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: cache,
        gaplessPlayback: true,
        filterQuality: FilterQuality.low,
      );
    } else if (photo != null) {
      face = Image.asset(
        photo!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: cache,
        filterQuality: FilterQuality.low,
      );
    } else {
      face = Center(
        child: Text(
          _initials,
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.34,
          ),
        ),
      );
    }

    final dot = (size * 0.28).clamp(10.0, 16.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              border: Border.all(color: AppColors.ink.withValues(alpha: 0.16)),
            ),
            child: face,
          ),
          if (online)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: dot,
                height: dot,
                decoration: BoxDecoration(
                  color: const Color(0xFF3DDC97),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
