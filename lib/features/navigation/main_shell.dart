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
  final List<Widget?> _pages = List<Widget?>.filled(3, null);

  Widget _buildPage(int index, String? userId) {
    switch (index) {
      case 0:
        return const FeedPage();
      case 1:
        return const ConversationsPage();
      case 2:
        return userId != null
            ? ProfilePage(userId: userId)
            : const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authControllerProvider.select((s) => s.user));
    _pages[0] ??= _buildPage(0, me?.id);
    if (_index == 1 || _pages[1] != null) {
      _pages[1] ??= _buildPage(1, me?.id);
    }
    if (_index == 2 || _pages[2] != null) {
      _pages[2] ??= _buildPage(2, me?.id);
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: IndexedStack(
          index: _index.clamp(0, _pages.length - 1),
          children: _pages.map((p) => p ?? const SizedBox.shrink()).toList(),
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
              selectedIndex: _index.clamp(0, _pages.length - 1),
              onDestinationSelected: (value) {
                setState(() {
                  _index = value;
                  _pages[value] ??= _buildPage(value, me?.id);
                });
              },
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
