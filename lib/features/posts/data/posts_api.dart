import 'package:dio/dio.dart';
import '../../../core/config/endpoints.dart';

class PostsApi {
  final Dio dio;
  PostsApi(this.dio);

  Future<Map<String, dynamic>> feed({String? cursor, int limit = 15}) async {
    final res = await dio.get(
      Endpoints.feed,
      queryParameters: {'limit': limit, if (cursor != null) 'cursor': cursor},
    );
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<void> like(String postId) => dio.post(Endpoints.like(postId));
  Future<void> unlike(String postId) => dio.delete(Endpoints.like(postId));

  Future<Map<String, dynamic>> createPost({
    String? caption,
    required List<Map<String, dynamic>> media,
  }) async {
    final res = await dio.post(
      Endpoints.posts,
      data: {if (caption != null) 'caption': caption, 'media': media},
    );
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> listComments(
    String postId, {
    String? cursor,
    int limit = 20,
  }) async {
    final res = await dio.get(
      Endpoints.comments(postId),
      queryParameters: {'limit': limit, if (cursor != null) 'cursor': cursor},
    );
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> createComment(String postId, String text) async {
    final res = await dio.post(
      Endpoints.comments(postId),
      data: {'text': text},
    );
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> deleteComment(String commentId) async {
    final res = await dio.delete('/comments/$commentId');
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<void> deletePost(String postId) =>
      dio.delete(Endpoints.deletePost(postId));

  Future<Map<String, dynamic>> userPosts(
    String userId, {
    String? cursor,
    int limit = 15,
  }) async {
    final res = await dio.get(
      Endpoints.userPosts(userId),
      queryParameters: {'limit': limit, if (cursor != null) 'cursor': cursor},
    );
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> editPostCaption(
    String postId,
    String caption,
  ) async {
    final res = await dio.patch('/posts/$postId', data: {'caption': caption});
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> getPost(String postId) async {
    final res = await dio.get('/posts/$postId');
    return (res.data as Map).cast<String, dynamic>();
  }
}
