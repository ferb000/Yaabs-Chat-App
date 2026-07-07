class PostAuthor {
  final String id;
  final String email;
  final String? username;
  final String? avatarUrl;

  PostAuthor({
    required this.id,
    required this.email,
    this.username,
    this.avatarUrl,
  });

  factory PostAuthor.fromJson(Map<String, dynamic> json) => PostAuthor(
    id: json['id'] as String,
    email: json['email'] as String,
    username: json['username'] as String?,
    avatarUrl: json['avatarUrl'] as String?,
  );
}

class PostMedia {
  final String id;
  final String url;
  final String mime;

  PostMedia({required this.id, required this.url, required this.mime});

  factory PostMedia.fromJson(Map<String, dynamic> json) => PostMedia(
    id: json['id'] as String,
    url: json['url'] as String,
    mime: json['mime'] as String,
  );

  Map<String, dynamic> toCreateJson() => {'url': url, 'mime': mime};
}

class Post {
  final String id;
  final String caption;
  final DateTime createdAt;
  final PostAuthor author;
  final List<PostMedia> media;
  final int likeCount;
  final int commentCount;
  final bool likedByMe;

  Post({
    required this.id,
    required this.caption,
    required this.createdAt,
    required this.author,
    required this.media,
    required this.likeCount,
    required this.commentCount,
    required this.likedByMe,
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
    id: json['id'] as String,
    caption: (json['caption'] as String?) ?? '',
    createdAt: DateTime.parse(json['created_at'] as String),
    author: PostAuthor.fromJson(
      (json['author'] as Map).cast<String, dynamic>(),
    ),
    media: ((json['media'] as List?) ?? [])
        .map((e) => PostMedia.fromJson((e as Map).cast<String, dynamic>()))
        .toList(),
    likeCount: (json['likeCount'] as num).toInt(),
    commentCount: (json['commentCount'] as num).toInt(),
    likedByMe: json['likedByMe'] as bool,
  );
}

class Comment {
  final String id;
  final String text;
  final DateTime createdAt;
  final PostAuthor author;

  Comment({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.author,
  });

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
    id: json['id'] as String,
    text: (json['text'] as String?) ?? '',
    createdAt: DateTime.parse(
      (json['created_at'] as String?) ?? (json['createdAt'] as String),
    ),
    author: _authorFromJson(json),
  );

  static PostAuthor _authorFromJson(Map<String, dynamic> json) {
    final rawAuthor = json['author'];
    if (rawAuthor is Map) {
      return PostAuthor.fromJson(rawAuthor.cast<String, dynamic>());
    }

    return PostAuthor(
      id: (json['user_id'] as String?) ?? (json['userId'] as String?) ?? '',
      email: (json['email'] as String?) ?? 'Unknown',
      username: json['username'] as String?,
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar_url'] as String?,
    );
  }
}
