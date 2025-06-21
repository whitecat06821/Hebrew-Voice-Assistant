import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/tts_service.dart';
import '../services/stt_service.dart';
import 'dart:async';

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

  @override
  void initState() {
    super.initState();
    _requestMicPermission();
    // Show greeting immediately and speak it
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakGreeting();
    });
  }

  void _speakGreeting() {
    if (!_greetingSpoken) {
      TTSService().speak(_greeting);
      _greetingSpoken = true;
    }
  }

  void _startConversation() {
    setState(() {
      _isActive = true;
      _isProcessing = true;
      _recognizedText = 'כאן יופיע הטקסט המתומלל';
      _lastRecognized = '';
    });
    TTSService().setCompletionHandler(_onTtsComplete);
    TTSService().speak(_greeting);
  }

  void _onTtsComplete() {
    if (!_isActive) return;
    STTService().listen(
      onResult: (text) {
        setState(() {
          _recognizedText = text.isEmpty ? 'כאן יופיע הטקסט המתומלל' : text;
          _lastRecognized = text;
        });
      },
      onFinal: () async {
        if (!_isActive) return;
        if (_lastRecognized.isNotEmpty) {
          await Future.delayed(const Duration(seconds: 1));
          TTSService().speak(_lastRecognized);
        }
      },
      pauseDuration: const Duration(seconds: 2),
    );
  }

  void _stopConversation() {
    setState(() {
      _isActive = false;
      _isProcessing = false;
      _recognizedText = _greeting;
      _lastRecognized = '';
    });
    STTService().stop();
    TTSService().stop();
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
    final isStopped = !_isActive;
    final buttonColor = isStopped ? Colors.green : Colors.red;
    final buttonText = isStopped ? 'התחל שיחה' : 'סיים שיחה';
    final buttonIcon = isStopped ? Icons.mic : Icons.stop;

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
                  onPressed: isStopped ? _startConversation : _stopConversation,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}