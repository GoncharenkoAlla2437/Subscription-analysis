import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'subscription_screen.dart'; // ✅ Добавляем импорт экрана подписок

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // ✅ Проверяем, авторизован ли пользователь
    if (!authProvider.isAuthenticated) {
      // Если не авторизован, показываем LoginScreen
      return LoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Главная'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
            onPressed: () {
              _showLogoutDialog(context, authProvider);
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Аватар пользователя
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.blue[100],
                child: Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 30),
              
              // Приветствие
              Text(
                // ✅ Изменено: используем userEmail вместо user?.email
                'Добро пожаловать, ${authProvider.userEmail ?? "Пользователь"}!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 10),
              
              // Статус
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Вы успешно вошли в систему',
                      style: TextStyle(
                        color: Colors.green[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Карточки функций
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: [
                  _buildFeatureCard(
                    context,
                    icon: Icons.subscriptions,
                    title: 'Мои подписки',
                    subtitle: 'Управление подписками',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => SubscriptionsScreen()),
                      );
                    },
                  ),
                  
                  _buildFeatureCard(
                    context,
                    icon: Icons.analytics,
                    title: 'Аналитика',
                    subtitle: 'Статистика расходов',
                    color: Colors.green,
                    onTap: () {
                      // TODO: Переход на экран аналитики
                      _showComingSoonSnackBar(context, 'Аналитика');
                    },
                  ),
                  
                  _buildFeatureCard(
                    context,
                    icon: Icons.notifications,
                    title: 'Уведомления',
                    subtitle: 'Напоминания о платежах',
                    color: Colors.orange,
                    onTap: () {
                      // TODO: Переход на экран уведомлений
                      _showComingSoonSnackBar(context, 'Уведомления');
                    },
                  ),
                  
                  _buildFeatureCard(
                    context,
                    icon: Icons.settings,
                    title: 'Настройки',
                    subtitle: 'Настройки приложения',
                    color: Colors.purple,
                    onTap: () {
                      // TODO: Переход на экран настроек
                      _showComingSoonSnackBar(context, 'Настройки');
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              
              // Информация о пользователе
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.email, color: Colors.blue),
                        title: Text('Email'),
                        subtitle: Text(authProvider.userEmail ?? 'Не указан'),
                      ),
                      if (authProvider.userId != null)
                        ListTile(
                          leading: Icon(Icons.numbers, color: Colors.blue),
                          title: Text('ID пользователя'),
                          subtitle: Text(authProvider.userId.toString()),
                        ),
                      ListTile(
                        leading: Icon(Icons.login, color: Colors.blue),
                        title: Text('Статус'),
                        subtitle: Text(
                          authProvider.isAuthenticated 
                              ? 'Активный' 
                              : 'Не авторизован'
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Виджет карточки функции
  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Диалог выхода
  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Выход из системы'),
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
                // После выхода показываем LoginScreen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // Уведомление о функции в разработке
  void _showComingSoonSnackBar(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Функция "$featureName" скоро будет доступна'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.blue,
      ),
    );
  }
}