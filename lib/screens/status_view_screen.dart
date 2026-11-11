import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qapp/l10n/app_lang.dart';
import 'package:qapp/theme/app_theme.dart';
import 'package:qapp/widgets/q_avatar.dart';

class StatusViewScreen extends StatefulWidget {
  const StatusViewScreen({
    super.key,
    required this.name,
    required this.caption,
    this.colorIndex = 1,
    this.bytes,
  });

  final String name;
  final String caption;
  final int colorIndex;
  final Uint8List? bytes;

  @override
  State<StatusViewScreen> createState() => _StatusViewScreenState();
}

class _StatusViewScreenState extends State<StatusViewScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _play;

  @override
  void initState() {
    super.initState();
    _play = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..forward();
    _play.addStatusListener(_onDone);
  }

  void _onDone(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _play.removeStatusListener(_onDone);
    _play.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_play.isAnimating) {
      _play.stop();
    } else {
      _play.forward();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggle,
        child: Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _play,
                builder: (context, child) {
                  final t = _play.value;
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-1.1 + t * 1.6, -1),
                        end: Alignment(1, 0.2 + t),
                        colors: const [
                          Color(0xFF071418),
                          Color(0xFF0C1F26),
                          Color(0xFF155659),
                          Color(0xFF1C8F7C),
                        ],
                      ),
                    ),
                    child: child,
                  );
                },
                child: const SizedBox.expand(),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _play,
                      builder: (context, _) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _play.value,
                            minHeight: 3,
                            backgroundColor: Colors.white24,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        QAvatar(
                          name: widget.name,
                          size: 40,
                          colorIndex: widget.colorIndex,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              Text(s.statusPlay, style: AppText.subtitle),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (widget.bytes != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.memory(
                          widget.bytes!,
                          height: 280,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      QAvatar(
                        name: widget.name,
                        size: 120,
                        colorIndex: widget.colorIndex,
                      ),
                    const SizedBox(height: 18),
                    Text(
                      widget.caption,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Icon(
                      _play.isAnimating
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_fill_rounded,
                      color: Colors.white70,
                      size: 42,
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
