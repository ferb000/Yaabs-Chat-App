import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../auth/state/auth_controller.dart';
import '../chat/ui/conversations_page.dart';
import '../posts/ui/feed_page.dart';
import '../users/ui/profile_page.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authControllerProvider.select((s) => s.user));
    final pages = <Widget>[
      const FeedPage(),
      const ConversationsPage(),
      if (me != null) ProfilePage(userId: me.id) else const SizedBox.shrink(),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: IndexedStack(
          index: _index.clamp(0, pages.length - 1),
          children: pages,
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: AppShadows.soft,
              border: Border.all(color: AppColors.border),
            ),
            child: NavigationBar(
              selectedIndex: _index.clamp(0, pages.length - 1),
              onDestinationSelected: (value) => setState(() => _index = value),
              backgroundColor: Colors.transparent,
              indicatorColor: AppColors.outgoing,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dynamic_feed_rounded),
                  label: 'Feeds',
                ),
                NavigationDestination(
                  icon: Icon(Icons.chat_bubble_rounded),
                  label: 'Chats',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
