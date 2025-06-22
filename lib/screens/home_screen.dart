import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/tts_service.dart';
import '../services/stt_service.dart';
import 'dart:async';
import 'dart:math';

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
  bool _simulationActive = false;

  @override
  void initState() {
    super.initState();
    _requestMicPermission().then((_) {
      setState(() {
        _isActive = true;
        _recognizedText = _fakeSentences[_random.nextInt(_fakeSentences.length)];
      });
      _startConversationLoop();
    });
  }

  void _startConversationLoop() {
    if (!_isActive) return;
    _simulationTimer?.cancel();
    _simulationTimer = Timer(const Duration(seconds: 5), () {
      if (!_isActive) return;
      final fakeText = _fakeSentences[_random.nextInt(_fakeSentences.length)];
      setState(() {
        _recognizedText = fakeText;
      });
      TTSService().setOnComplete(() {
        if (_isActive) {
          _startConversationLoop();
        }
      });
      TTSService().speak(fakeText);
    });
  }

  void _stopConversation() {
    setState(() {
      _isActive = false;
      _recognizedText = _greeting;
    });
    _simulationTimer?.cancel();
    TTSService().stop();
  }

  void _toggleSimulation() {
    setState(() {
      _simulationActive = !_simulationActive;
      _isActive = _simulationActive;
      _recognizedText = _greeting;
    });
    if (_simulationActive) {
      _startConversationLoop();
    } else {
      _stopConversation();
    }
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
    // Always show as if talking
    final buttonColor = Colors.red;
    final buttonText = 'סיים שיחה';
    final buttonIcon = Icons.stop;

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
                    backgroundColor: buttonColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  icon: Icon(buttonIcon, color: Colors.white),
                  label: Text(
                    buttonText,
                    style: const TextStyle(fontSize: 20, color: Colors.white),
                  ),
                  onPressed: _stopConversation,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}