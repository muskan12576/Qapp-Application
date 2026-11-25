import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:qapp/Services/chat_socket_service.dart';
import 'package:qapp/Services/zego_calling_service.dart';
import 'package:qapp/Utills/token_storage.dart';
import 'package:qapp/Views/CallModule/model/call_vm.dart';
import 'package:qapp/l10n/app_lang.dart';
import 'package:qapp/widgets/q_avatar.dart';

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({
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
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  Timer? _ticker;
  int _seconds = 0;
  bool _muted = false;
  bool _cameraOff = false;
  bool _isConnected = false;
  String? _activeCallId;
  String? _activeRoomId;
  String? _callStatus;

  Widget? _localVideoWidget;
  Widget? _remoteVideoWidget;

  // Draggable PIP coordinates
  Offset _pipPosition = const Offset(16, 80);

  StreamSubscription? _remoteSub;
  StreamSubscription? _declineSub;
  StreamSubscription? _endedSub;
  StreamSubscription? _busySub;
  Timer? _ringTimeoutTimer;

  @override
  void initState() {
    super.initState();
    _activeCallId = widget.callId;
    _activeRoomId = widget.roomId;
    _callStatus = widget.isIncoming ? "Connecting..." : "Calling...";

    if (!widget.isIncoming) {
      _playRingingTone();
      _startRingTimeout();
    }

    _listenSockets();
    _initZegoVideoCall();
  }

  void _startRingTimeout() {
    _ringTimeoutTimer?.cancel();
    // 8 rings * 3.0s = 24 seconds
    _ringTimeoutTimer = Timer(const Duration(seconds: 24), () {
      if (!mounted || _isConnected) return;
      _stopRingingTone();
      setState(() => _callStatus = "No Answer");
      HapticFeedback.mediumImpact();
      _endCall();
    });
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
      if (streams.isNotEmpty) {
        _stopRingingTone();
        _ringTimeoutTimer?.cancel();
        final streamId = streams.first;
        final remoteWidget = await ZegoCallingService.instance.createRemoteVideoView(streamId);
        if (mounted) {
          setState(() {
            _remoteVideoWidget = remoteWidget;
            _isConnected = true;
            _callStatus = "Connected";
          });
          _startTimer();
        }
      } else if (streams.isEmpty && _isConnected) {
        _stopRingingTone();
        setState(() {
          _remoteVideoWidget = null;
          _callStatus = "Call Ended";
        });
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) _leaveAndPop();
        });
      }
    });
  }

  Future<void> _initZegoVideoCall() async {
    final hasPerm = await ZegoCallingService.instance.requestPermissions(isVideo: true);
    if (!hasPerm) {
      if (mounted) {
        setState(() => _callStatus = "Camera & Mic Permission Required");
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
        final res = await CallViewModel.instance.initiateVideoCall(
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
        debugPrint('⚠️ [VideoCall] initiateVideoCall error: $e');
      }
    } else if (widget.isIncoming && roomId != null && (token == null || token.isEmpty)) {
      final res = await CallViewModel.instance.getVideoToken(roomId);
      if (res != null) {
        token = res['token']?.toString();
      }
    }

    if (roomId == null || roomId.isEmpty) {
      roomId = 'video_${widget.chatId ?? widget.recipientId ?? DateTime.now().millisecondsSinceEpoch}';
      _activeRoomId = roomId;
    }

    final initialized = await ZegoCallingService.instance.initializeEngine(isVideo: true);
    if (!initialized) {
      if (mounted) setState(() => _callStatus = "Engine Init Failed");
      return;
    }

    final localWidget = await ZegoCallingService.instance.createLocalPreviewView();
    if (mounted) {
      setState(() => _localVideoWidget = localWidget);
    }

    final loggedIn = await ZegoCallingService.instance.loginRoom(
      roomId: roomId,
      userId: myUserId,
      userName: myUserName,
      token: token,
      isVideo: true,
    );

    if (!loggedIn) {
      if (mounted) setState(() => _callStatus = "Failed to join room");
      return;
    }

    if (mounted) {
      setState(() {
        _callStatus = widget.isIncoming ? "Connecting..." : "Ringing...";
      });
      if (!widget.isIncoming) {
        _playRingingTone();
      }
      ZegoCallingService.instance.setSpeakerphone(true);
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
    _ringTimeoutTimer?.cancel();
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

  Future<void> _toggleCamera() async {
    HapticFeedback.selectionClick();
    final next = !_cameraOff;
    await ZegoCallingService.instance.setCameraEnabled(!next);
    if (mounted) setState(() => _cameraOff = next);
  }

  Future<void> _flipCamera() async {
    HapticFeedback.selectionClick();
    await ZegoCallingService.instance.switchCamera();
  }

  void _endCall() {
    _stopRingingTone();
    HapticFeedback.heavyImpact();
    if (_activeCallId != null) {
      CallViewModel.instance.endVideoCall(
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
    _ringTimeoutTimer?.cancel();
    _ticker?.cancel();
    _remoteSub?.cancel();
    _declineSub?.cancel();
    _endedSub?.cancel();
    _busySub?.cancel();
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Full Screen Video (Remote video if connected, or Local camera if waiting)
          Positioned.fill(
            child: _isConnected && _remoteVideoWidget != null
                ? _remoteVideoWidget!
                : (_localVideoWidget != null && !_cameraOff
                    ? _localVideoWidget!
                    : Container(
                        color: const Color(0xFF0F172A),
                        child: Center(
                          child: QAvatar(
                            name: widget.name,
                            size: 110,
                            colorIndex: widget.colorIndex,
                            photo: widget.photo,
                          ),
                        ),
                      )),
          ),

          // 2. Caller Info overlay (when ringing / connecting or if remote video is empty)
          if (!_isConnected)
            Positioned(
              top: 70,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.videocam_rounded, color: Color(0xFF25D366), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          "Qapp Video Call",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusText.contains("Declined") || statusText.contains("Failed")
                          ? const Color(0xFFEF4444)
                          : Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      shadows: const [Shadow(color: Colors.black54, blurRadius: 8)],
                    ),
                  ),
                ],
              ),
            ),

          // 3. Top Call Duration pill when connected
          if (_isConnected)
            Positioned(
              top: 50,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF25D366),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _clock,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 4. Floating Local Camera PIP (when connected & remote video is visible)
          if (_isConnected && _remoteVideoWidget != null && _localVideoWidget != null)
            Positioned(
              top: _pipPosition.dy,
              right: _pipPosition.dx,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _pipPosition = Offset(
                      (_pipPosition.dx - details.delta.dx).clamp(10.0, 240.0),
                      (_pipPosition.dy + details.delta.dy).clamp(50.0, 500.0),
                    );
                  });
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 110,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white30, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: _cameraOff
                        ? const Center(
                            child: Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 30),
                          )
                        : _localVideoWidget!,
                  ),
                ),
              ),
            ),

          // 5. Bottom Call Controls Bar
          Positioned(
            left: 20,
            right: 20,
            bottom: 36,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Flip Camera
                  _actionButton(
                    icon: Icons.flip_camera_ios_rounded,
                    label: "Flip",
                    active: false,
                    onTap: _flipCamera,
                  ),

                  // Camera Toggle
                  _actionButton(
                    icon: _cameraOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                    label: _cameraOff ? "Camera On" : "Camera Off",
                    active: _cameraOff,
                    onTap: _toggleCamera,
                  ),

                  // End Call
                  _endButton(),

                  // Mute Mic
                  _actionButton(
                    icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    label: _muted ? "Unmute" : "Mute",
                    active: _muted,
                    onTap: _toggleMute,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: active ? Colors.white : Colors.white.withValues(alpha: 0.15),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 52,
              height: 52,
              child: Icon(
                icon,
                color: active ? Colors.black : Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
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
              width: 60,
              height: 60,
              child: Icon(
                Icons.call_end_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "End",
          style: TextStyle(
            color: Color(0xFFEF4444),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
