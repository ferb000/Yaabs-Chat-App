import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import 'notifications_api.dart';

final notificationsApiProvider = Provider<NotificationsApi>((ref) {
  final dio = ref.watch(dioProvider);
  return NotificationsApi(dio);
});
