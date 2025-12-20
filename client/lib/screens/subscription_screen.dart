import 'package:flutter/material.dart';
import 'package:my_first_app/models/subscription.dart';
import 'package:provider/provider.dart';
import '../widgets/add_subscription_modal.dart';
import '../widgets/subscription_item.dart';
import '../providers/subscription_provider.dart';
import '../providers/auth_provider.dart';
import 'profile_screen.dart';
import 'analytics_screen.dart';
import 'notifications_screen.dart';
import 'archive_screen.dart';

class SubscriptionsScreen extends StatefulWidget {
  SubscriptionsScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<String> categories = ['Все', 'Музыка', 'Видео', 'Книги', 'Игры', 'Образование', 'Соцсети', 'Другое'];
  String selectedCategory = 'Все';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Загружаем подписки при инициализации экрана
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SubscriptionProvider>();
      if (!provider.hasLoaded) {
        provider.loadSubscriptions();
      }
    });
  }

  // Функция для показа модального окна добавления подписки
  void _showAddSubscriptionModal() async {
    final subscriptionProvider = context.read<SubscriptionProvider>();
    
    // Показываем модальное окно
    final newSubscription = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddSubscriptionModal(),
    );

    // Если вернулась подписка, создаём её через провайдер
    if (newSubscription != null) {
      final result = await subscriptionProvider.createSubscription(newSubscription);
      
      if (result != null) {
        _showSnackBar('Подписка успешно создана');
      } else if (subscriptionProvider.error != null) {
        _showErrorSnackBar(subscriptionProvider.error!);
      }
    }
  }

  // Функция обновления подписки
  void _updateSubscription(Subscription updatedSubscription) async {
    final provider = context.read<SubscriptionProvider>();
    final result = await provider.updateSubscription(updatedSubscription);
    
    if (result != null) {
      _showSnackBar('Подписка успешно обновлена');
    } else if (provider.error != null) {
      _showErrorSnackBar(provider.error!);
    }
  }

  // Функция архивации подписки
  void _archiveSubscription(String subscriptionId) async {
    final provider = context.read<SubscriptionProvider>();
    final success = await provider.archiveSubscription(subscriptionId);
    
    if (success) {
      _showSnackBar('Подписка перемещена в архив');
    } else if (provider.error != null) {
      _showErrorSnackBar(provider.error!);
    }
  }

  // Функция для обновления (перезагрузки) данных
  void _refreshData() async {
    final provider = context.read<SubscriptionProvider>();
    await provider.loadSubscriptions(forceRefresh: true);
    
    if (provider.error == null) {
      _showSnackBar('Данные обновлены');
    }
  }

  // Вспомогательные функции для уведомлений
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = context.watch<SubscriptionProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Color.fromARGB(248, 223, 218, 245),
      appBar: AppBar(
        title: Text('Мои подписки'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          // Кнопка обновления
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: subscriptionProvider.isLoading ? null : _refreshData,
          ),
          // Кнопка меню
          IconButton(
            icon: Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              _scaffoldKey.currentState!.openEndDrawer();
            },
          ),
        ],
      ),
      
      // Боковая выдвижная панель
      endDrawer: _buildDrawer(context, authProvider),
      
      // Кнопка добавления новой подписки
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSubscriptionModal,
        backgroundColor: Colors.blue,
        child: Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      body: _buildBody(subscriptionProvider),
    );
  }

  // Построение основного содержимого экрана
  Widget _buildBody(SubscriptionProvider provider) {
    // Если загрузка и нет данных
    if (provider.isLoading && !provider.hasLoaded) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    // Если ошибка
    if (provider.error != null && !provider.hasLoaded) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Ошибка загрузки',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                provider.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.loadSubscriptions(forceRefresh: true),
              child: Text('Повторить'),
            ),
          ],
        ),
      );
    }

    // Получаем активные подписки и фильтруем
    final activeSubscriptions = provider.activeSubscriptions;
    
    // Фильтруем по категории
    List<Subscription> filteredSubscriptions = selectedCategory == 'Все'
        ? activeSubscriptions
        : activeSubscriptions.where((sub) => _matchesCategory(sub, selectedCategory)).toList();
    
    // Фильтруем по поисковому запросу
    if (_searchQuery.isNotEmpty) {
      filteredSubscriptions = filteredSubscriptions.where((sub) =>
        sub.name.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    return Column(
      children: [
        // Поисковая строка
        Padding(
          padding: EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Поиск подписок...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),

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

        // Статистика (кол-во подписок)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Найдено: ${filteredSubscriptions.length}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              Text(
                'Всего активных: ${activeSubscriptions.length}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),

        // Список подписок или сообщение об отсутствии
        Expanded(
          child: filteredSubscriptions.isEmpty
              ? _buildEmptyState(provider)
              : RefreshIndicator(
                  onRefresh: () async {
                    await provider.loadSubscriptions(forceRefresh: true);
                  },
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: filteredSubscriptions.length,
                    itemBuilder: (context, index) {
                      final subscription = filteredSubscriptions[index];
                      return SubscriptionItem(
                        subscription: subscription,
                        onUpdate: _updateSubscription,
                        onArchive: _archiveSubscription,
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // Проверка соответствия категории
  bool _matchesCategory(Subscription subscription, String uiCategory) {
    switch (subscription.category) {
      case SubscriptionCategory.music: return uiCategory == 'Музыка';
      case SubscriptionCategory.video: return uiCategory == 'Видео';
      case SubscriptionCategory.books: return uiCategory == 'Книги';
      case SubscriptionCategory.games: return uiCategory == 'Игры';
      case SubscriptionCategory.education: return uiCategory == 'Образование';
      case SubscriptionCategory.social: return uiCategory == 'Соцсети';
      case SubscriptionCategory.other: return uiCategory == 'Другое';
      default: return false;
    }
  }

  // Виджет для пустого состояния
  Widget _buildEmptyState(SubscriptionProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.subscriptions,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 20),
          Text(
            _searchQuery.isEmpty 
              ? 'Нет активных подписок'
              : 'Ничего не найдено по запросу "$_searchQuery"',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
              ? 'Нажмите на "+" чтобы добавить первую подписку'
              : 'Попробуйте изменить запрос или категорию',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (provider.archivedSubscriptions.isNotEmpty && _searchQuery.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: 16),
              child: ElevatedButton.icon(
                icon: Icon(Icons.archive),
                label: Text('Перейти в архив (${provider.archivedSubscriptions.length})'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ArchiveScreen()),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // Функция для построения боковой панели
  Widget _buildDrawer(BuildContext context, AuthProvider authProvider) {
    return Drawer(
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
                    authProvider.user?.email ?? 'Пользователь',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    authProvider.isAuthenticated ? 'Аккаунт активен' : 'Не авторизован',
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
                    icon: Icons.archive,
                    title: 'Архив подписок',
                    badge: context.read<SubscriptionProvider>().archivedSubscriptions.length,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ArchiveScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.person,
                    title: 'Личный кабинет',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfileScreen()),
                      );
                    },
                  ),                   
                  _buildDrawerItem(
                    icon: Icons.analytics,
                    title: 'Аналитика',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AnalyticsScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.notifications,
                    title: 'Уведомления',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => NotificationsScreen()),
                      );
                    },
                  ),
                  
                  // Разделитель
                  Divider(height: 24, thickness: 1),
                  
                  _buildDrawerItem(
                    icon: Icons.exit_to_app,
                    title: 'Выйти',
                    onTap: () {
                      Navigator.pop(context);
                      _showLogoutDialog(context, authProvider);
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
    int? badge,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(fontSize: 16),
      ),
      trailing: badge != null && badge > 0
          ? CircleAvatar(
              radius: 12,
              backgroundColor: Colors.red,
              child: Text(
                badge > 99 ? '99+' : badge.toString(),
                style: TextStyle(fontSize: 10, color: Colors.white),
              ),
            )
          : null,
      onTap: onTap,
    );
  }

  // Функция для показа диалога выхода
  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
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
                authProvider.logout();
                // Здесь можно добавить навигацию на экран входа
                _showSnackBar('Вы вышли из системы');
              },
            ),
          ],
        );
      },
    );
  }
}