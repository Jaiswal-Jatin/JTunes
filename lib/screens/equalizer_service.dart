import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

class EqualizerService {
  static final EqualizerService _instance = EqualizerService._internal();
  factory EqualizerService() => _instance;
  EqualizerService._internal() {
    // The equalizer is disabled by default.
    isEqualizerEnabled.value = equalizer.enabled;
    equalizer.enabledStream.listen((enabled) {
      isEqualizerEnabled.value = enabled;
    });
  }

  final AndroidEqualizer equalizer = AndroidEqualizer();
  final ValueNotifier<bool> isEqualizerEnabled = ValueNotifier(false);

  Future<void> setEnabled(bool enabled) async {
    await equalizer.setEnabled(enabled);
  }
}