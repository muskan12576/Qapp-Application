import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qapp/Services/chat_socket_service.dart';
import 'package:qapp/Services/zego_calling_service.dart';
import 'package:qapp/Utills/token_storage.dart';
import 'package:qapp/widgets/q_avatar.dart';

class GroupCallScreen extends StatefulWidget {
  const GroupCallScreen({
    super.key,
    required this.groupName,
    required this.roomId,
    this.participantIds = const [],
    this.isVideo = true,
    this.token,
    this.isIncoming = false,
  });

  final String groupName;
  final String roomId;
  final List<String> participantIds;
  final bool isVideo;
  final String? token;
  final bool isIncoming;

  @override
  State<GroupCallScreen> createState() => _GroupCallScreenState();
}

class _GroupCallScreenState extends State<GroupCallScreen> {
  Timer? _ticker;
  int _seconds = 0;
  bool _muted = false;
  bool _cameraOff = false;
  bool _speaker = true;

  Widget? _localVideoWidget;
  final Map<String, Widget> _remoteWidgets = {};

  StreamSubscription? _streamsSub;
  StreamSubscription? _endedSub;

  @override
  void initState() {
    super.initState();
    _listenEvents();
    _initZegoGroupCall();
  }

  void _listenEvents() {
    _endedSub = ChatSocketService.instance.onCallEnded.listen((data) {
      if (data['roomId']?.toString() == widget.roomId && mounted) {
        _leaveAndPop();
      }
    });

    _streamsSub = ZegoCallingService.instance.onRemoteStreamsChanged.listen((streams) async {
      if (!mounted) return;

      // Clean up removed streams
      _remoteWidgets.removeWhere((id, _) => !streams.contains(id));

      // Add new streams
      for (final streamId in streams) {
        if (!_remoteWidgets.containsKey(streamId) && widget.isVideo) {
          final widgetView = await ZegoCallingService.instance.createRemoteVideoView(streamId);
          if (widgetView != null && mounted) {
            setState(() {
              _remoteWidgets[streamId] = widgetView;
            });
          }
        }
      }

      if (mounted) setState(() {});
    });
  }

  Future<void> _initZegoGroupCall() async {
    final hasPerm = await ZegoCallingService.instance.requestPermissions(isVideo: widget.isVideo);
    if (!hasPerm) return;

    await TokenStorage.instance.load();
    final myUserId = TokenStorage.instance.userId.isNotEmpty
        ? TokenStorage.instance.userId
        : 'user_${DateTime.now().millisecondsSinceEpoch}';
    final myUserName = TokenStorage.instance.name.isNotEmpty
        ? TokenStorage.instance.name
        : 'User';

    final initialized = await ZegoCallingService.instance.initializeEngine(isVideo: widget.isVideo);
    if (!initialized) return;

    if (widget.isVideo) {
      final localView = await ZegoCallingService.instance.createLocalPreviewView();
      if (mounted) setState(() => _localVideoWidget = localView);
    }

    final loggedIn = await ZegoCallingService.instance.loginRoom(
      roomId: widget.roomId,
      userId: myUserId,
      userName: myUserName,
      token: widget.token,
      isVideo: widget.isVideo,
    );

    if (loggedIn) {
      _startTimer();
    }
  }

  void _startTimer() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  String get _clock {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _leaveAndPop() async {
    _ticker?.cancel();
    await ZegoCallingService.instance.leaveRoomAndDestroy(widget.roomId);
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

  Future<void> _toggleSpeaker() async {
    HapticFeedback.selectionClick();
    final next = !_speaker;
    await ZegoCallingService.instance.setSpeakerphone(next);
    if (mounted) setState(() => _speaker = next);
  }

  void _endCall() {
    HapticFeedback.heavyImpact();
    ChatSocketService.instance.endCall(
      callId: widget.roomId,
      roomId: widget.roomId,
    );
    _leaveAndPop();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _streamsSub?.cancel();
    _endedSub?.cancel();
    ZegoCallingService.instance.leaveRoomAndDestroy(widget.roomId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remoteStreams = ZegoCallingService.instance.remoteStreams;
    final totalParticipants = 1 + remoteStreams.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Stack(
          children: [
            // Top App Bar
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 30),
                  ),
                  Column(
                    children: [
                      Text(
                        widget.groupName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF25D366),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "$_clock • $totalParticipants participants",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Video / Participant Grid
            Positioned.fill(
              top: 72,
              bottom: 100,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildDynamicGrid(remoteStreams),
              ),
            ),

            // Bottom Controls Bar
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (widget.isVideo) ...[
                      _actionBtn(
                        icon: Icons.flip_camera_ios_rounded,
                        label: "Flip",
                        onTap: _flipCamera,
                      ),
                      _actionBtn(
                        icon: _cameraOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                        label: _cameraOff ? "Camera On" : "Camera Off",
                        active: _cameraOff,
                        onTap: _toggleCamera,
                      ),
                    ] else ...[
                      _actionBtn(
                        icon: _speaker ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                        label: _speaker ? "Speaker" : "Earpiece",
                        active: _speaker,
                        onTap: _toggleSpeaker,
                      ),
                    ],
                    _endBtn(),
                    _actionBtn(
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
      ),
    );
  }

  Widget _buildDynamicGrid(List<String> remoteStreams) {
    if (remoteStreams.isEmpty) {
      // Only local user
      return Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            height: 380,
            color: const Color(0xFF1E293B),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (widget.isVideo && _localVideoWidget != null && !_cameraOff)
                  _localVideoWidget!
                else
                  const QAvatar(name: "You", size: 90, colorIndex: 1),
                Positioned(
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      "Waiting for others to join...",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (remoteStreams.length == 1) {
      // 2 Users: Split 50% Top and 50% Bottom
      final remoteStreamId = remoteStreams.first;
      return Column(
        children: [
          Expanded(child: _participantCard(widget: _remoteWidgets[remoteStreamId], title: "Participant")),
          const SizedBox(height: 8),
          Expanded(child: _participantCard(widget: widget.isVideo && !_cameraOff ? _localVideoWidget : null, title: "You")),
        ],
      );
    }

    // 3+ Users: 2-Column Grid
    return GridView.builder(
      itemCount: 1 + remoteStreams.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _participantCard(
            widget: widget.isVideo && !_cameraOff ? _localVideoWidget : null,
            title: "You",
          );
        }
        final streamId = remoteStreams[index - 1];
        return _participantCard(
          widget: _remoteWidgets[streamId],
          title: "User $index",
        );
      },
    );
  }

  Widget _participantCard({Widget? widget, required String title}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: const Color(0xFF1E293B),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (widget != null) widget else QAvatar(name: title, size: 64, colorIndex: 2),
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    bool active = false,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: active ? Colors.white : Colors.white.withValues(alpha: 0.14),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 50,
              height: 50,
              child: Icon(icon, color: active ? Colors.black : Colors.white, size: 24),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
        ),
      ],
    );
  }

  Widget _endBtn() {
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
              width: 58,
              height: 58,
              child: Icon(Icons.call_end_rounded, color: Colors.white, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text("Leave", style: TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
