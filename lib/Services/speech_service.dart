import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  SpeechService._();
  static final SpeechService instance = SpeechService._();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  Function(String status)? _currentStatusCallback;

  bool get isListening => _isListening;
  bool get isAvailable => _isInitialized;

  // Stream of recognized speech text
  final _textController = StreamController<String>.broadcast();
  Stream<String> get onSpeechText => _textController.stream;

  // Stream of sound level (0 to 10 for audio waveform animation)
  final _soundLevelController = StreamController<double>.broadcast();
  Stream<double> get onSoundLevel => _soundLevelController.stream;

  // Stream of recognition status ('listening', 'notListening', 'done', 'error')
  final _statusController = StreamController<String>.broadcast();
  Stream<String> get onStatus => _statusController.stream;

  Future<bool> initialize() async {
    if (_isInitialized && _speech.isAvailable) return true;
    try {
      final micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) {
        final requested = await Permission.microphone.request();
        if (!requested.isGranted) {
          debugPrint('⚠️ [SPEECH] Microphone permission not granted: $requested');
          return false;
        }
      }

      _isInitialized = await _speech.initialize(
        onStatus: (status) {
          debugPrint('🎙️ [SPEECH] Status: $status');
          if (status == 'notListening' || status == 'done') {
            _isListening = false;
          }
          _statusController.add(status);
          _currentStatusCallback?.call(status);
        },
        onError: (SpeechRecognitionError error) {
          debugPrint('⚠️ [SPEECH] Error: ${error.errorMsg}');
          _isListening = false;
          _statusController.add('error');
          _currentStatusCallback?.call('error');
        },
        debugLogging: true,
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('⚠️ [SPEECH] Exception initializing: $e');
      _isInitialized = false;
      return false;
    }
  }

  Future<bool> startListening({
    required Function(String text, bool isFinal) onResult,
    Function(String status)? onStatus,
    String? localeId,
  }) async {
    _currentStatusCallback = onStatus;
    final ready = await initialize();
    if (!ready) {
      debugPrint('⚠️ [SPEECH] SpeechToText not available or permission denied');
      return false;
    }

    try {
      if (_speech.isListening) {
        await _speech.stop();
      }

      _isListening = true;
      _statusController.add('listening');
      _currentStatusCallback?.call('listening');

      await _speech.listen(
        onResult: (result) {
          final text = result.recognizedWords;
          _textController.add(text);
          onResult(text, result.finalResult);
        },
        onSoundLevelChange: (level) {
          _soundLevelController.add(level.clamp(0.0, 10.0));
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          listenFor: const Duration(seconds: 45),
          pauseFor: const Duration(seconds: 3),
          localeId: localeId,
          cancelOnError: false,
          partialResults: true,
        ),
      );
      return true;
    } catch (e) {
      debugPrint('⚠️ [SPEECH] Listen error: $e');
      _isListening = false;
      _statusController.add('error');
      _currentStatusCallback?.call('error');
      return false;
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      try {
        await _speech.stop();
      } catch (_) {}
      _isListening = false;
      _statusController.add('notListening');
      _currentStatusCallback?.call('notListening');
      _currentStatusCallback = null;
    }
  }
}
