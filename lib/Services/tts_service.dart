import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  final _speakingController = StreamController<bool>.broadcast();
  Stream<bool> get onSpeakingChanged => _speakingController.stream;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.awaitSpeakCompletion(true);

      // Check available languages and prefer Hindi / Indian English
      try {
        final languages = await _flutterTts.getLanguages;
        if (languages is List) {
          if (languages.any((l) => l.toString().contains('hi'))) {
            await _flutterTts.setLanguage("hi-IN");
          } else if (languages.any((l) => l.toString().contains('en-IN') || l.toString().contains('en_IN'))) {
            await _flutterTts.setLanguage("en-IN");
          } else {
            await _flutterTts.setLanguage("en-US");
          }
        }
      } catch (_) {
        await _flutterTts.setLanguage("hi-IN");
      }

      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        _speakingController.add(true);
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        _speakingController.add(false);
      });

      _flutterTts.setCancelHandler(() {
        _isSpeaking = false;
        _speakingController.add(false);
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('⚠️ [TTS] Error: $msg');
        _isSpeaking = false;
        _speakingController.add(false);
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('⚠️ [TTS] Init error: $e');
    }
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await init();
    try {
      await _flutterTts.stop();
      _isSpeaking = true;
      _speakingController.add(true);
      await _flutterTts.speak(text.trim());
    } catch (e) {
      debugPrint('⚠️ [TTS] Speak error: $e');
      _isSpeaking = false;
      _speakingController.add(false);
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
      _speakingController.add(false);
    } catch (_) {}
  }
}
