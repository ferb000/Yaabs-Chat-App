import 'package:flutter/foundation.dart';

import '../../../core/config/env.dart';

String resolveMediaUrl(String url) {
  final parsed = Uri.tryParse(url);
  if (parsed != null && parsed.hasScheme && parsed.host.isNotEmpty) {
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        (parsed.host == 'localhost' || parsed.host == '127.0.0.1')) {
      return parsed.replace(host: '10.0.2.2').toString();
    }
    return url;
  }

  return Uri.parse(Env.apiBaseUrl).resolve(url).toString();
}

bool isVideoMediaUrl(String url, {String? mime}) {
  final lowerMime = mime?.toLowerCase();
  if (lowerMime != null && lowerMime.startsWith('video/')) return true;

  final parsed = Uri.tryParse(url);
  final path = parsed?.path.toLowerCase() ?? url.toLowerCase();
  return path.endsWith('.mp4') ||
      path.endsWith('.mov') ||
      path.endsWith('.m4v') ||
      path.endsWith('.webm') ||
      path.contains('/video/');
}
