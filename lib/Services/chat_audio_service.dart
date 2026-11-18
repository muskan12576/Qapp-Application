import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ChatAudioService extends ChangeNotifier {
  ChatAudioService._() {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  static final ChatAudioService instance = ChatAudioService._();
  static const _channel = MethodChannel('qapp/audio');

  String? _currentPath;
  bool _isPlaying = false;
  int _positionMs = 0;
  int _durationMs = 0;
  Timer? _poller;

  String? get currentPath => _currentPath;
  bool get isPlaying => _isPlaying;
  int get positionMs => _positionMs;
  int get durationMs => _durationMs;
  int get currentPosition => _positionMs;
  int get totalDuration => _durationMs;

  bool isCurrentPlaying(String? path) {
    if (path == null || _currentPath == null) return false;
    return _currentPath == path && _isPlaying;
  }

  bool isCurrent(String? path) {
    if (path == null || _currentPath == null) return false;
    return _currentPath == path;
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onAudioPrepared') {
      _isPlaying = true;
      final dur = call.arguments?['duration'];
      if (dur is int && dur > 0) {
        _durationMs = dur;
      }
      _startPoller();
      notifyListeners();
    } else if (call.method == 'onAudioComplete') {
      _isPlaying = false;
      _positionMs = 0;
      _stopPoller();
      notifyListeners();
    } else if (call.method == 'onAudioError') {
      _isPlaying = false;
      _stopPoller();
      notifyListeners();
    }
  }

  Future<void> play(String pathOrUrl) async {
    if (pathOrUrl.isEmpty) return;

    if (_currentPath == pathOrUrl && _isPlaying) {
      await pause();
      return;
    }

    if (_currentPath != pathOrUrl) {
      await stop();
      _currentPath = pathOrUrl;
      _positionMs = 0;
      _durationMs = 0;
    }

    try {
      if (Platform.isAndroid) {
        final res = await _channel.invokeMethod<Map>('play', {'path': pathOrUrl});
        _isPlaying = true;
        if (res != null && res['duration'] is int) {
          _durationMs = res['duration'] as int;
        }
      } else {
        // Desktop / Mock fallback
        _isPlaying = true;
        _durationMs = 15000;
      }
      _startPoller();
      notifyListeners();
    } catch (e) {
      debugPrint('⚡ [AUDIO PLAYER] Error playing: $e');
      _isPlaying = false;
      _stopPoller();
      notifyListeners();
    }
  }

  Future<void> pause() async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('pause');
      }
    } catch (_) {}
    _isPlaying = false;
    _stopPoller();
    notifyListeners();
  }

  Future<void> stop() async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('stop_play');
      }
    } catch (_) {}
    _isPlaying = false;
    _currentPath = null;
    _positionMs = 0;
    _durationMs = 0;
    _stopPoller();
    notifyListeners();
  }

  Future<void> seek(int positionMs) async {
    _positionMs = positionMs;
    notifyListeners();
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('seek', {'position': positionMs});
      }
    } catch (_) {}
  }

  void _startPoller() {
    _poller?.cancel();
    _poller = Timer.periodic(const Duration(milliseconds: 300), (_) async {
      if (!_isPlaying) {
        _stopPoller();
        return;
      }

      if (Platform.isAndroid) {
        try {
          final res = await _channel.invokeMethod<Map>('status');
          if (res != null) {
            _isPlaying = res['isPlaying'] == true;
            _positionMs = res['position'] as int? ?? _positionMs;
            final dur = res['duration'] as int? ?? 0;
            if (dur > 0) _durationMs = dur;
            notifyListeners();
            if (!_isPlaying) _stopPoller();
          }
        } catch (_) {}
      } else {
        _positionMs += 300;
        if (_positionMs >= _durationMs) {
          _isPlaying = false;
          _positionMs = 0;
          _stopPoller();
        }
        notifyListeners();
      }
    });
  }

  void _stopPoller() {
    _poller?.cancel();
    _poller = null;
  }

  @override
  void dispose() {
    _stopPoller();
    super.dispose();
  }
}
