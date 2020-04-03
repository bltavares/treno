import 'dart:async';

import 'package:flutter/services.dart';

class Treno {
  static const MethodChannel _channel =
      const MethodChannel('treno');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
