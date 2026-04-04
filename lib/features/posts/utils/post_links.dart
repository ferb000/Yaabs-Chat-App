class PostLinks {
  static const baseUrl = 'https://localhost:3000';

  static String postUrl(String postId) => '$baseUrl/posts/$postId';
}
