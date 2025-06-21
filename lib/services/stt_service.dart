import 'package:speech_to_text/speech_to_text.dart';

class STTService {
  static final STTService _instance = STTService._internal();
  factory STTService() => _instance;
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;

  STTService._internal();

  Future<bool> init() async {
    if (!_isInitialized) {
      _isInitialized = await _speechToText.initialize();
    }
    return _isInitialized;
  }

  Future<void> listen({required Function(String) onResult}) async {
    await init();
    await _speechToText.listen(
      localeId: 'he_IL',
      onResult: (result) {
        onResult(result.recognizedWords);
      },
      listenMode: ListenMode.confirmation,
    );
  }

  void stop() {
    _speechToText.stop();
  }

  bool get isListening => _speechToText.isListening;
} 