import 'package:flutter/material.dart';
import '../widgets/add_subscription_modal.dart';
import '../widgets/subscription_item.dart';
import '../models/subscription.dart';

import 'profile_screen.dart';
import 'analytics_screen.dart';
import 'notifications_screen.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState(); // создает объект State для управления StatefulWidget
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  final List<Subscription> subscriptions = [
    Subscription(
      name: 'КиноПоиск',
      date: '20.09.2025',
      amount: 256,
      icon: Icons.movie_creation_outlined,
      color: Colors.orange,
      category: 'Видео',
    ),
    Subscription(
      name: 'Spotify',
      date: '23.09.2025',
      amount: 315,
      icon: Icons.music_note_outlined,
      color: Colors.green,
      category: 'Музыка',
    ),
    Subscription(
      name: 'Яндекс Музыка',
      date: '20.09.2025',
      amount: 256,
      icon: Icons.headphones_outlined,
      color: Colors.red,
      category: 'Музыка',
    ),
    Subscription(
      name: 'Кинотеатр Okko',
      date: '20.09.2025',
      amount: 256,
      icon: Icons.play_circle_outline,
      color: Colors.purple,
      category: 'Видео',
    ),
    Subscription(
      name: 'Литрес',
      date: '20.09.2025',
      amount: 256,
      icon: Icons.menu_book_outlined,
      color: Colors.blue,
      category: 'Книги',
    ),
    Subscription(
      name: 'Яндекс Книги',
      date: '20.09.2025',
      amount: 256,
      icon: Icons.book_outlined,
      color: Colors.blue[800]!,
      category: 'Книги',
    ),
    Subscription(
      name: 'СберПрайм',
      date: '20.09.2025',
      amount: 256,
      icon: Icons.diamond_outlined,
      color: Colors.green[700]!,
      category: 'Другое',
    ),
    Subscription(
      name: 'VK',
      date: '20.09.2025',
      amount: 199,
      icon: Icons.chat_outlined,
      color: Colors.blue[400]!,
      category: 'Соцсети',
    ),
  ];

  final List<String> categories = ['Все', 'Музыка', 'Видео', 'Книги', 'Соцсети', 'Другое'];
  String selectedCategory = 'Все';

  // Функция для показа модального окна добавления подписки
  void _showAddSubscriptionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddSubscriptionModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Фильтрация подписок по выбранной категории
    final filteredSubscriptions = selectedCategory == 'Все'
        ? subscriptions
        : subscriptions.where((sub) => sub.category == selectedCategory).toList();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Color.fromARGB(248, 223, 218, 245),
      appBar: AppBar(
        title: Text('Мои подписки'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              // Открываем правую боковую панель
              _scaffoldKey.currentState!.openEndDrawer();
            },
          ),
        ],
      ),
      
      endDrawer: _buildDrawer(context),
      
      // Кнопка добавления новой подписки
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSubscriptionModal,
        backgroundColor: Colors.blue,
        child: Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      body: Column(
        children: [
          // Горизонтальная полоска с категориями
          Container(
            height: 60,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (context, index) => SizedBox(width: 12),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category == selectedCategory;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = category;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Список подписок
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.all(16),
              itemCount: filteredSubscriptions.length,
              separatorBuilder: (context, index) => Divider(
                height: 24,
                thickness: 1,
                color: Colors.grey[300],
              ),
              itemBuilder: (context, index) {
                final subscription = filteredSubscriptions[index];
                return SubscriptionItem(subscription: subscription);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Функция для построения боковой панели
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      // Добавляем выравнивание для правой панели
      child: SafeArea(
        child: Column(
          children: [
            // Заголовок боковой панели
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
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
                  SizedBox(height: 12),
                  Text(
                    'Пользователь',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'user@example.com',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            // Пункты меню
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    icon: Icons.subscriptions,
                    title: 'Подписки',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.person,
                    title: 'Личный кабинет',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(
                            builder: (context) => ProfileScreen(),
                          ));
                        },
                  ),                   
                  _buildDrawerItem(
                    icon: Icons.analytics,
                    title: 'Аналитика',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(
                            builder: (context) => AnalyticsScreen(),
                          ));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.notifications,
                    title: 'Уведомления',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(
                            builder: (context) => NotificationsScreen(),
                          ));
                    },
                  ),
                  
                  
                  // Разделитель
                  Divider(height: 24, thickness: 1),
                  
                  _buildDrawerItem(
                    icon: Icons.exit_to_app,
                    title: 'Выйти',
                    onTap: () {
                      Navigator.pop(context);
                      _showLogoutDialog(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Вспомогательная функция для создания пунктов меню
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(fontSize: 16),
      ),
      onTap: onTap,
    );
  }

  // Функция для показа сообщения "Скоро будет"
  void _showComingSoonMessage(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - скоро будет доступно!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Функция для показа диалога выхода
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Выход'),
          content: Text('Вы уверены, что хотите выйти?'),
          actions: [
            TextButton(
              child: Text('Отмена'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Выйти', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _showComingSoonMessage(context, 'Выход');
              },
            ),
          ],
        );
      },
    );
  }
}

