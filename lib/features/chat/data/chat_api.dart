import 'package:dio/dio.dart';
import '../../../core/config/endpoints.dart';

class ChatApi {
  final Dio dio;
  ChatApi(this.dio);

  Future<List<dynamic>> listConversations() async {
    final res = await dio.get(Endpoints.conversations);
    return (res.data['items'] as List);
  }

  Future<Map<String, dynamic>> listMessages(
    String conversationId, {
    String? cursor,
    int limit = 30,
  }) async {
    final res = await dio.get(
      Endpoints.messages(conversationId),
      queryParameters: {if (cursor != null) 'cursor': cursor, 'limit': limit},
    );
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> searchMessages(
    String conversationId, {
    String? query,
    String type = 'all',
    int limit = 30,
  }) async {
    final res = await dio.get(
      '${Endpoints.messages(conversationId)}/search',
      queryParameters: {
        'type': type,
        'limit': limit,
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      },
    );
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> getConversationDetail(
    String conversationId,
  ) async {
    final res = await dio.get('${Endpoints.conversations}/$conversationId');
    return (res.data as Map).cast<String, dynamic>();
  }

  //create new chat with user
  Future<Map<String, dynamic>> createDirect(String userId) async {
    final res = await dio.post(
      '${Endpoints.conversations}/direct',
      data: {'userId': userId},
    );
    return (res.data as Map).cast<String, dynamic>();
  }

  //create a new group with members
  Future<Map<String, dynamic>> createGroup({
    required String title,
    required List<String> memberIds,
  }) async {
    final res = await dio.post(
      '${Endpoints.conversations}/group',
      data: {'title': title, 'memberIds': memberIds},
    );
    return (res.data as Map).cast<String, dynamic>();
  }
}
