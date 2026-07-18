import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
// import '../data/chat_api.dart';
import '../realtime/chat_socket.dart';
import 'conversations_controller.dart';
import '../../presence/state/presence_controller.dart';
import '../../reactions/data/reaction_models.dart';
import '../../reactions/state/reactions_provider.dart';

import '../../auth/state/auth_controller.dart'; // for my userId

// class ChatRoomState {
//   final List<ChatMessage> messages; // newest last (UI friendly)
//   final String? nextCursor;
//   final bool isLoadingMore;
//   final Set<String> typingUsers;

//   ChatRoomState({
//     required this.messages,
//     this.nextCursor,
//     this.isLoadingMore = false,
//     Set<String>? typingUsers,
//   }) : typingUsers = typingUsers ?? {};
//   ChatRoomState copyWith({
//     List<ChatMessage>? messages,
//     String? nextCursor,
//     bool? isLoadingMore,
//   }) => ChatRoomState(
//     messages: messages ?? this.messages,
//     nextCursor: nextCursor ?? this.nextCursor,
//     isLoadingMore: isLoadingMore ?? this.isLoadingMore,
//   );
// }

class ChatRoomState {
  final List<ChatMessage> messages;
  final String? nextCursor;
  final bool isLoadingMore;

  final List<ConversationMember> members;
  final Map<String, String?> memberLastRead;
  final Set<String> typingUsers;

  // NEW:
  final Map<String, MessageMedia> mediaByMessageId;
  final List<ChatMessage> searchResults;
  final bool isSearching;
  final String? searchError;
  final String? highlightedMessageId;

  ChatRoomState({
    required this.messages,
    this.nextCursor,
    this.isLoadingMore = false,
    List<ConversationMember>? members,
    Map<String, String?>? memberLastRead,
    Set<String>? typingUsers,
    Map<String, MessageMedia>? mediaByMessageId,
    List<ChatMessage>? searchResults,
    this.isSearching = false,
    this.searchError,
    this.highlightedMessageId,
  }) : members = members ?? const [],
       memberLastRead = memberLastRead ?? const {},
       typingUsers = typingUsers ?? <String>{},
       mediaByMessageId = mediaByMessageId ?? const {},
       searchResults = searchResults ?? const [];

  ChatRoomState copyWith({
    List<ChatMessage>? messages,
    String? nextCursor,
    bool? isLoadingMore,
    List<ConversationMember>? members,
    Map<String, String?>? memberLastRead,
    Set<String>? typingUsers,
    Map<String, MessageMedia>? mediaByMessageId,
    List<ChatMessage>? searchResults,
    bool? isSearching,
    Object? searchError = _sentinel,
    Object? highlightedMessageId = _sentinel,
  }) => ChatRoomState(
    messages: messages ?? this.messages,
    nextCursor: nextCursor ?? this.nextCursor,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    members: members ?? this.members,
    memberLastRead: memberLastRead ?? this.memberLastRead,
    typingUsers: typingUsers ?? this.typingUsers,
    mediaByMessageId: mediaByMessageId ?? this.mediaByMessageId,
    searchResults: searchResults ?? this.searchResults,
    isSearching: isSearching ?? this.isSearching,
    searchError: identical(searchError, _sentinel)
        ? this.searchError
        : searchError as String?,
    highlightedMessageId: identical(highlightedMessageId, _sentinel)
        ? this.highlightedMessageId
        : highlightedMessageId as String?,
  );
}

// final chatRoomControllerProvider =
//     StateNotifierProvider.family<ChatRoomController, ChatRoomState, String>(
//       (ref, conversationId) => ChatRoomController(ref, conversationId),
//     );

// class ChatRoomController extends StateNotifier<ChatRoomState> {
//   ChatRoomController(this.ref, this.conversationId)
//     : super(ChatRoomState(messages: [])) {
//     _sub = ref.read(chatSocketProvider).onNewMessage().listen(_handleIncoming);
//     loadInitial();
//   }

//   final Ref ref;
//   final String conversationId;
//   StreamSubscription<ChatMessage>? _sub;

//   @override
//   void dispose() {
//     _sub?.cancel();
//     super.dispose();
//   }

//   void _handleIncoming(ChatMessage msg) {
//     if (msg.conversationId != conversationId) return;
//     state = state.copyWith(messages: [...state.messages, msg]);
//   }

