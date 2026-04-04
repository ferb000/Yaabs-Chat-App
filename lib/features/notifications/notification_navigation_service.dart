import 'package:flutter/material.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class NotificationNavigationService {
  static void handleData(Map<String, dynamic> data) {
    final type = data['type'];

    if (type == 'chat_message') {
      final conversationId = data['conversationId'];
      if (conversationId == null) return;

      navigatorKey.currentState?.pushNamed(
        '/chat',
        arguments: {'conversationId': conversationId},
      );
      return;
    }

    if (type == 'post_comment' || type == 'post_like') {
      final postId = data['postId'];
      if (postId == null) return;

      navigatorKey.currentState?.pushNamed(
        '/post',
        arguments: {'postId': postId},
      );
      return;
    }
  }
}
