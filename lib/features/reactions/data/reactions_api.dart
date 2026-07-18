import 'package:dio/dio.dart';

class ReactionsApi {
  final Dio dio;
  ReactionsApi(this.dio);

  Future<Map<String, dynamic>> toggle({
    required String targetType,
    required String targetId,
    required String reaction,
  }) async {
    final res = await dio.post(
      '/reactions/toggle',
      data: {
        'targetType': targetType,
        'targetId': targetId,
        'reaction': reaction,
      },
    );
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> remove({
    required String targetType,
    required String targetId,
  }) async {
    final res = await dio.delete(
      '/reactions',
      data: {'targetType': targetType, 'targetId': targetId},
    );
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> list({
    required String targetType,
    required String targetId,
  }) async {
    final res = await dio.get(
      '/reactions',
      queryParameters: {'targetType': targetType, 'targetId': targetId},
    );
    return (res.data as Map).cast<String, dynamic>();
  }
}