//   Future<void> loadInitial() async {
//     final api = ref.read(chatApiProvider);
//     final res = await api.listMessages(conversationId, limit: 30);
//     final items = (res['items'] as List)
//         .map((e) => ChatMessage.fromJson((e as Map).cast<String, dynamic>()))
//         .toList();

//     // backend returns newest-first; convert to oldest-first for chat UI
//     final ordered = items.reversed.toList();
//     state = state.copyWith(
//       messages: ordered,
//       nextCursor: res['nextCursor'] as String?,
//     );
//   }

//   Future<void> loadMore() async {
//     if (state.isLoadingMore) return;
//     final cursor = state.nextCursor;
//     if (cursor == null) return;

//     state = state.copyWith(isLoadingMore: true);

//     final api = ref.read(chatApiProvider);
//     final res = await api.listMessages(
//       conversationId,
//       cursor: cursor,
//       limit: 30,
//     );
//     final items = (res['items'] as List)
//         .map((e) => ChatMessage.fromJson((e as Map).cast<String, dynamic>()))
//         .toList();

//     final older = items.reversed.toList();
//     state = state.copyWith(
//       isLoadingMore: false,
//       messages: [...older, ...state.messages],
//       nextCursor: res['nextCursor'] as String?,
//     );
//   }

//   Future<void> sendText(String text) async {
//     final socket = ref.read(chatSocketProvider);
//     await socket.send(conversationId: conversationId, type: 'text', text: text);
//     // message will arrive via message:new broadcast
//   }

//   Future<void> sendMedia(MessageMedia media) async {
//     final socket = ref.read(chatSocketProvider);
//     await socket.send(
//       conversationId: conversationId,
//       type: media.mediaType, // "image" or "audio"
//       media: media.toJson(),
//     );
//   }
// }

final chatRoomControllerProvider =
    StateNotifierProvider.family<ChatRoomController, ChatRoomState, String>(
      (ref, conversationId) => ChatRoomController(ref, conversationId),
    );

class ChatRoomController extends StateNotifier<ChatRoomState> {
  // ChatRoomController(this.ref, this.conversationId)
  //   : super(ChatRoomState(messages: [])) {
  //   final sock = ref.read(chatSocketProvider);

  //   _subNewMsg = sock.onNewMessageRaw().listen(_handleIncomingRaw);
  //   _subTypingStart = sock.onTypingStart().listen(_handleTypingStart);
  //   _subTypingStop = sock.onTypingStop().listen(_handleTypingStop);
  //   _subRead = sock.onMessageRead().listen(_handleMessageRead);

  //   loadInitial();
  // }
  ChatRoomController(this.ref, this.conversationId)
    : super(ChatRoomState(messages: [])) {
    final sock = ref.read(chatSocketProvider);

    _subNewMsg = sock.onNewMessageRaw.listen(_handleIncomingRaw);
    _subTypingStart = sock.onTypingStart.listen(_handleTypingStart);
    _subTypingStop = sock.onTypingStop.listen(_handleTypingStop);
    _subRead = sock.onMessageRead.listen(_handleMessageRead);

    Future.microtask(() async {
      await _loadConversationMembers();
      await loadInitial();
    });
  }

  final Ref ref;
  final String conversationId;

  StreamSubscription<Map<String, dynamic>>? _subNewMsg;
  StreamSubscription<Map<String, dynamic>>? _subTypingStart;
  StreamSubscription<Map<String, dynamic>>? _subTypingStop;
  StreamSubscription<Map<String, dynamic>>? _subRead;

  Timer? _typingStopTimer;
  bool _typingSent = false;

  String? get myUserId => ref.read(authControllerProvider).user?.id;

  @override
  void dispose() {
    _subNewMsg?.cancel();
    _subTypingStart?.cancel();
    _subTypingStop?.cancel();
    _subRead?.cancel();
    _typingStopTimer?.cancel();
    super.dispose();
  }

  // ---------- Typing (called by UI on every text change) ----------
  void onTextChanged(String text) {
    final sock = ref.read(chatSocketProvider);

    // If user is typing and we haven't signaled start yet
    if (text.trim().isNotEmpty && !_typingSent) {
      _typingSent = true;
      sock.typingStart(conversationId);
    }

    // Debounce stop: if no typing for 900ms, send stop
    _typingStopTimer?.cancel();
    _typingStopTimer = Timer(const Duration(milliseconds: 900), () {
      if (_typingSent) {
        _typingSent = false;
        sock.typingStop(conversationId);
      }
    });

    // If user cleared input, stop immediately
    if (text.trim().isEmpty && _typingSent) {
      _typingStopTimer?.cancel();
      _typingSent = false;
      sock.typingStop(conversationId);
    }
  }

