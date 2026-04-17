import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Speech recognition configured for Punjabi (pa-IN).
///
/// On-device support depends on the OS/Google app locale packs. If pa-IN is
/// unavailable the service falls back to the best matching locale.
class SpeechService extends ChangeNotifier {
  SpeechService._();
  static final SpeechService instance = SpeechService._();

  static const _preferredLocale = 'pa_IN';
  final SpeechToText _stt = SpeechToText();

  bool _available = false;
  bool _listening = false;
  String _transcript = '';
  String? _error;

  bool get available => _available;
  bool get listening => _listening;
  String get transcript => _transcript;
  String? get error => _error;

  Future<bool> init() async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      _error = 'Microphone permission denied';
      notifyListeners();
      return false;
    }
    _available = await _stt.initialize(
      onStatus: (s) {
        _listening = s == 'listening';
        notifyListeners();
      },
      onError: (e) {
        _error = e.errorMsg;
        _listening = false;
        notifyListeners();
      },
    );
    notifyListeners();
    return _available;
  }

  Future<void> start() async {
    if (!_available && !await init()) return;
    _transcript = '';
    _error = null;
    await _stt.listen(
      localeId: _preferredLocale,
      onResult: (SpeechRecognitionResult r) {
        _transcript = r.recognizedWords;
        notifyListeners();
      },
      listenFor: const Duration(minutes: 2),
      pauseFor: const Duration(seconds: 4),
    );
  }

  Future<void> stop() async {
    await _stt.stop();
    _listening = false;
    notifyListeners();
  }

  void clear() {
    _transcript = '';
    notifyListeners();
  }
}
