import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'push_service.dart';
import 'providers.dart';

final pushControllerProvider = Provider<PushController>((ref) {
  return PushController(ref);
});

class PushController {
  PushController(this.ref);

  final Ref ref;
  final PushService _pushService = PushService();
  String? _registeredToken;

  Future<void> init() async {
    final token = await _pushService.init();

    if (token == null) {
      debugPrint('Push token unavailable; skipping backend registration.');
      return;
    }
    if (token == _registeredToken) return;

    try {
      final api = ref.read(notificationsApiProvider);
      await api.registerPushToken(token);
      _registeredToken = token;

      debugPrint("Push token saved to backend");
    } on DioException catch (e) {
      debugPrint(
        "Push token save failed: status=${e.response?.statusCode} data=${e.response?.data}",
      );
    } catch (e) {
      debugPrint("Push token save failed: $e");
    }
  }
}

// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'push_service.dart';
// import 'providers.dart';

// final pushControllerProvider = Provider<PushController>((ref) {
//   return PushController(ref);
// });

// class PushController {
//   PushController(this.ref);

//   final Ref ref;

//   Future<void> init() async {
//     final pushService = PushService();
//     final token = await pushService.init();

//     if (token == null || token.isEmpty) {
//       print('No FCM token received, skipping backend registration');
//       return;
//     }

//     try {
//       final api = ref.read(notificationsApiProvider);
//       await api.registerPushToken(token);
//       print('Push token saved to backend');
//     } catch (e) {
//       print('Push token save failed: $e');
//     }
//   }
// }
