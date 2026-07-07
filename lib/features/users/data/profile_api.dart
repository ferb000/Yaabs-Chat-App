import 'package:dio/dio.dart';
import '../../../core/config/endpoints.dart';

class ProfileApi {
  final Dio dio;
  ProfileApi(this.dio);

  Future<Map<String, dynamic>> getProfile(String userId) async {
    final res = await dio.get(Endpoints.userProfile(userId));
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> updateAvatar(String avatarUrl) async {
    final res = await dio.patch(
      Endpoints.meAvatar,
      data: {'avatarUrl': avatarUrl},
    );
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<void> follow(String userId) =>
      dio.post(Endpoints.follow, data: {'userId': userId});
  Future<void> unfollow(String userId) =>
      dio.post(Endpoints.unfollow, data: {'userId': userId});
}
