import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Centralizes small, non-blocking device feedback used by Testified.
///
/// Android reports its ringer mode through the native channel so navigation
/// haptics are only emitted in normal mode. Other platforms keep their native
/// haptic behavior and system accessibility settings.
abstract final class DeviceFeedbackService {
  static const MethodChannel _channel = MethodChannel(
    'com.testified/device_feedback',
  );

  static Future<void> playPrescriptionSuccess() async {
    try {
      await _channel.invokeMethod<void>('playPrescriptionSuccess');
    } on MissingPluginException {
      await _playFallbackClick();
    } on PlatformException {
      await _playFallbackClick();
    }
  }

  static Future<void> navigationSelection() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final isNormalMode =
            await _channel.invokeMethod<bool>('isRingerModeNormal') ?? false;
        if (!isNormalMode) return;
      } on MissingPluginException {
        // Widget tests and unsupported hosts can still use Flutter's no-op-safe
        // haptic implementation.
      } on PlatformException {
        return;
      }
    }

    try {
      await HapticFeedback.selectionClick();
    } catch (_) {
      // Feedback must never delay or block navigation.
    }
  }

  static Future<void> _playFallbackClick() async {
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {
      // The success route still communicates completion visually.
    }
  }
}
