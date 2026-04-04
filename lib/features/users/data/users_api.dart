import 'package:dio/dio.dart';
import '../../../core/config/endpoints.dart';

class UsersApi {
  final Dio dio;
  UsersApi(this.dio);

  Future<List<dynamic>> search(String q, {int limit = 20}) async {
    final res = await dio.get(
      Endpoints.usersSearch,
      queryParameters: {'q': q, 'limit': limit},
    );
    return (res.data['items'] as List);
  }

  Future<void> follow(String userId) =>
      dio.post(Endpoints.follow, data: {'userId': userId});
  Future<void> unfollow(String userId) =>
      dio.post(Endpoints.unfollow, data: {'userId': userId});
}
