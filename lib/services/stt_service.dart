import 'package:speech_to_text/speech_to_text.dart';

class STTService {
  static final STTService _instance = STTService._internal();
  factory STTService() => _instance;
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;

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

  Future<void> listen({required Function(String) onResult}) async {
    await init();
    print('STT: Starting to listen (he_IL)');
    await _speechToText.listen(
      localeId: 'he_IL',
      onResult: (result) {
        print('STT result: [34m${result.recognizedWords}[0m');
        onResult(result.recognizedWords);
      },
      listenMode: ListenMode.confirmation,
    );
  }

  void stop() {
    print('STT: Stopped listening');
    _speechToText.stop();
  }

  bool get isListening => _speechToText.isListening;
}