import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/tts_service.dart';
import '../services/stt_service.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _greeting = 'שלום, איך אפשר לעזור לך?';
  String _recognizedText = _greeting;
  String _lastRecognized = '';
  bool _isActive = false;
  bool _isProcessing = false;
  bool _greetingSpoken = false;
  Timer? _simulationTimer;
  bool _isListening = false;
  final List<String> _fakeSentences = [
    'מה שלומך היום?',
    'האם אתה צריך עזרה במשהו?',
    'מזג האוויר יפה היום.',
    'אני כאן כדי לעזור לך.',
    'ספר לי מה תרצה לעשות.',
    'האם יש משהו שתרצה לדעת?',
    'במה אפשר לסייע לך?',
    'האם תרצה לשמוע בדיחה?',
    'האם יש לך שאלה בשבילי?',
    'אני אוהב לעזור לאנשים.'
  ];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _requestMicPermission().then((_) {
      setState(() {
        _recognizedText = _greeting;
      });
      TTSService().setOnComplete(() {
        _startConversationLoop();
      });
      TTSService().speak(_greeting);
    });
  }

  void _startConversationLoop() {
    _isListening = true;
    STTService().listen(
      onResult: (text) {
        setState(() {
          _recognizedText = text.isEmpty ? 'כאן יופיע הטקסט המתומלל' : text;
        });
      },
      onFinal: () async {
        final speech = _recognizedText;
        if (speech.isNotEmpty && speech != 'כאן יופיע הטקסט המתומלל') {
          _lastRecognized = speech;
          _isListening = false;
          _echoRecognizedSentence();
        } else {
          // If nothing was recognized, restart listening
          _startConversationLoop();
        }
      },
      pauseDuration: const Duration(seconds: 2),
    );
  }

  void _echoRecognizedSentence() {
    TTSService().setOnComplete(() {
      if (!_isListening) {
        _echoRecognizedSentence();
      }
    });
    TTSService().speak(_lastRecognized);
    // While echoing, also listen in the background for new speech
    STTService().listen(
      onResult: (text) {
        setState(() {
          _recognizedText = text.isEmpty ? 'כאן יופיע הטקסט המתומלל' : text;
        });
      },
      onFinal: () async {
        final speech = _recognizedText;
        if (speech.isNotEmpty && speech != 'כאן יופיע הטקסט המתומלל' && speech != _lastRecognized) {
          _lastRecognized = speech;
          _isListening = false;
          _echoRecognizedSentence();
        } else {
          // If nothing new, keep echoing
          _isListening = false;
        }
      },
      pauseDuration: const Duration(seconds: 2),
    );
  }

  void _closeApp() {
    TTSService().stop();
    SystemNavigator.pop();
  }

  Future<void> _requestMicPermission() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) return;

    if (status.isPermanentlyDenied) {
      // Show dialog to open app settings
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('דרושה הרשאה'),
            content: const Text('יש לאפשר גישה למיקרופון כדי להשתמש באפליקציה. פתח את הגדרות האפליקציה כדי לאפשר הרשאה.'),
            actions: [
              TextButton(
                onPressed: () {
                  openAppSettings();
                  Navigator.of(context).pop();
                },
                child: const Text('פתח הגדרות'),
              ),
            ],
          ),
        );
      }
    } else {
      // Show regular denied dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('דרושה הרשאה'),
            content: const Text('יש לאפשר גישה למיקרופון כדי להשתמש באפליקציה.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('אישור'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 32.0),
              child: Text(
                'שלום, איך אפשר לעזור לך?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  _recognizedText,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: SizedBox(
                width: 220,
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  icon: const Icon(Icons.close, color: Colors.white),
                  label: const Text(
                    'סגור אפליקציה',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                  onPressed: _closeApp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}