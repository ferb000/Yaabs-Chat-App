// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// import 'features/auth/state/auth_controller.dart';
// import 'features/auth/ui/login_page.dart';
// import 'features/posts/ui/feed_page.dart';

// import 'features/notifications/notification_navigation_service.dart';

import 'features/notifications/notification_navigation_service.dart';
import 'features/chat/ui/chat_room_page.dart';
import 'features/posts/ui/post_loader_page.dart';
import 'features/auth/ui/login_page.dart';
import 'features/posts/ui/feed_page.dart';
import 'features/auth/state/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

// class App extends ConsumerStatefulWidget {
//   const App({super.key});

//   @override
//   ConsumerState<App> createState() => _AppState();
// }

// class _AppState extends ConsumerState<App> {
//   @override
//   void initState() {
//     super.initState();
//     Future.microtask(
//       () => ref.read(authControllerProvider.notifier).bootstrap(),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final auth = ref.watch(authControllerProvider);

//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: auth.user == null ? const LoginPage() : const FeedPage(),
//     );
//   }
// }

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(authControllerProvider.notifier).bootstrap(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: auth.user == null ? const LoginPage() : const FeedPage(),
      onGenerateRoute: (settings) {
        if (settings.name == '/chat') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => ChatRoomPage(
              conversationId: args['conversationId'] as String,
              title: 'Chat',
            ),
          );
        }

        if (settings.name == '/post') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => PostLoaderPage(postId: args['postId'] as String),
          );
        }

        return null;
      },
    );
  }
}
