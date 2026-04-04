import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class NotificationsApi {
  final Dio dio;
  NotificationsApi(this.dio);

  Future<void> registerPushToken(String token) async {
    debugPrint(
      'Registering push token at ${dio.options.baseUrl}/notifications/tokens',
    );
    await dio.post('/notifications/tokens', data: {'token': token});
  }

  Future<void> removePushToken(String token) async {
    await dio.delete('/notifications/tokens', data: {'token': token});
  }
}
