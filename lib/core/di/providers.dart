import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../network/token_storage.dart';
import '../network/api_client.dart';
import '../realtime/socket_client.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  return ApiClient(storage);
});

final dioProvider = Provider<Dio>((ref) => ref.watch(apiClientProvider).dio);

final socketClientProvider = Provider<SocketClient>((ref) {
  final socket = SocketClient();
  ref.onDispose(socket.disconnect);
  return socket;
});
