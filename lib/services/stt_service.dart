import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class STTService {
  static final STTService _instance = STTService._internal();
  factory STTService() => _instance;
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  Timer? _pauseTimer;

  STTService._internal();

  Future<bool> init() async {
    if (!_isInitialized) {
      _isInitialized = await _speechToText.initialize(
        onStatus: (status) => print('STT status: $status'),
        onError: (error) => print('STT error: $error'),
      );
      print('STT initialized: [32m$_isInitialized[0m');
    }
    return _isInitialized;
  }

  Future<void> listen({
    required Function(String) onResult,
    required VoidCallback onFinal,
    Duration pauseDuration = const Duration(seconds: 2),
  }) async {
    await init();
    print('STT: Starting to listen (he_IL)');
    String lastRecognized = '';
    _pauseTimer?.cancel();
    await _speechToText.listen(
      localeId: 'he_IL',
      onResult: (result) {
        print('STT result: [34m${result.recognizedWords}[0m');
        onResult(result.recognizedWords);
        lastRecognized = result.recognizedWords;
        _pauseTimer?.cancel();
        _pauseTimer = Timer(pauseDuration, () {
          print('STT: Pause detected, triggering onFinal');
          stop();
          onFinal();
        });
      },
      listenMode: ListenMode.confirmation,
    );
  }

  void stop() {
    print('STT: Stopped listening');
    _pauseTimer?.cancel();
    _speechToText.stop();
  }

  bool get isListening => _speechToText.isListening;
}
