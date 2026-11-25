import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:qapp/Services/chat_socket_service.dart';
import 'package:qapp/Views/CallModule/group_call_screen.dart';
import 'package:qapp/Views/CallModule/video_call_screen.dart';
import 'package:qapp/Views/CallModule/voice_call_screen.dart';
import 'package:qapp/theme/app_theme.dart';
import 'package:qapp/theme/q_route.dart';
import 'package:qapp/widgets/q_avatar.dart';

class IncomingCallDialog extends StatefulWidget {
  final Map<String, dynamic> callData;

  const IncomingCallDialog({super.key, required this.callData});

  static Future<void> show(BuildContext context, Map<String, dynamic> callData) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => IncomingCallDialog(callData: callData),
    );
  }

  @override
  State<IncomingCallDialog> createState() => _IncomingCallDialogState();
}

class _IncomingCallDialogState extends State<IncomingCallDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  Timer? _vibrateTimer;
  StreamSubscription? _endSub;

  String get _callId => widget.callData['callId']?.toString() ?? '';
  String get _callerId => widget.callData['callerId']?.toString() ?? '';
  String get _callerName => widget.callData['callerName']?.toString() ?? 'Caller';
  String? get _callerPhoto => widget.callData['callerPhoto']?.toString();
  bool get _isVideo =>
      widget.callData['kind'] == 'video' || widget.callData['callType'] == 'video';
  String? get _roomId => widget.callData['roomId']?.toString();

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Play loud looping incoming ringtone
    try {
      FlutterRingtonePlayer().playRingtone(
        looping: true,
        volume: 1.0,
        asAlarm: true,
      );
    } catch (_) {}

    // Continuous ringing vibration feedback
    HapticFeedback.vibrate();
    _vibrateTimer = Timer.periodic(const Duration(milliseconds: 1600), (_) {
      HapticFeedback.vibrate();
    });

    // Auto-dismiss if caller cancels before answer
    _endSub = ChatSocketService.instance.onCallEnded.listen((data) {
      if (data['callId']?.toString() == _callId && mounted) {
        _stopRingTone();
        Navigator.of(context, rootNavigator: true).pop();
      }
    });
  }

  void _stopRingTone() {
    try {
      FlutterRingtonePlayer().stop();
    } catch (_) {}
  }

  @override
  void dispose() {
    _stopRingTone();
    _vibrateTimer?.cancel();
    _endSub?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _decline() {
    _stopRingTone();
    HapticFeedback.heavyImpact();
    ChatSocketService.instance.declineCall(
      callId: _callId,
      callerId: _callerId,
      roomId: _roomId,
    );
    Navigator.of(context, rootNavigator: true).pop();
  }

  bool get _isGroup => widget.callData['isGroup'] == true;
  String? get _token => widget.callData['token']?.toString();

  void _accept() {
    _stopRingTone();
    HapticFeedback.heavyImpact();
    ChatSocketService.instance.acceptCall(
      callId: _callId,
      callerId: _callerId,
      channelName: _roomId,
    );
    Navigator.of(context, rootNavigator: true).pop();

    if (_isGroup) {
      Navigator.of(context).push(
        qRoute(
          GroupCallScreen(
            groupName: _callerName,
            roomId: _roomId ?? _callId,
            isVideo: _isVideo,
            token: _token,
            isIncoming: true,
          ),
        ),
      );
    } else if (_isVideo) {
      Navigator.of(context).push(
        qRoute(
          VideoCallScreen(
            name: _callerName,
            photo: _callerPhoto,
            callId: _callId,
            roomId: _roomId,
            token: _token,
            recipientId: _callerId,
            isIncoming: true,
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        qRoute(
          VoiceCallScreen(
            name: _callerName,
            photo: _callerPhoto,
            callId: _callId,
            roomId: _roomId,
            token: _token,
            recipientId: _callerId,
            isIncoming: true,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Call Type Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                      color: AppColors.accent,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isVideo ? "Incoming Video Call" : "Incoming Voice Call",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Animated Glowing Avatar with Ringing Pulse
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (context, child) {
                  final scale = 1.0 + (_pulseCtrl.value * 0.12);
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 104 * scale,
                        height: 104 * scale,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent.withValues(alpha: 0.25 * (1 - _pulseCtrl.value)),
                        ),
                      ),
                      QAvatar(
                        name: _callerName,
                        photo: _callerPhoto,
                        colorIndex: 2,
                        size: 88,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // Caller Name
              Text(
                _callerName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Ringing...",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 36),

              // Action Buttons: Decline (Red) and Accept (Green)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Decline Button
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _decline,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x66EF4444),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.call_end_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Decline",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  // Accept Button
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _accept,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x6610B981),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Accept",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
