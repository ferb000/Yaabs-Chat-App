import 'package:dio/dio.dart';
import '../config/env.dart';
import 'token_storage.dart';
import 'auth_interceptor.dart';

class ApiClient {
  final Dio dio;

  ApiClient._(this.dio);

  factory ApiClient(TokenStorage storage) {
    final dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(AuthInterceptor(dio: dio, storage: storage));
    return ApiClient._(dio);
  }
}
