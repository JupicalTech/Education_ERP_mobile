import 'package:flutter/foundation.dart';

class AppLogger {
  static void d(String msg, [dynamic extra]) {
    if (kDebugMode) debugPrint('[DEBUG] $msg ${extra ?? ''}');
  }

  static void e(String msg, [dynamic error]) {
    if (kDebugMode) debugPrint('[ERROR] $msg: $error');
  }

  static void i(String msg) {
    if (kDebugMode) debugPrint('[INFO] $msg');
  }
}