import 'package:dio/dio.dart';
import '../../../core/config/endpoints.dart';

class AuthApi {
  final Dio dio;
  AuthApi(this.dio);

  Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    String? username,
  }) async {
    final res = await dio.post(
      Endpoints.signup,
      data: {
        'email': email,
        'password': password,
        if (username != null) 'username': username,
      },
    );
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await dio.post(
      Endpoints.login,
      data: {'email': email, 'password': password},
    );
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> me() async {
    final res = await dio.get(Endpoints.me);
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<void> logout({required String refreshToken}) async {
    await dio.post(Endpoints.logout, data: {'refreshToken': refreshToken});
  }
}
