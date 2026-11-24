import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

class ZegoCallingService {
  ZegoCallingService._();
  static final ZegoCallingService instance = ZegoCallingService._();

  // Zego Cloud Credentials (matching backend .env)
  static const int appId = 10954316;
  static const String appSign =
      'f456e6b083e737f9a75b9a703898587a9f57642dacbe90b4852371d617ab2833';

  bool _isInitialized = false;
  bool _isLoggedIn = false;
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isSpeaker = false;
  bool _useFront = true;

  int? _localPreviewViewId;
  final Map<String, int> _remoteViewIds = {};

  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _isLoggedIn;
  bool get isMuted => _isMuted;
  bool get isCameraOff => _isCameraOff;
  bool get isSpeaker => _isSpeaker;
  bool get useFrontCamera => _useFront;

  // Stream controllers
  final _remoteStreamsController = StreamController<List<String>>.broadcast();
  Stream<List<String>> get onRemoteStreamsChanged =>
      _remoteStreamsController.stream;

  final _callConnectedController = StreamController<bool>.broadcast();
  Stream<bool> get onCallConnected => _callConnectedController.stream;

  final List<String> _remoteStreams = [];
  List<String> get remoteStreams => List.unmodifiable(_remoteStreams);

  /// Request microphone & camera permissions
  Future<bool> requestPermissions({required bool isVideo}) async {
    final micStatus = await Permission.microphone.request();
    if (micStatus != PermissionStatus.granted) {
      debugPrint('⚠️ [ZEGO] Microphone permission not granted: $micStatus');
      return false;
    }

    if (isVideo) {
      final camStatus = await Permission.camera.request();
      if (camStatus != PermissionStatus.granted) {
        debugPrint('⚠️ [ZEGO] Camera permission not granted: $camStatus');
        return false;
      }
    }

    return true;
  }

  /// Initialize Zego Express Engine
  Future<bool> initializeEngine({bool isVideo = false}) async {
    if (_isInitialized) return true;

    try {
      final profile = ZegoEngineProfile(
        appId,
        isVideo
            ? ZegoScenario.StandardVideoCall
            : ZegoScenario.StandardVoiceCall,
        appSign: appSign,
      );

      await ZegoExpressEngine.createEngineWithProfile(profile);
      _registerEventCallbacks();
      _isInitialized = true;
      debugPrint('⚡ [ZEGO] Engine initialized successfully');
      return true;
    } catch (e) {
      debugPrint('⚠️ [ZEGO] Engine initialization failed: $e');
      _isInitialized = false;
      return false;
    }
  }

  void _registerEventCallbacks() {
    ZegoExpressEngine.onRoomStateUpdate =
        (
          String roomID,
          ZegoRoomState state,
          int errorCode,
          Map<String, dynamic> extendedData,
        ) {
          debugPrint(
            '⚡ [ZEGO] Room state update: roomID=$roomID, state=$state, errorCode=$errorCode',
          );
          if (state == ZegoRoomState.Connected) {
            _callConnectedController.add(true);
          }
        };

    ZegoExpressEngine.onRoomStreamUpdate =
        (
          String roomID,
          ZegoUpdateType updateType,
          List<ZegoStream> streamList,
          Map<String, dynamic> extendedData,
        ) {
          debugPrint(
            '⚡ [ZEGO] Stream update: roomID=$roomID, updateType=$updateType, streams=${streamList.length}',
          );
          if (updateType == ZegoUpdateType.Add) {
            for (final stream in streamList) {
              if (!_remoteStreams.contains(stream.streamID)) {
                _remoteStreams.add(stream.streamID);
              }
            }
          } else if (updateType == ZegoUpdateType.Delete) {
            for (final stream in streamList) {
              _remoteStreams.remove(stream.streamID);
              stopPlayingRemoteStream(stream.streamID);
            }
          }
          _remoteStreamsController.add(List.from(_remoteStreams));
        };

    ZegoExpressEngine.onRoomUserUpdate =
        (String roomID, ZegoUpdateType updateType, List<ZegoUser> userList) {
          debugPrint(
            '⚡ [ZEGO] User update: roomID=$roomID, updateType=$updateType, users=${userList.map((u) => u.userID).join(',')}',
          );
        };
  }

  /// Join Room and publish local audio/video stream
  Future<bool> loginRoom({
    required String roomId,
    required String userId,
    required String userName,
    String? token,
    bool isVideo = false,
  }) async {
    try {
      _remoteStreams.clear();
      _isMuted = false;
      _isCameraOff = false;

      final user = ZegoUser(userId, userName.isEmpty ? 'User' : userName);
      final config = ZegoRoomConfig(0, true, token ?? '');

      await ZegoExpressEngine.instance.loginRoom(roomId, user, config: config);
      _isLoggedIn = true;
      debugPrint('⚡ [ZEGO] Logged into room: $roomId as $userId');

      // Start publishing local stream
      final streamId = 'stream_${roomId}_$userId';
      await ZegoExpressEngine.instance.startPublishingStream(streamId);
      await ZegoExpressEngine.instance.setCaptureVolume(100);
      debugPrint('⚡ [ZEGO] Publishing stream: $streamId at volume 100');

      if (!isVideo) {
        // Voice call: disable camera to save bandwidth/battery
        await ZegoExpressEngine.instance.enableCamera(false);
      }

      return true;
    } catch (e) {
      debugPrint('⚠️ [ZEGO] Error logging into room: $e');
      return false;
    }
  }

