import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:qapp/Services/chat_socket_service.dart';
import 'package:qapp/Services/zego_calling_service.dart';
import 'package:qapp/Utills/token_storage.dart';
import 'package:qapp/Views/CallModule/model/call_vm.dart';
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
    this.recipientId,
    this.chatId,
    this.callId,
    this.roomId,
    this.token,
    this.isIncoming = false,
  });

  final String name;
  final int colorIndex;
  final String? status;
  final String? photo;
  final String? recipientId;
  final String? chatId;
  final String? callId;
  final String? roomId;
  final String? token;
  final bool isIncoming;

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
  bool _isConnected = false;
  String? _callStatus;
  String? _activeCallId;
  String? _activeRoomId;
  Timer? _ringTimeoutTimer;
  StreamSubscription? _remoteSub;

  StreamSubscription? _declineSub;
  StreamSubscription? _endedSub;
  StreamSubscription? _busySub;
  StreamSubscription? _acceptedSub;

  @override
  void initState() {
    super.initState();
    _activeCallId = widget.callId;
    _activeRoomId = widget.roomId;
    _callStatus = widget.isIncoming ? "Connecting..." : "Calling...";

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    if (!widget.isIncoming) {
      _playRingingTone();
      _startRingTimeout();
    } else {
      _startTimer();
    }

    _listenSockets();
    _initZegoVoiceCall();
  }

  void _startRingTimeout() {
    _ringTimeoutTimer?.cancel();
    // 8 rings * 3.0 seconds cadence = 24 seconds
    _ringTimeoutTimer = Timer(const Duration(seconds: 24), () {
      if (!mounted || _isConnected) return;
      _stopRingingTone();
      setState(() => _callStatus = "No Answer");
      HapticFeedback.mediumImpact();
      _endCall();
    });
  }

  Future<void> _initZegoVoiceCall() async {
    final hasPerm = await ZegoCallingService.instance.requestPermissions(isVideo: false);
    if (!hasPerm) {
      if (mounted) setState(() => _callStatus = "Microphone Permission Required");
      return;
    }

    await TokenStorage.instance.load();
    final myUserId = TokenStorage.instance.userId.isNotEmpty
        ? TokenStorage.instance.userId
        : 'user_${DateTime.now().millisecondsSinceEpoch}';
    final myUserName = TokenStorage.instance.name.isNotEmpty
        ? TokenStorage.instance.name
        : 'User';

    String? token = widget.token;
    String? roomId = widget.roomId;

    if (!widget.isIncoming && widget.recipientId != null) {
      try {
        final res = await CallViewModel.instance.initiateVoiceCall(
          recipientId: widget.recipientId!,
          chatId: widget.chatId,
        );
        if (res != null) {
          _activeCallId = res['callId']?.toString() ?? _activeCallId;
          roomId = res['roomId']?.toString();
          token = res['token']?.toString();
          _activeRoomId = roomId;
        }
      } catch (e) {
        debugPrint('⚠️ [VoiceCall] initiateVoiceCall error: $e');
      }
    } else if (widget.isIncoming && roomId != null && (token == null || token.isEmpty)) {
      final res = await CallViewModel.instance.getVoiceToken(roomId);
      if (res != null) {
        token = res['token']?.toString();
      }
    }

    if (roomId == null || roomId.isEmpty) {
      roomId = 'voice_${widget.chatId ?? widget.recipientId ?? DateTime.now().millisecondsSinceEpoch}';
      _activeRoomId = roomId;
    }

    final initialized = await ZegoCallingService.instance.initializeEngine(isVideo: false);
    if (!initialized) {
      if (mounted) setState(() => _callStatus = "Audio Engine Init Failed");
      return;
    }

    final loggedIn = await ZegoCallingService.instance.loginRoom(
      roomId: roomId,
      userId: myUserId,
      userName: myUserName,
      token: token,
      isVideo: false,
    );
    if (!loggedIn) {
      if (mounted) setState(() => _callStatus = "Room Join Failed");
      return;
    }

    // Default to earpiece for private voice calls, speakerphone false
    await ZegoCallingService.instance.setSpeakerphone(false);

    _remoteSub = ZegoCallingService.instance.onRemoteStreamsChanged.listen((streams) {
      if (!mounted) return;
      if (streams.isNotEmpty) {
        _stopRingingTone();
        _ringTimeoutTimer?.cancel();
        for (final streamId in streams) {
          ZegoCallingService.instance.startPlayingAudioStream(streamId);
        }
        setState(() {
          _isConnected = true;
          _callStatus = "Connected";
        });
        _startTimer();
      } else if (streams.isEmpty && _isConnected) {
        _stopRingingTone();
        setState(() => _callStatus = "Call Ended");
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) _leaveAndPop();
        });
      }
    });
  }

  Future<void> _toggleMute() async {
    HapticFeedback.selectionClick();
    final next = !_muted;
    await ZegoCallingService.instance.setMicrophoneMute(next);
    if (mounted) setState(() => _muted = next);
  }

  Future<void> _toggleSpeaker() async {
    HapticFeedback.selectionClick();
    final next = !_speaker;
    await ZegoCallingService.instance.setSpeakerphone(next);
    if (mounted) setState(() => _speaker = next);
  }

  Future<void> _leaveAndPop() async {
    _stopRingingTone();
    _ringTimeoutTimer?.cancel();
    _ticker?.cancel();
    if (_activeRoomId != null) {
      await ZegoCallingService.instance.leaveRoomAndDestroy(_activeRoomId!);
    }
    if (mounted) Navigator.of(context).maybePop();
  }

  void _endCall() {
    _stopRingingTone();
    _ringTimeoutTimer?.cancel();
    HapticFeedback.heavyImpact();
    if (_activeCallId != null) {
      CallViewModel.instance.endVoiceCall(
        callId: _activeCallId!,
        durationSec: _seconds,
      );
      ChatSocketService.instance.endCall(
        callId: _activeCallId!,
        recipientId: widget.recipientId,
        roomId: _activeRoomId,
      );
    }
    _leaveAndPop();
  }

  void _playRingingTone() {
    try {
      FlutterRingtonePlayer().play(
        fromAsset: 'assets/sounds/telephone_ringback.wav',
        ios: IosSounds.electronic,
        looping: true,
        volume: 1.0,
        asAlarm: true,
      );
    } catch (_) {}
  }

  void _stopRingingTone() {
    try {
      FlutterRingtonePlayer().stop();
    } catch (_) {}
  }

  void _listenSockets() {
    _declineSub = ChatSocketService.instance.onCallDeclined.listen((_) {
      if (mounted) {
        _stopRingingTone();
        setState(() => _callStatus = "Call Declined");
        HapticFeedback.mediumImpact();
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    });

    _endedSub = ChatSocketService.instance.onCallEnded.listen((_) {
      if (mounted) {
        _stopRingingTone();
        setState(() => _callStatus = "Call Ended");
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    });

    _busySub = ChatSocketService.instance.onCallBusy.listen((_) {
      if (mounted) {
        _stopRingingTone();
        setState(() => _callStatus = "User Busy");
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    });

    _acceptedSub = ChatSocketService.instance.onCallAccepted.listen((_) {
      if (mounted) {
        _stopRingingTone();
        setState(() {
          _isConnected = true;
          _callStatus = "Connected";
        });
        _startTimer();
      }
    });
  }

  void _startTimer() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _seconds++);
      }
    });
  }

  @override
  void dispose() {
    _stopRingingTone();
    _ringTimeoutTimer?.cancel();
    _remoteSub?.cancel();
    _declineSub?.cancel();
    _endedSub?.cancel();
    _busySub?.cancel();
    _acceptedSub?.cancel();
    _ticker?.cancel();
    if (_activeRoomId != null) {
      ZegoCallingService.instance.leaveRoomAndDestroy(_activeRoomId!);
    }
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
                    onPressed: _endCall,
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
                  _callStatus ?? status,
                  textAlign: TextAlign.center,
                  style: AppText.subtitle,
                ),
                const SizedBox(height: 8),
                Text(
                  _isConnected ? _clock : (_callStatus ?? s.calling),
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
                      onTap: _toggleMute,
                    ),
                    _end(s.end),
                    _round(
                      icon: _speaker
                          ? Icons.volume_up_rounded
                          : Icons.volume_down_rounded,
                      label: s.speaker,
                      on: _speaker,
                      onTap: _toggleSpeaker,
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
        Text(label, style: TextStyle(color: AppColors.muted, fontSize: 12)),
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
            onTap: _endCall,
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
        Text(label, style: TextStyle(color: AppColors.muted, fontSize: 12)),
      ],
    );
  }
}
