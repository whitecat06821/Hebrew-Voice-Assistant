import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/tts_service.dart';
import '../services/stt_service.dart';
import 'dart:async';
import 'dart:math';
import '../config.dart';
import 'package:flutter/services.dart';

// ConversationMode replaces CurrentMode for clarity
enum ConversationMode { Idle, Listening, Speaking }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _greeting = 'שלום, איך אפשר לעזור לך?';
  String _recognizedText = _greeting;
  ConversationMode _mode = ConversationMode.Idle;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _requestMicPermission().then((_) {
      setState(() {
        _isActive = false;
        _recognizedText = _greeting;
        _mode = ConversationMode.Speaking;
      });
      TTSService().setOnComplete(() {
        setState(() {
          _isActive = true;
          _mode = ConversationMode.Listening;
        });
        _startListening();
      });
      TTSService().speak(_greeting);
    });
  }

  void _startListening() {
    setState(() {
      _mode = ConversationMode.Listening;
    });
    STTService().listen(
      onResult: (text) {
        setState(() {
          _recognizedText = text.isEmpty ? 'כאן יופיע הטקסט המתומלל' : text;
        });
      },
      onFinal: () async {
        if (!_isActive) return;
        final speech = _recognizedText;
        if (speech.isNotEmpty && speech != 'כאן יופיע הטקסט המתומלל') {
          setState(() {
            _mode = ConversationMode.Speaking;
          });
          TTSService().setOnComplete(() {
            if (_isActive) {
              setState(() {
                _mode = ConversationMode.Listening;
              });
              _startListening();
            }
          });
          await TTSService().speak(speech);
        } else {
          // If nothing was recognized, restart listening
          _startListening();
        }
      },
      pauseDuration: const Duration(seconds: 2),
    );
  }

  void _stopConversation() {
    setState(() {
      _isActive = false;
      _recognizedText = _greeting;
      _mode = ConversationMode.Idle;
    });
    STTService().stop();
    TTSService().stop();
  }

  Future<void> _requestMicPermission() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) return;
    if (status.isPermanentlyDenied) {
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
    Widget? modeIcon;
    switch (_mode) {
      case ConversationMode.Listening:
        modeIcon = const Icon(Icons.mic, size: 48, color: Colors.blue);
        break;
      case ConversationMode.Speaking:
        modeIcon = const Icon(Icons.volume_up, size: 48, color: Colors.orange);
        break;
      case ConversationMode.Idle:
        modeIcon = null;
        break;
    }

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
            if (modeIcon != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: modeIcon,
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
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          SystemNavigator.pop();
        },
        backgroundColor: Colors.red,
        child: const Icon(Icons.close, color: Colors.white),
        tooltip: 'סגור אפליקציה',
      ),
    );
  }
}