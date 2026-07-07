import 'package:flutter/foundation.dart';

class Env {
  static const String _renderApiBaseUrl =
      'https://full-node-chat-api.onrender.com';

  static String get apiBaseUrl {
    if (kIsWeb) return _renderApiBaseUrl;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _renderApiBaseUrl;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return _renderApiBaseUrl;
      default:
        return _renderApiBaseUrl;
    }
  }
}
