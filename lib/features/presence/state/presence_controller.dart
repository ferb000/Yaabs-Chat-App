import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';
import '../../../core/config/socket_events.dart';
// import 'package:dio/dio.dart';
import '../../../core/config/endpoints.dart';

class PresenceInfo {
  final bool isOnline;
  final DateTime? lastSeenAt;
  const PresenceInfo({required this.isOnline, this.lastSeenAt});

  PresenceInfo copyWith({bool? isOnline, DateTime? lastSeenAt}) => PresenceInfo(
    isOnline: isOnline ?? this.isOnline,
    lastSeenAt: lastSeenAt ?? this.lastSeenAt,
  );
}

final presenceControllerProvider =
    StateNotifierProvider<PresenceController, Map<String, PresenceInfo>>((ref) {
      return PresenceController(ref);
    });

class PresenceController extends StateNotifier<Map<String, PresenceInfo>> {
  PresenceController(this.ref) : super({}) {
    final socket = ref.read(socketClientProvider).socket;

    socket.on(SocketEvents.presenceOnline, (data) {
      final m = (data as Map).cast<String, dynamic>();
      final userId = m['userId'] as String;
      state = {
        ...state,
        userId: (state[userId] ?? const PresenceInfo(isOnline: false)).copyWith(
          isOnline: true,
        ),
      };
    });

    socket.on(SocketEvents.presenceOffline, (data) {
      final m = (data as Map).cast<String, dynamic>();
      final userId = m['userId'] as String;
      final at = DateTime.tryParse((m['at'] as String?) ?? '');
      state = {
        ...state,
        userId: (state[userId] ?? const PresenceInfo(isOnline: false)).copyWith(
          isOnline: false,
          lastSeenAt: at,
        ),
      };
    });
  }

  final Ref ref;

  Future<void> hydrateFromApi(String userId) async {
    final dio = ref.read(dioProvider);
    final res = await dio.get(
      Endpoints.followCounts(userId).replaceAll('/follow-counts', '/presence'),
    ); // safer: just build /users/:id/presence below if you have it.
  }

  Future<void> fetchPresence(String userId) async {
    final dio = ref.read(dioProvider);
    final res = await dio.get('/users/$userId/presence');
    final data = (res.data as Map).cast<String, dynamic>();

    final isOnline = data['isOnline'] as bool? ?? false;
    final lastSeen = data['lastSeenAt'] != null
        ? DateTime.tryParse(data['lastSeenAt'])
        : null;

    state = {
      ...state,
      userId: PresenceInfo(isOnline: isOnline, lastSeenAt: lastSeen),
    };
  }
}
