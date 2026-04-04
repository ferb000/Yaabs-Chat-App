import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';
import '../data/chat_api.dart';
import '../data/models.dart';

final chatApiProvider = Provider<ChatApi>((ref) {
  final dio = ref.watch(dioProvider);
  return ChatApi(dio);
});

final conversationsControllerProvider =
    StateNotifierProvider<
      ConversationsController,
      AsyncValue<List<Conversation>>
    >((ref) => ConversationsController(ref));

class ConversationsController
    extends StateNotifier<AsyncValue<List<Conversation>>> {
  ConversationsController(this.ref) : super(const AsyncValue.loading());

  final Ref ref;

  Future<void> load() async {
    state = const AsyncValue.loading();
    final api = ref.read(chatApiProvider);
    try {
      final items = await api.listConversations();
      final convos = items
          .map((e) => Conversation.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
      state = AsyncValue.data(convos);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
