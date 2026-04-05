import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_event.dart';
import '../../features/auth/bloc/auth_state.dart';
import '../../features/notifications/bloc/notification_bloc.dart';
import '../../features/notifications/bloc/notification_event_state.dart';
import '../../core/utils/responsive.dart';

class DashboardScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  /// Hide bottom nav on sub-screens (detail pages, etc.)
  final bool showBottomNav;

  const DashboardScaffold({
    super.key,
    required this.title,
    required this.body,
    this.showBottomNav = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = Responsive.isMobile(context);
    final authState = context.watch<AuthBloc>().state;
    final userEmail = authState is AuthAuthenticated
        ? authState.user.email
        : '';
    final userRole = authState is AuthAuthenticated
        ? authState.user.role
        : '';

    final navItems = _navItemsForRole(userRole);
    final currentPath = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _selectedIndex(navItems, currentPath);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: isMobile
              ? theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)
              : null,
        ),
        leading: isMobile
            ? Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu),
                  tooltip: 'Меню',
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              )
            : null,
        actions: [
          if (!isMobile)
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Поиск',
              onPressed: () => context.push('/search'),
            ),
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, nState) {
              final unread =
                  nState is NotificationLoaded ? nState.unreadCount : 0;
              return IconButton(
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text('$unread'),
                  child: const Icon(Icons.notifications_outlined),
                ),
                tooltip: 'Уведомления',
                onPressed: () => context.push('/notifications'),
              );
            },
          ),
          if (!isMobile)
            IconButton(
              icon: const Icon(Icons.person_outlined),
              tooltip: 'Профиль',
              onPressed: () => context.push('/profile'),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') {
                context.read<AuthBloc>().add(AuthLogoutRequested());
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text(userEmail,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text('Выйти'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: isMobile ? _buildDrawer(context, theme, navItems, userEmail, userRole) : null,
      body: body,
      bottomNavigationBar:
          isMobile && showBottomNav && navItems.length >= 2
              ? NavigationBar(
                  selectedIndex: selectedIndex.clamp(0, navItems.length - 1),
                  onDestinationSelected: (i) {
                    if (i < navItems.length) {
                      context.go(navItems[i].route);
                    }
                  },
                  labelBehavior:
                      NavigationDestinationLabelBehavior.alwaysShow,
                  height: 64,
                  destinations: navItems
                      .map((item) => NavigationDestination(
                            icon: Icon(item.icon),
                            selectedIcon: Icon(item.selectedIcon),
                            label: item.label,
                          ))
                      .toList(),
                )
              : null,
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    ThemeData theme,
    List<_NavItem> navItems,
    String userEmail,
    String userRole,
  ) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primary,
                    child: Icon(Icons.person, color: theme.colorScheme.onPrimary, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(userEmail,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_roleLabel(userRole),
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ...navItems.map((item) => ListTile(
                        leading: Icon(item.icon),
                        title: Text(item.label),
                        onTap: () {
                          Navigator.pop(context);
                          context.go(item.route);
                        },
                      )),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.search),
                    title: const Text('Поиск'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/search');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_outlined),
                    title: const Text('Профиль'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/profile');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: const Text('Уведомления'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/notifications');
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Выйти',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                context.read<AuthBloc>().add(AuthLogoutRequested());
              },
            ),
          ],
        ),
      ),
    );
  }

  static List<_NavItem> _navItemsForRole(String role) {
    switch (role) {
      case 'student':
        return const [
          _NavItem(Icons.dashboard_outlined, Icons.dashboard, 'Главная', '/dashboard'),
          _NavItem(Icons.description_outlined, Icons.description, 'Дипломы', '/student/diplomas'),
          _NavItem(Icons.upload_file_outlined, Icons.upload_file, 'Загрузить', '/student/upload'),
          _NavItem(Icons.chat_outlined, Icons.chat, 'Чат', '/student/chats'),
        ];
      case 'employer':
        return const [
          _NavItem(Icons.dashboard_outlined, Icons.dashboard, 'Главная', '/dashboard'),
          _NavItem(Icons.search, Icons.search, 'Проверка', '/employer/verify'),
          _NavItem(Icons.people_outlined, Icons.people, 'Сотрудники', '/employer/employees'),
          _NavItem(Icons.history, Icons.history, 'История', '/employer/history'),
        ];
      case 'university':
        return const [
          _NavItem(Icons.dashboard_outlined, Icons.dashboard, 'Главная', '/dashboard'),
          _NavItem(Icons.list_alt, Icons.list_alt, 'Реестр', '/university/registry'),
          _NavItem(Icons.upload_file_outlined, Icons.upload_file, 'Добавить', '/university/diploma-upload'),
          _NavItem(Icons.card_membership_outlined, Icons.card_membership, 'Серт-ты', '/university/certificates'),
        ];
      case 'admin':
        return const [
          _NavItem(Icons.dashboard_outlined, Icons.dashboard, 'Главная', '/dashboard'),
          _NavItem(Icons.people_outlined, Icons.people, 'Польз-ли', '/admin/users'),
          _NavItem(Icons.description_outlined, Icons.description, 'Дипломы', '/admin/diplomas'),
          _NavItem(Icons.monitor_heart_outlined, Icons.monitor_heart, 'Мон-нг', '/admin/monitoring'),
        ];
      default:
        return const [];
    }
  }

  static int _selectedIndex(List<_NavItem> items, String currentPath) {
    for (var i = 0; i < items.length; i++) {
      if (currentPath == items[i].route) return i;
      // Match sub-paths (e.g. /student/diploma/123 → /student/diplomas)
      if (items[i].route != '/dashboard' &&
          currentPath.startsWith(items[i].route.replaceAll(RegExp(r's?$'), ''))) {
        return i;
      }
    }
    return 0;
  }

  static String _roleLabel(String role) {
    switch (role) {
      case 'student':
        return 'Студент';
      case 'employer':
        return 'Работодатель';
      case 'university':
        return 'Университет';
      case 'admin':
        return 'Администратор';
      default:
        return role;
    }
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;

  const _NavItem(this.icon, this.selectedIcon, this.label, this.route);
}
