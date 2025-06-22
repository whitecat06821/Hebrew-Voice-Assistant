import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  late final FlutterTts _flutterTts;
  VoidCallback? _onCompleteCallback;

  TTSService._internal() {
    _flutterTts = FlutterTts();
    _flutterTts.setLanguage('he-IL');
    _flutterTts.setSpeechRate(0.5); // Optional: adjust as needed
  }

  Future<void> speak(String text) async {
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  void setOnComplete(VoidCallback onComplete) {
    _onCompleteCallback = onComplete;
    _flutterTts.setCompletionHandler(() {
      if (_onCompleteCallback != null) {
        _onCompleteCallback!();
      }
    });
  }
}