  // ---------- Message handlers ----------
  // void _handleIncomingRaw(Map<String, dynamic> data) {
  //   final msgJson = (data['message'] as Map).cast<String, dynamic>();
  //   final msg = ChatMessage.fromJson(msgJson);

  //   if (msg.conversationId != conversationId) return;

  //   state = state.copyWith(messages: [...state.messages, msg]);

  //   // mark as read (best effort)
  //   _markRead(msg.id);
  // }

  void _handleIncomingRaw(Map<String, dynamic> data) {
    final msgRaw = data['message'];
    if (msgRaw is! Map) return;
    final msg = ChatMessage.fromJson(msgRaw.cast<String, dynamic>());
    _upsertIncomingMessage(msg, data['media']);
    _markRead(msg.id);
  }

  void _handleTypingStart(Map<String, dynamic> data) {
    final cid = data['conversationId'] as String?;
    final userId = data['userId'] as String?;
    if (cid != conversationId || userId == null) return;
    if (userId == myUserId) return; // ignore self

    final updated = {...state.typingUsers}..add(userId);
    state = state.copyWith(typingUsers: updated);
  }

  void _handleTypingStop(Map<String, dynamic> data) {
    final cid = data['conversationId'] as String?;
    final userId = data['userId'] as String?;
    if (cid != conversationId || userId == null) return;
    if (userId == myUserId) return;

    final updated = {...state.typingUsers}..remove(userId);
    state = state.copyWith(typingUsers: updated);
  }

  void _handleMessageRead(Map<String, dynamic> data) {
    final cid = data['conversationId'] as String?;
    final userId = data['userId'] as String?;
    final messageId = data['messageId'] as String?;
    if (cid != conversationId || userId == null || messageId == null) return;

    final updated = Map<String, String?>.from(state.memberLastRead);
    updated[userId] = messageId;

    state = state.copyWith(memberLastRead: updated);
  }

  // ---------- History ----------
  // Future<void> loadInitial() async {
  //   final api = ref.read(chatApiProvider);
  //   final res = await api.listMessages(conversationId, limit: 30);

  //   final items = (res['items'] as List)
  //       .map((e) => ChatMessage.fromJson((e as Map).cast<String, dynamic>()))
  //       .toList();

  //   final ordered = items.reversed.toList(); // oldest->newest
  //   state = state.copyWith(
  //     messages: ordered,
  //     nextCursor: res['nextCursor'] as String?,
  //   );

  //   // mark latest as read
  //   if (state.messages.isNotEmpty) {
  //     _markRead(state.messages.last.id);
  //   }
  // }

  Future<void> loadInitial() async {
    final api = ref.read(chatApiProvider);
    final res = await api.listMessages(conversationId, limit: 30);

    final rawItems = (res['items'] as List)
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();

    // messages from backend are newest-first, convert to oldest-first
    final parsed = rawItems.map((item) => ChatMessage.fromJson(item)).toList();
    final ordered = parsed.reversed.toList();

    final mediaMap = Map<String, MessageMedia>.from(state.mediaByMessageId);

    // merge media from each raw item (use the same item->msg mapping)
    for (final item in rawItems) {
      final msg = ChatMessage.fromJson(item);
      _mergeMediaFromItem(item, msg, mediaMap);
    }

    state = state.copyWith(
      messages: ordered,
      nextCursor: res['nextCursor'] as String?,
      mediaByMessageId: mediaMap,
    );

    if (state.messages.isNotEmpty) {
      _markRead(state.messages.last.id);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore) return;
    final cursor = state.nextCursor;
    if (cursor == null) return;

    state = state.copyWith(isLoadingMore: true);

    final api = ref.read(chatApiProvider);
    final res = await api.listMessages(
      conversationId,
      cursor: cursor,
      limit: 30,
    );

    // final items = (res['items'] as List)
    //     .map((e) => ChatMessage.fromJson((e as Map).cast<String, dynamic>()))
    //     .toList();

    // final older = items.reversed.toList();
    // state = state.copyWith(
    //   isLoadingMore: false,
    //   messages: [...older, ...state.messages],
    //   nextCursor: res['nextCursor'] as String?,
    // );
    final rawItems = (res['items'] as List)
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();

    final parsed = rawItems.map((item) => ChatMessage.fromJson(item)).toList();
    final older = parsed.reversed.toList();

    final mediaMap = Map<String, MessageMedia>.from(state.mediaByMessageId);
    for (final item in rawItems) {
      final msg = ChatMessage.fromJson(item);
      _mergeMediaFromItem(item, msg, mediaMap);
    }

    state = state.copyWith(
      isLoadingMore: false,
      messages: [...older, ...state.messages],
      nextCursor: res['nextCursor'] as String?,
      mediaByMessageId: mediaMap,
    );
  }

