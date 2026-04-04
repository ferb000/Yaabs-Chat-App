class AuthTokens {
  final String accessToken;
  final String refreshToken;
  AuthTokens({required this.accessToken, required this.refreshToken});

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
  );
}

class AppUser {
  final String id;
  final String email;
  final String? username;
  final String? avatarUrl;

  AppUser({
    required this.id,
    required this.email,
    this.username,
    this.avatarUrl,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String,
    email: json['email'] as String,
    username: json['username'] as String?,
    avatarUrl: json['avatarUrl'] as String? ?? json['avatar_url'] as String?,
  );
}
