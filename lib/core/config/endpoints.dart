class Endpoints {
  static const signup = '/auth/signup';
  static const login = '/auth/login';
  static const refresh = '/auth/refresh';
  static const logout = '/auth/logout';
  static const me = '/me';

  static const conversations = '/conversations';
  static String messages(String conversationId) =>
      '/conversations/$conversationId/messages';

  static const mediaUpload = '/media/upload';

  static const posts = '/posts';
  static const feed = '/posts/feed';
  static String postById(String id) => '/posts/$id';
  static String like(String id) => '/posts/$id/like';
  static String comments(String postId) => '/posts/$postId/comments';

  static const follow = '/follow';
  static const unfollow = '/unfollow';
  static String followCounts(String userId) => '/users/$userId/follow-counts';
  static const usersSearch = '/users/search';

  static String deletePost(String id) => '/posts/$id';
  static String userPosts(String userId) => '/posts/user/$userId';
  static String userProfile(String userId) => '/users/$userId';
}
