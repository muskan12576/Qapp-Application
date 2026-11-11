import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qapp/l10n/app_lang.dart';
import 'package:qapp/theme/app_theme.dart';
import 'package:qapp/widgets/q_avatar.dart';

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({
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
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  static const _perm = MethodChannel('qapp/camera_perm');

  Timer? _ticker;
  int _seconds = 0;
  bool _muted = false;
  bool _cameraOn = true;
  bool _allowed = false;
  bool _failed = false;
  int? _viewId;

  bool get _android => defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _seconds++);
      }
    });
    _ask();
  }

  Future<void> _ask() async {
    if (!_android) {
      if (mounted) {
        setState(() => _failed = true);
      }
      return;
    }
    try {
      final granted = await _perm.invokeMethod<bool>('grant');
      if (!mounted) {
        return;
      }
      setState(() {
        _allowed = granted == true;
        _failed = granted != true;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _failed = true);
      }
    }
  }

  Future<void> _flip() async {
    final id = _viewId;
    if (id == null) {
      return;
    }
    try {
      await MethodChannel('qapp/camera_$id').invokeMethod<void>('flip');
    } catch (_) {}
  }

  @override
  void dispose() {
    _ticker?.cancel();
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
    final live = _android && _allowed && _cameraOn && !_failed;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (live)
            _AndroidCamera(onReady: (id) => _viewId = id)
          else
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0C1F26), Color(0xFF155659)],
                ),
              ),
            ),
          if (live)
            Positioned(
              left: 16,
              bottom: 108,
              child: _pip(true),
            ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(status, style: AppText.subtitle),
                          ],
                        ),
                      ),
                      Text(
                        _seconds == 0 ? s.calling : _clock,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                if (!live) ...[
                  const Spacer(),
                  QAvatar(
                    name: widget.name,
                    size: 110,
                    colorIndex: widget.colorIndex,
                    photo: widget.photo,
                  ),
                  const SizedBox(height: 10),
                  Text(_failed || !_cameraOn ? s.cameraHint : s.videoCall, style: AppText.subtitle),
                  const Spacer(),
                ] else
                  const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _btn(Icons.cameraswitch_rounded, _flip, on: false),
                      const SizedBox(width: 10),
                      _btn(
                        _muted ? Icons.mic_off_rounded : Icons.mic_none_rounded,
                        () => setState(() => _muted = !_muted),
                        on: _muted,
                      ),
                      const SizedBox(width: 10),
                      _btn(
                        _cameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                        () => setState(() => _cameraOn = !_cameraOn),
                        on: !_cameraOn,
                      ),
                      const SizedBox(width: 10),
                      Material(
                        color: const Color(0xFFE25B5B),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => Navigator.of(context).pop(),
                          child: const SizedBox(
                            width: 58,
                            height: 58,
                            child: Icon(Icons.call_end_rounded, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pip(bool live) {
    return Container(
      width: 92,
      height: 124,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      clipBehavior: Clip.antiAlias,
      child: live
          ? QAvatar(name: widget.name, size: 56, colorIndex: widget.colorIndex, photo: widget.photo)
          : const Icon(Icons.videocam_off_rounded, color: Colors.white70),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap, {required bool on}) {
    return Material(
      color: on ? const Color(0xFF1C8F7C) : AppColors.surface.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 52, height: 52, child: Icon(icon, color: Colors.white)),
      ),
    );
  }
}

class _AndroidCamera extends StatelessWidget {
  const _AndroidCamera({required this.onReady});

  final ValueChanged<int> onReady;

  @override
  Widget build(BuildContext context) {
    return PlatformViewLink(
      viewType: 'qapp/camera',
      surfaceFactory: (context, controller) {
        return AndroidViewSurface(
          controller: controller as AndroidViewController,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        );
      },
      onCreatePlatformView: (params) {
        final view = PlatformViewsService.initExpensiveAndroidView(
          id: params.id,
          viewType: 'qapp/camera',
          layoutDirection: Directionality.of(context),
          creationParams: null,
          creationParamsCodec: const StandardMessageCodec(),
          onFocus: () => params.onFocusChanged(true),
        );
        view
          ..addOnPlatformViewCreatedListener((id) {
            params.onPlatformViewCreated(id);
            onReady(id);
          })
          ..create();
        return view;
      },
    );
  }
}
