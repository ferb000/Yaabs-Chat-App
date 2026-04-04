import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../core/di/providers.dart';
import '../../../core/network/token_storage.dart';
import '../../../core/realtime/socket_client.dart';
import '../../notifications/push_controller.dart';
import '../data/auth_api.dart';
import '../data/models.dart';

class AuthState {
  final bool isLoading;
  final AppUser? user;
  final String? error;

  const AuthState({this.isLoading = false, this.user, this.error});

  AuthState copyWith({bool? isLoading, AppUser? user, String? error}) =>
      AuthState(
        isLoading: isLoading ?? this.isLoading,
        user: user ?? this.user,
        error: error,
      );
}

final authApiProvider = Provider<AuthApi>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthApi(dio);
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(
      ref: ref,
      api: ref.watch(authApiProvider),
      storage: ref.watch(tokenStorageProvider),
      socket: ref.watch(socketClientProvider),
    );
  },
);

class AuthController extends StateNotifier<AuthState> {
  AuthController({
    required this.ref,
    required this.api,
    required this.storage,
    required this.socket,
  }) : super(const AuthState());

  final Ref ref;
  final AuthApi api;
  final TokenStorage storage;
  final SocketClient socket;

  Future<void> bootstrap() async {
    // On app start: if access token exists, try /me (auto refresh handled by interceptor)
    state = state.copyWith(isLoading: true, error: null);
    try {
      final access = await storage.accessToken();
      if (access == null) {
        state = state.copyWith(isLoading: false, user: null);
        return;
      }
      final meRes = await api.me();

      final userJson = (meRes['user'] as Map).cast<String, dynamic>();
      final user = AppUser.fromJson(userJson);

      await socket.connect(accessToken: access);

      state = state.copyWith(isLoading: false, user: user);
      await ref.read(pushControllerProvider).init();
    } catch (e) {
      await storage.clear();
      socket.disconnect();
      state = state.copyWith(isLoading: false, user: null, error: e.toString());
    }
  }

  Future<void> signup(String email, String password, {String? username}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await api.signup(
        email: email,
        password: password,
        username: username,
      );
      await _persistAuthResponse(res);
      await ref.read(pushControllerProvider).init();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _dioMsg(e));
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await api.login(email: email, password: password);
      await _persistAuthResponse(res);
      await ref.read(pushControllerProvider).init();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _dioMsg(e));
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final refresh = await storage.refreshToken();
      if (refresh != null) {
        await api.logout(refreshToken: refresh);
      }
    } catch (_) {
      // even if API logout fails, clear locally
    } finally {
      await storage.clear();
      socket.disconnect();
      state = state.copyWith(isLoading: false, user: null);
    }
  }

  Future<void> _persistAuthResponse(Map<String, dynamic> res) async {
    final tokens = AuthTokens.fromJson(res);
    await storage.saveTokens(
      access: tokens.accessToken,
      refresh: tokens.refreshToken,
    );

    // fetch user (or use returned user if present)
    final meRes = await api.me();
    final userJson = (meRes['user'] as Map).cast<String, dynamic>();
    final user = AppUser.fromJson(userJson);

    await socket.connect(accessToken: tokens.accessToken);

    state = state.copyWith(user: user);
  }

  String _dioMsg(Object e) {
    if (e is DioException) {
      return e.response?.data is Map
          ? ((e.response?.data['message'])?.toString() ?? e.message ?? 'Error')
          : (e.message ?? 'Error');
    }
    return e.toString();
  }
}
