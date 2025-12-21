import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../screens/subscription_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/archive_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

enum AppScreen {
  subscriptions,
  profile,
  analytics,
  notifications,
  archive,
}

class AppDrawer extends StatelessWidget {
  final AppScreen currentScreen;
  final bool isMobile;

  const AppDrawer({
    Key? key,
    required this.currentScreen,
    this.isMobile = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return _buildMobileDrawer(context);
    } else {
      return _buildWebDrawer(context);
    }
  }

  Widget _buildMobileDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: _buildDrawerContent(context),
      ),
    );
  }

  Widget _buildWebDrawer(BuildContext context) {
    return Container(
      width: 280,
      color: Colors.white,
      child: SafeArea(
        child: _buildDrawerContent(context),
      ),
    );
  }

  Widget _buildDrawerContent(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final subscriptionProvider = context.watch<SubscriptionProvider>();

    return Column(
      children: [
        // Заголовок боковой панели
        _buildDrawerHeader(authProvider),
        
        // Пункты меню
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildDrawerItem(
                context,
                icon: Icons.subscriptions,
                title: 'Подписки',
                screen: AppScreen.subscriptions,
                badge: null,
              ),
              _buildDrawerItem(
                context,
                icon: Icons.archive,
                title: 'Архив подписок',
                screen: AppScreen.archive,
                badge: subscriptionProvider.archivedSubscriptions.length,
              ),
              _buildDrawerItem(
                context,
                icon: Icons.person,
                title: 'Личный кабинет',
                screen: AppScreen.profile,
                badge: null,
              ),
              _buildDrawerItem(
                context,
                icon: Icons.analytics,
                title: 'Аналитика',
                screen: AppScreen.analytics,
                badge: null,
              ),
              _buildDrawerItem(
                context,
                icon: Icons.notifications,
                title: 'Уведомления',
                screen: AppScreen.notifications,
                badge: null,
              ),
              
              // Разделитель
              const Divider(height: 24, thickness: 1),
              
              _buildLogoutItem(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDrawerHeader(AuthProvider authProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      color: Colors.blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person,
              size: 25,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            authProvider.user?.email ?? 'Пользователь',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            authProvider.isAuthenticated ? 'Аккаунт активен' : 'Не авторизован',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required AppScreen screen,
    required int? badge,
  }) {
    final isSelected = screen == currentScreen;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.blue : Colors.grey[700],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: isSelected ? Colors.blue : Colors.black,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: badge != null && badge > 0
          ? CircleAvatar(
              radius: 12,
              backgroundColor: Colors.red,
              child: Text(
                badge > 99 ? '99+' : badge.toString(),
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            )
          : null,
      tileColor: isSelected ? Colors.blue.withOpacity(0.1) : null,
      onTap: () => _navigateToScreen(context, screen),
    );
  }

  Widget _buildLogoutItem(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.exit_to_app, color: Colors.grey),
      title: const Text(
        'Выйти',
        style: TextStyle(fontSize: 16),
      ),
      onTap: () => _showLogoutDialog(context),
    );
  }

  void _navigateToScreen(BuildContext context, AppScreen screen) {
    // Закрываем drawer на мобильных
    if (isMobile) {
      Navigator.pop(context);
    }

    switch (screen) {
      case AppScreen.subscriptions:
        if (currentScreen != AppScreen.subscriptions) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SubscriptionsScreen()),
          );
        }
        break;
      case AppScreen.profile:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
        break;
      case AppScreen.analytics:
        if (currentScreen != AppScreen.analytics) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
          );
        }
        break;
      case AppScreen.notifications:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
        );
        break;
      case AppScreen.archive:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ArchiveScreen()),
        );
        break;
    }
  }

  void _showLogoutDialog(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Выход'),
          content: const Text('Вы уверены, что хотите выйти?'),
          actions: [
            TextButton(
              child: const Text('Отмена'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Выйти', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                authProvider.logout();
              },
            ),
          ],
        );
      },
    );
  }
}