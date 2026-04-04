import 'dart:async';
import 'package:dio/dio.dart';
import '../config/endpoints.dart';
import 'token_storage.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;
  final TokenStorage storage;

  bool _refreshing = false;
  final List<Future<void> Function()> _queued = [];

  AuthInterceptor({required this.dio, required this.storage});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final access = await storage.accessToken();
    if (access != null && options.headers['Authorization'] == null) {
      options.headers['Authorization'] = 'Bearer $access';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final is401 = err.response?.statusCode == 401;
    final isAuthRoute =
        err.requestOptions.path == Endpoints.login ||
        err.requestOptions.path == Endpoints.signup ||
        err.requestOptions.path == Endpoints.refresh;

    if (!is401 || isAuthRoute) {
      return handler.next(err);
    }

    // Queue requests while refreshing
    final completer = Completer<Response<dynamic>>();
    _queued.add(() async {
      try {
        final res = await dio.fetch(err.requestOptions);
        completer.complete(res);
      } catch (e) {
        completer.completeError(e);
      }
    });

    if (_refreshing) {
      try {
        final res = await completer.future;
        return handler.resolve(res);
      } catch (e) {
        return handler.next(e is DioException ? e : err);
      }
    }

    _refreshing = true;
    try {
      final refresh = await storage.refreshToken();
      if (refresh == null) {
        throw DioException(requestOptions: err.requestOptions);
      }

      final refreshRes = await dio.post(
        Endpoints.refresh,
        data: {'refreshToken': refresh},
      );
      final newAccess = refreshRes.data['accessToken'] as String;
      final newRefresh = refreshRes.data['refreshToken'] as String;
      await storage.saveTokens(access: newAccess, refresh: newRefresh);

      // retry queued
      for (final fn in List<Future<void> Function()>.from(_queued)) {
        await fn();
      }
      _queued.clear();

      final res = await completer.future;
      handler.resolve(res);
    } catch (e) {
      await storage.clear();
      _queued.clear();
      handler.next(err);
    } finally {
      _refreshing = false;
    }
  }
}
