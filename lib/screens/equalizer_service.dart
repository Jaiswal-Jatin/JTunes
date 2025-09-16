import 'dart:io'; // Import dart:io for Platform checks
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

class EqualizerService {
  static final EqualizerService _instance = EqualizerService._internal();
  factory EqualizerService() => _instance;
  EqualizerService._internal() {
    // Initialize equalizer conditionally based on platform
    if (Platform.isAndroid) {
      equalizer = AndroidEqualizer();
      // The equalizer is disabled by default.
      isEqualizerEnabled.value = equalizer!.enabled;
      equalizer!.enabledStream.listen((enabled) {
        isEqualizerEnabled.value = enabled;
      });
    } else {
      equalizer = null;
      isEqualizerEnabled.value = false; // Equalizer is not available on other platforms
    }
  }

  AndroidEqualizer? equalizer; // Made nullable
  final ValueNotifier<bool> isEqualizerEnabled = ValueNotifier(false);

  Future<void> setEnabled(bool enabled) async {
    if (equalizer != null) {
      await equalizer!.setEnabled(enabled);
    } else {
      // Log or handle the case where equalizer is not available
      debugPrint('Equalizer is not available on this platform.');
    }
  }
}
