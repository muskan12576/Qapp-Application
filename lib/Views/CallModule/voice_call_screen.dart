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
  String? _activeCallId;
  String? _activeRoomId;
  String? _callStatus;

  StreamSubscription? _remoteSub;
  StreamSubscription? _declineSub;
  StreamSubscription? _endedSub;
  StreamSubscription? _busySub;

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

    _listenSockets();
    _initZegoVoiceCall();
  }

  void _playRingingTone() {
    try {
      FlutterRingtonePlayer().play(
        android: AndroidSounds.ringtone,
        ios: IosSounds.electronic,
        looping: true,
        volume: 0.8,
      );
    } catch (_) {}
  }

  void _stopRingingTone() {
    try {
      FlutterRingtonePlayer().stop();
    } catch (_) {}
  }

  void _listenSockets() {
    _declineSub = ChatSocketService.instance.onCallDeclined.listen((data) {
      if (mounted) {
        _stopRingingTone();
        setState(() => _callStatus = "Call Declined");
        HapticFeedback.mediumImpact();
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (mounted) _leaveAndPop();
        });
      }
    });

    _endedSub = ChatSocketService.instance.onCallEnded.listen((data) {
      if (mounted) {
        _stopRingingTone();
        setState(() => _callStatus = "Call Ended");
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) _leaveAndPop();
        });
      }
    });

    _busySub = ChatSocketService.instance.onCallBusy.listen((data) {
      if (mounted) {
        _stopRingingTone();
        setState(() => _callStatus = "User Busy");
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (mounted) _leaveAndPop();
        });
      }
    });

    _remoteSub = ZegoCallingService.instance.onRemoteStreamsChanged.listen((streams) async {
      if (!mounted) return;
      if (streams.isNotEmpty && !_isConnected) {
        _stopRingingTone();
        for (final streamId in streams) {
          await ZegoCallingService.instance.startPlayingAudioStream(streamId);
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

  Future<void> _initZegoVoiceCall() async {
    final hasPerm = await ZegoCallingService.instance.requestPermissions(isVideo: false);
    if (!hasPerm) {
      if (mounted) {
        setState(() => _callStatus = "Microphone Permission Required");
      }
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
      if (mounted) setState(() => _callStatus = "Engine Init Failed");
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
      if (mounted) setState(() => _callStatus = "Failed to join room");
      return;
    }

    if (mounted) {
      setState(() {
        _callStatus = widget.isIncoming ? "Connected" : "Ringing...";
      });
      if (!widget.isIncoming) {
        _playRingingTone();
      }
    }
  }

  void _startTimer() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _seconds++);
      }
    });
  }

  Future<void> _leaveAndPop() async {
    _stopRingingTone();
    _ticker?.cancel();
    if (_activeRoomId != null) {
      await ZegoCallingService.instance.leaveRoomAndDestroy(_activeRoomId!);
    }
    if (mounted) Navigator.of(context).maybePop();
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

  void _endCall() {
    _stopRingingTone();
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

  @override
  void dispose() {
    _stopRingingTone();
    _ticker?.cancel();
    _remoteSub?.cancel();
    _declineSub?.cancel();
    _endedSub?.cancel();
    _busySub?.cancel();
    _pulse.dispose();
    if (_activeRoomId != null) {
      ZegoCallingService.instance.leaveRoomAndDestroy(_activeRoomId!);
    }
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
    final statusText = _callStatus ?? widget.status ?? s.callStatus(widget.name);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: QBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              children: [
                // Top bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 32,
                        color: Colors.white70,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.lock_rounded, size: 14, color: Color(0xFF25D366)),
                        const SizedBox(width: 4),
                        Text(
                          "End-to-end encrypted",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Qapp Voice Call",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),

                // Pulsing Avatar
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
                            if (!_isConnected) ...[
                              _ring(150 + t * 50, (1 - t) * 0.4),
                              _ring(125 + t * 25, 0.25),
                            ],
                            child!,
                          ],
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.25),
                            blurRadius: 30,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: QAvatar(
                        name: widget.name,
                        size: 110,
                        colorIndex: widget.colorIndex,
                        photo: widget.photo,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Name
                Text(
                  widget.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Status or Clock
                Text(
                  _isConnected ? _clock : statusText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: statusText.contains("Declined") || statusText.contains("Failed")
                        ? const Color(0xFFEF4444)
                        : (_isConnected ? const Color(0xFF25D366) : Colors.white70),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),

                // Bottom Call Controls
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Mute
                      _controlButton(
                        icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                        label: _muted ? "Unmute" : "Mute",
                        active: _muted,
                        onTap: _toggleMute,
                      ),

                      // End
                      _endButton(),

                      // Speaker
                      _controlButton(
                        icon: _speaker ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                        label: _speaker ? "Speaker" : "Earpiece",
                        active: _speaker,
                        onTap: _toggleSpeaker,
                      ),
                    ],
                  ),
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

  Widget _controlButton({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: active ? Colors.white : Colors.white.withValues(alpha: 0.12),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 58,
              height: 58,
              child: Icon(
                icon,
                color: active ? Colors.black : Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _endButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: const Color(0xFFEF4444),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _endCall,
            child: const SizedBox(
              width: 66,
              height: 66,
              child: Icon(
                Icons.call_end_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "End",
          style: TextStyle(
            color: Color(0xFFEF4444),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
