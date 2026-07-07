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

  Future<List<dynamic>> followers(
    String userId, {
    String? q,
    int limit = 50,
  }) async {
    final res = await dio.get(
      Endpoints.followers(userId),
      queryParameters: {
        'limit': limit,
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      },
    );
    return (res.data['items'] as List);
  }

  Future<List<dynamic>> following(
    String userId, {
    String? q,
    int limit = 50,
  }) async {
    final res = await dio.get(
      Endpoints.following(userId),
      queryParameters: {
        'limit': limit,
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      },
    );
    return (res.data['items'] as List);
  }

  Future<void> follow(String userId) =>
      dio.post(Endpoints.follow, data: {'userId': userId});
  Future<void> unfollow(String userId) =>
      dio.post(Endpoints.unfollow, data: {'userId': userId});
}
