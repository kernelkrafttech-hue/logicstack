import 'package:flutter/services.dart';

class KeyboardChannel {
  static const _channel = MethodChannel('com.kernelkraft.punjabi_keyboard/ime');

  static Future<void> openKeyboardSettings() async {
    await _channel.invokeMethod('openImeSettings');
  }

  static Future<void> showInputMethodPicker() async {
    await _channel.invokeMethod('showImePicker');
  }

  static Future<bool> isKeyboardEnabled() async {
    final result = await _channel.invokeMethod<bool>('isImeEnabled');
    return result ?? false;
  }

  static Future<bool> isKeyboardSelected() async {
    final result = await _channel.invokeMethod<bool>('isImeSelected');
    return result ?? false;
  }
}
