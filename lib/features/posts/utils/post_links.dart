import '../../../core/config/env.dart';

class PostLinks {
  static String get baseUrl => Env.apiBaseUrl;

  static String postUrl(String postId) => '$baseUrl/posts/$postId';
}