  /// Create local camera preview widget for video calls
  Future<Widget?> createLocalPreviewView() async {
    try {
      final widget = await ZegoExpressEngine.instance.createCanvasView((
        viewId,
      ) {
        _localPreviewViewId = viewId;
        final canvas = ZegoCanvas.view(viewId);
        ZegoExpressEngine.instance.startPreview(canvas: canvas);
      });
      return widget;
    } catch (e) {
      debugPrint('⚠️ [ZEGO] Error creating local preview view: $e');
      return null;
    }
  }

  /// Play remote stream and return rendering widget
  Future<Widget?> createRemoteVideoView(String streamId) async {
    try {
      final widget = await ZegoExpressEngine.instance.createCanvasView((
        viewId,
      ) {
        _remoteViewIds[streamId] = viewId;
        final canvas = ZegoCanvas.view(viewId);
        ZegoExpressEngine.instance.startPlayingStream(streamId, canvas: canvas);
      });
      return widget;
    } catch (e) {
      debugPrint(
        '⚠️ [ZEGO] Error creating remote video view for $streamId: $e',
      );
      return null;
    }
  }

  /// Play remote audio stream for voice calls
  Future<void> startPlayingAudioStream(String streamId) async {
    try {
      await ZegoExpressEngine.instance.startPlayingStream(streamId);
      await ZegoExpressEngine.instance.setPlayVolume(streamId, 100);
      debugPrint(
        '⚡ [ZEGO] Playing remote audio stream: $streamId at volume 100',
      );
    } catch (e) {
      debugPrint('⚠️ [ZEGO] Error playing audio stream for $streamId: $e');
    }
  }

  /// Stop playing a specific remote stream
  Future<void> stopPlayingRemoteStream(String streamId) async {
    try {
      await ZegoExpressEngine.instance.stopPlayingStream(streamId);
      final viewId = _remoteViewIds.remove(streamId);
      if (viewId != null) {
        await ZegoExpressEngine.instance.destroyCanvasView(viewId);
      }
    } catch (e) {
      debugPrint('⚠️ [ZEGO] Error stopping stream $streamId: $e');
    }
  }

  /// Mute / Unmute Microphone
  Future<void> setMicrophoneMute(bool muted) async {
    try {
      await ZegoExpressEngine.instance.muteMicrophone(muted);
      _isMuted = muted;
      debugPrint('🎙️ [ZEGO] Microphone mute toggled: $_isMuted');
    } catch (e) {
      debugPrint('⚠️ [ZEGO] Error muting microphone: $e');
    }
  }

  /// Turn Camera On / Off
  Future<void> setCameraEnabled(bool enabled) async {
    try {
      await ZegoExpressEngine.instance.enableCamera(enabled);
      _isCameraOff = !enabled;
      debugPrint('📷 [ZEGO] Camera enabled: $enabled');
    } catch (e) {
      debugPrint('⚠️ [ZEGO] Error toggling camera: $e');
    }
  }

  /// Flip Front / Back Camera
  Future<void> switchCamera() async {
    try {
      _useFront = !_useFront;
      await ZegoExpressEngine.instance.useFrontCamera(_useFront);
      debugPrint('🔄 [ZEGO] Camera flipped: useFront=$_useFront');
    } catch (e) {
      debugPrint('⚠️ [ZEGO] Error switching camera: $e');
    }
  }

  /// Speakerphone ON / OFF
  Future<void> setSpeakerphone(bool enable) async {
    try {
      await ZegoExpressEngine.instance.setAudioRouteToSpeaker(enable);
      _isSpeaker = enable;
      debugPrint('🔊 [ZEGO] Speakerphone set to: $_isSpeaker');
    } catch (e) {
      debugPrint('⚠️ [ZEGO] Error toggling speakerphone: $e');
    }
  }

  /// Leave Room, stop streams, and cleanly destroy engine
  Future<void> leaveRoomAndDestroy(String roomId) async {
    if (!_isInitialized) {
      _isLoggedIn = false;
      return;
    }
    _isLoggedIn = false;
    _remoteStreams.clear();
    _remoteStreamsController.add([]);

    try {
      if (_isInitialized) {
        await ZegoExpressEngine.instance.stopPublishingStream();
        await ZegoExpressEngine.instance.stopPreview();

        if (_localPreviewViewId != null) {
          await ZegoExpressEngine.instance.destroyCanvasView(
            _localPreviewViewId!,
          );
          _localPreviewViewId = null;
        }

        for (final viewId in _remoteViewIds.values) {
          await ZegoExpressEngine.instance.destroyCanvasView(viewId);
        }
        _remoteViewIds.clear();

        await ZegoExpressEngine.instance.logoutRoom(roomId);
      }
    } catch (e) {
      debugPrint('⚠️ [ZEGO] Error leaving room: $e');
    }

    try {
      if (_isInitialized) {
        await ZegoExpressEngine.destroyEngine();
        _isInitialized = false;
        debugPrint('🏳️ [ZEGO] Engine destroyed cleanly');
      }
    } catch (e) {
      debugPrint('⚠️ [ZEGO] Error destroying engine: $e');
    }
  }
}
