When the user taps the red "סיים שיחה" button on the home screen, all speech recognition and TTS will stop. Optionally, you can reset the UI.
And I want the initial state to be the stopped state.
Once the start button is clicked, the app will recognize and echo the speech.
And if you stop, all actions will stop.
And I change the icon and button color to easily recognize the start and stop states.import 'package:flutter/material.dart';
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
  String _recognizedText = 'כאן יופיע הטקסט המתומלל';
  String _lastRecognized = '';

  @override
  void initState() {
    super.initState();
    _requestMicPermission();
    TTSService().setCompletionHandler(_onTtsComplete);
    TTSService().speak('שלום, איך אפשר לעזור לך?');
  }

  void _onTtsComplete() {
    STTService().listen(
      onResult: (text) {
        setState(() {
          _recognizedText = text.isEmpty ? 'כאן יופיע הטקסט המתומלל' : text;
          _lastRecognized = text;
        });
      },
      onFinal: () async {
        if (_lastRecognized.isNotEmpty) {
          await Future.delayed(const Duration(seconds: 1));
          TTSService().speak(_lastRecognized);
        }
      },
      pauseDuration: const Duration(seconds: 2),
    );
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
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed: () {},
                  child: const Text(
                    'סיים שיחה',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}