  // ---------- Sending ----------
  Future<void> sendText(String text) async {
    final sock = ref.read(chatSocketProvider);
    final ack = await sock.send(
      conversationId: conversationId,
      type: 'text',
      text: text,
    );
    _ingestAckAsMessage(ack);

    // stop typing when sent
    if (_typingSent) {
      _typingStopTimer?.cancel();
      _typingSent = false;
      sock.typingStop(conversationId);
    }
  }

  Future<void> sendMedia(MessageMedia media) async {
    final sock = ref.read(chatSocketProvider);
    final ack = await sock.send(
      conversationId: conversationId,
      type: media.mediaType,
      media: media.toJson(),
    );
    _ingestAckAsMessage(ack);
  }

  Future<void> toggleReaction(ChatMessage message, String reaction) async {
    final previous = state;
    final previousReaction = message.myReaction;
    final optimisticSummary = message.reactionSummary.applyToggle(
      previousReaction: previousReaction,
      reaction: reaction,
    );
    final optimisticMyReaction = previousReaction == reaction ? null : reaction;

    state = state.copyWith(
      messages: state.messages.map((m) {
        if (m.id != message.id) return m;
        return m.copyWith(
          reactionCount: optimisticSummary.total,
          myReaction: optimisticMyReaction,
          reactionSummary: optimisticSummary,
        );
      }).toList(),
    );

    try {
      final res = await ref.read(reactionsApiProvider).toggle(
        targetType: 'message',
        targetId: message.id,
        reaction: reaction,
      );
      final summary = ReactionSummary.fromJson(res['reactionSummary']);
      state = state.copyWith(
        messages: state.messages.map((m) {
          if (m.id != message.id) return m;
          return m.copyWith(
            reactionCount: summary.total,
            myReaction: res['myReaction'] as String?,
            reactionSummary: summary,
          );
        }).toList(),
      );
    } catch (_) {
      state = previous;
    }
  }

  Future<void> searchMessages({String? query, String type = 'all'}) async {
    final clean = query?.trim();
    if ((clean == null || clean.isEmpty) && type == 'all') {
      state = state.copyWith(searchResults: [], searchError: null);
      return;
    }

    state = state.copyWith(isSearching: true, searchError: null);

    try {
      final api = ref.read(chatApiProvider);
      final res = await api.searchMessages(
        conversationId,
        query: clean,
        type: type,
        limit: 30,
      );

      final rawItems = (res['items'] as List)
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();
      final results = rawItems.map(ChatMessage.fromJson).toList();
      final mediaMap = Map<String, MessageMedia>.from(state.mediaByMessageId);
      for (final item in rawItems) {
        final msg = ChatMessage.fromJson(item);
        _mergeMediaFromItem(item, msg, mediaMap);
      }

      state = state.copyWith(
        isSearching: false,
        searchResults: results,
        mediaByMessageId: mediaMap,
      );
    } catch (e) {
      state = state.copyWith(isSearching: false, searchError: e.toString());
    }
  }

  void clearSearch() {
    state = state.copyWith(
      searchResults: [],
      searchError: null,
      highlightedMessageId: null,
    );
  }

