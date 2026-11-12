import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qapp/l10n/app_lang.dart';
import 'package:qapp/theme/app_theme.dart';
import 'package:qapp/widgets/q_avatar.dart';
import 'package:qapp/widgets/q_background.dart';

class VoiceCallScreen extends StatefulWidget {
  const VoiceCallScreen({
    super.key,
    required this.name,
    this.colorIndex = 1,
    this.status,
    this.photo,
  });

  final String name;
  final int colorIndex;
  final String? status;
  final String? photo;

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  Timer? _ticker;
  int _seconds = 0;
  bool _muted = false;
  bool _speaker = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _seconds++);
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  String get _clock {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final status = widget.status ?? s.callStatus(widget.name);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: QBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 32,
                    ),
                  ),
                ),
                Text(s.voiceCall, style: AppText.subtitle),
                const Spacer(),
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, child) {
                      final t = _pulse.value;
                      return SizedBox(
                        width: 220,
                        height: 220,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _ring(148 + t * 56, (1 - t) * 0.35),
                            _ring(120 + t * 30, 0.25),
                            child!,
                          ],
                        ),
                      );
                    },
                    child: QAvatar(
                      name: widget.name,
                      size: 112,
                      colorIndex: widget.colorIndex,
                      photo: widget.photo,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  widget.name,
                  textAlign: TextAlign.center,
                  style: AppText.title,
                ),
                const SizedBox(height: 6),
                Text(
                  status,
                  textAlign: TextAlign.center,
                  style: AppText.subtitle,
                ),
                const SizedBox(height: 8),
                Text(
                  _seconds == 0 ? s.calling : _clock,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _round(
                      icon: _muted
                          ? Icons.mic_off_rounded
                          : Icons.mic_none_rounded,
                      label: s.mute,
                      on: _muted,
                      onTap: () => setState(() => _muted = !_muted),
                    ),
                    _end(s.end),
                    _round(
                      icon: Icons.volume_up_rounded,
                      label: s.speaker,
                      on: _speaker,
                      onTap: () => setState(() => _speaker = !_speaker),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ring(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.accent.withValues(alpha: opacity),
          width: 2,
        ),
      ),
    );
  }

  Widget _round({
    required IconData icon,
    required String label,
    required bool on,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        Material(
          color: on ? const Color(0xFF1C8F7C) : AppColors.surface,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 64,
              height: 64,
              child: Icon(icon, color: AppColors.ink),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _end(String label) {
    return Column(
      children: [
        Material(
          color: const Color(0xFFE25B5B),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.of(context).pop(),
            child: SizedBox(
              width: 72,
              height: 72,
              child: Icon(
                Icons.call_end_rounded,
                color: AppColors.ink,
                size: 30,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    );
  }
}
