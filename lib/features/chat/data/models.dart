import '../../reactions/data/reaction_models.dart';

class Conversation {
  final String id;
  final String type; // direct/group
  final String? title;
  final String? displayTitle;
  final String? displaySubtitle;
  final String? avatarUrl;
  final List<ConversationMember> members;

  Conversation({
    required this.id,
    required this.type,
    this.title,
    this.displayTitle,
    this.displaySubtitle,
    this.avatarUrl,
    this.members = const [],
  });

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    id: json['id'] as String,
    type: json['type'] as String,
    title: json['title'] as String?,
    displayTitle:
        json['displayTitle'] as String? ?? json['display_title'] as String?,
    displaySubtitle:
        json['displaySubtitle'] as String? ??
        json['display_subtitle'] as String?,
    avatarUrl: json['avatarUrl'] as String? ?? json['avatar_url'] as String?,
    members: ((json['members'] as List?) ?? const [])
        .map(
          (e) =>
              ConversationMember.fromJson((e as Map).cast<String, dynamic>()),
        )
        .toList(),
  );

  String get resolvedTitle =>
      displayTitle ??
      (type == 'group'
          ? (title?.trim().isNotEmpty == true ? title! : 'Group')
          : 'Direct chat');
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String type; // text/image/audio
  final String? text;
  final DateTime createdAt;
  final int reactionCount;
  final String? myReaction;
  final ReactionSummary reactionSummary;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.type,
    required this.text,
    required this.createdAt,
    this.reactionCount = 0,
    this.myReaction,
    this.reactionSummary = ReactionSummary.empty,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    conversationId:
        json['conversation_id'] as String? ?? json['conversationId'] as String,
    senderId: json['sender_id'] as String? ?? json['senderId'] as String,
    type: json['type'] as String,
    text: json['text'] as String?,
    createdAt: DateTime.parse(
      json['created_at'] as String? ?? json['createdAt'] as String,
    ),
    reactionCount: (json['reactionCount'] as num?)?.toInt() ?? 0,
    myReaction: json['myReaction'] as String?,
    reactionSummary: ReactionSummary.fromJson(json['reactionSummary']),
  );

  ChatMessage copyWith({
    int? reactionCount,
    Object? myReaction = _sentinel,
    ReactionSummary? reactionSummary,
  }) => ChatMessage(
    id: id,
    conversationId: conversationId,
    senderId: senderId,
    type: type,
    text: text,
    createdAt: createdAt,
    reactionCount: reactionCount ?? this.reactionCount,
    myReaction: identical(myReaction, _sentinel)
        ? this.myReaction
        : myReaction as String?,
    reactionSummary: reactionSummary ?? this.reactionSummary,
  );
}

class MessageMedia {
  final String url;
  final String mime;
  final int sizeBytes;
  final String mediaType; // image/audio
  final int? durationMs;

  MessageMedia({
    required this.url,
    required this.mime,
    required this.sizeBytes,
    required this.mediaType,
    this.durationMs,
  });

  Map<String, dynamic> toJson() => {
    'url': url,
    'mime': mime,
    'sizeBytes': sizeBytes,
    'mediaType': mediaType,
    if (durationMs != null) 'durationMs': durationMs,
  };
}

class ConversationMember {
  final String userId;
  final String role;
  final String email;
  final String? username;
  final String? avatarUrl;
  final String? lastReadMessageId;

  ConversationMember({
    required this.userId,
    required this.role,
    required this.email,
    this.username,
    this.avatarUrl,
    this.lastReadMessageId,
  });

  factory ConversationMember.fromJson(Map<String, dynamic> json) =>
      ConversationMember(
        userId: json['user_id'] as String? ?? json['userId'] as String,
        role: json['role'] as String? ?? 'member',
        email: json['email'] as String,
        username: json['username'] as String?,
        avatarUrl:
            json['avatar_url'] as String? ?? json['avatarUrl'] as String?,
        lastReadMessageId: json['last_read_message_id'] as String?,
      );

  String get displayName =>
      (username != null && username!.trim().isNotEmpty) ? username! : email;
}

const _sentinel = Object();