  void focusSearchResult(ChatMessage message) {
    final existing = state.messages.any((m) => m.id == message.id);
    final nextMessages = existing
        ? state.messages
        : ([...state.messages, message]
              ..sort((a, b) => a.createdAt.compareTo(b.createdAt)));

    state = state.copyWith(
      messages: nextMessages,
      highlightedMessageId: message.id,
    );

    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (state.highlightedMessageId == message.id) {
        state = state.copyWith(highlightedMessageId: null);
      }
    });
  }

  Future<void> _markRead(String messageId) async {
    final sock = ref.read(chatSocketProvider);
    try {
      await sock.messageRead(conversationId, messageId);
    } catch (_) {}

    final me = myUserId;
    if (me != null) {
      final updated = Map<String, String?>.from(state.memberLastRead);
      updated[me] = messageId;
      state = state.copyWith(memberLastRead: updated);
    }
  }

  Future<void> _loadConversationMembers() async {
    final api = ref.read(chatApiProvider);
    final res = await api.getConversationDetail(conversationId);

    final membersJson = (res['members'] as List)
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();

    final members = membersJson
        .map((m) => ConversationMember.fromJson(m))
        .toList();

    final map = <String, String?>{};
    for (final m in members) {
      map[m.userId] = m.lastReadMessageId;
    }

    state = state.copyWith(members: members, memberLastRead: map);

    final other = otherUserId;
    if (other != null) {
      await ref.read(presenceControllerProvider.notifier).fetchPresence(other);
    }
  }

  // String? get myUserId => ref.read(authControllerProvider).user?.id;

  String? get otherUserId {
    if (state.members.length != 2) return null;
    final me = myUserId;
    if (me == null) return null;
    return state.members
        .firstWhere((m) => m.userId != me, orElse: () => state.members.first)
        .userId;
  }

  bool isReadBy(String userId, String messageId) {
    final lastReadId = state.memberLastRead[userId];
    if (lastReadId == null) return false;

    // Compare using message order indexes
    final index = <String, int>{};
    for (var i = 0; i < state.messages.length; i++) {
      index[state.messages[i].id] = i;
    }

    final msgIdx = index[messageId];
    final readIdx = index[lastReadId];
    if (msgIdx == null || readIdx == null) {
      // If we don't have the lastRead message in memory, assume not read (safe)
      return false;
    }
    return readIdx >= msgIdx;
  }

  int readByCount(String messageId) {
    final me = myUserId;
    if (me == null) return 0;

    int count = 0;
    for (final m in state.members) {
      if (m.userId == me) continue;
      if (isReadBy(m.userId, messageId)) count++;
    }
    return count;
  }

  List<String> readByNames(String messageId) {
    final me = myUserId;
    if (me == null) return [];
    final names = <String>[];
    for (final m in state.members) {
      if (m.userId == me) continue;
      if (isReadBy(m.userId, messageId)) names.add(m.displayName);
    }
    return names;
  }

  void _mergeMediaFromItem(
    Map<String, dynamic> item,
    ChatMessage msg,
    Map<String, MessageMedia> mediaMap,
  ) {
    final media = item['media'];
    if (media is! Map) return;

    final m = (media).cast<String, dynamic>();

    final url = m['url'] as String?;
    final mime = m['mime'] as String?;
    final mediaType = (m['media_type'] as String?) ?? msg.type;
    final sizeBytesRaw = m['size_bytes'];
    final durationRaw = m['duration_ms'];

    if (url == null || mime == null) return;

    mediaMap[msg.id] = MessageMedia(
      url: url,
      mime: mime,
      sizeBytes: (sizeBytesRaw is num) ? sizeBytesRaw.toInt() : 0,
      mediaType: mediaType,
      durationMs: (durationRaw is num) ? durationRaw.toInt() : null,
    );
  }

  void _ingestAckAsMessage(Map<String, dynamic> ack) {
    final msgRaw = ack['message'];
    if (msgRaw is! Map) return;
    final msg = ChatMessage.fromJson(msgRaw.cast<String, dynamic>());
    _upsertIncomingMessage(msg, ack['media']);
  }

  void _upsertIncomingMessage(ChatMessage msg, Object? mediaJson) {
    if (msg.conversationId != conversationId) return;
    if (!state.messages.any((m) => m.id == msg.id)) {
      state = state.copyWith(messages: [...state.messages, msg]);
    }

    if (mediaJson is! Map) return;
    final m = mediaJson.cast<String, dynamic>();
    final url = m['url'] as String?;
    final mime = m['mime'] as String?;
    final mediaType = (m['media_type'] as String?) ?? msg.type;
    final sizeBytesRaw = m['size_bytes'];
    final durationRaw = m['duration_ms'];

    if (url == null || mime == null) return;

    final updated = Map<String, MessageMedia>.from(state.mediaByMessageId);
    updated[msg.id] = MessageMedia(
      url: url,
      mime: mime,
      sizeBytes: (sizeBytesRaw is num) ? sizeBytesRaw.toInt() : 0,
      mediaType: mediaType,
      durationMs: (durationRaw is num) ? durationRaw.toInt() : null,
    );
    state = state.copyWith(mediaByMessageId: updated);
  }
}

const _sentinel = Object();
