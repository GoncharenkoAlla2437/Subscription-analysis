import 'package:flutter/material.dart';
import 'package:my_first_app/models/subscription.dart';
import 'package:provider/provider.dart';
import '../widgets/add_subscription_modal.dart';
import '../widgets/subscription_item.dart';
import '../providers/subscription_provider.dart';
import 'archive_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../widgets/app_drawer.dart';
import '../providers/auth_provider.dart'; 

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
      final authProvider = context.read<AuthProvider>();
      final subscriptionProvider = context.read<SubscriptionProvider>();
      
      // ✅ Изменили проверку: используем isAuthenticated вместо user?.token
      if (authProvider.isAuthenticated && authProvider.token != null) {
        // Передаем токен в SubscriptionProvider если нужно
        if (subscriptionProvider.authToken == null) {
          subscriptionProvider.setAuthToken(authProvider.token!);
        }
        
        if (!subscriptionProvider.hasLoaded) {
          subscriptionProvider.loadSubscriptions();
        }
      }
    });
  }

  // Функция для показа модального окна добавления подписки
  void _showAddSubscriptionModal() async {
    // ✅ Проверяем авторизацию
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      _showErrorSnackBar('Пожалуйста, войдите в систему');
      return;
    }

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
    // ✅ Проверяем авторизацию
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      _showErrorSnackBar('Пожалуйста, войдите в систему');
      return;
    }

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
    // ✅ Проверяем авторизацию
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      _showErrorSnackBar('Пожалуйста, войдите в систему');
      return;
    }

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
    // ✅ Проверяем авторизацию
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      _showErrorSnackBar('Пожалуйста, войдите в систему');
      return;
    }

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
  final authProvider = context.watch<AuthProvider>();
  final subscriptionProvider = context.watch<SubscriptionProvider>();

  // 🔥 КРИТИЧЕСКО ВАЖНО: Очищаем данные при logout
  if (!authProvider.isAuthenticated && subscriptionProvider.hasLoaded) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      subscriptionProvider.clearData();
    });
  }

  // 🔥 Проверяем смену пользователя по токену
  if (authProvider.isAuthenticated && authProvider.token != null) {
    if (subscriptionProvider.authToken != authProvider.token) {
      // Токен изменился - значит другой пользователь
      WidgetsBinding.instance.addPostFrameCallback((_) {
        subscriptionProvider.clearData();
        subscriptionProvider.setAuthToken(authProvider.token!);
        subscriptionProvider.loadSubscriptions();
      });
    } else if (!subscriptionProvider.hasLoaded) {
      // Первая загрузка для этого пользователя
      WidgetsBinding.instance.addPostFrameCallback((_) {
        subscriptionProvider.loadSubscriptions();
      });
    }
  }

  return Scaffold(
    key: _scaffoldKey,
    backgroundColor: Color.fromARGB(248, 223, 218, 245),
    appBar: AppBar(
      title: Text(
        // ✅ Используем userEmail или заголовок по умолчанию
        authProvider.isAuthenticated && authProvider.userEmail != null
            ? 'Подписки: ${authProvider.userEmail}'
            : 'Мои подписки'
      ),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      actions: [
        // ✅ Показываем кнопку обновления только если авторизованы
        if (authProvider.isAuthenticated) 
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: subscriptionProvider.isLoading ? null : _refreshData,
          ),
        if (!kIsWeb) IconButton(
          icon: Icon(Icons.menu, color: Colors.black),
          onPressed: () {
            _scaffoldKey.currentState!.openEndDrawer();
          },
        ),
        // ✅ Добавляем кнопку входа/выхода
        IconButton(
          icon: Icon(
            authProvider.isAuthenticated ? Icons.logout : Icons.login,
            color: Colors.black,
          ),
          onPressed: () {
            if (authProvider.isAuthenticated) {
              authProvider.logout();
            } else {
              Navigator.pushNamed(context, '/login');
            }
          },
        ),
      ],
    ),
    
    endDrawer: kIsWeb ? null : const AppDrawer(
      currentScreen: AppScreen.subscriptions,
      isMobile: true,
    ),
    
    body: _buildMainContent(authProvider, subscriptionProvider),
    
    floatingActionButton: _buildFloatingActionButton(authProvider),
    floatingActionButtonLocation: kIsWeb
      ? FloatingActionButtonLocation.endFloat
      : FloatingActionButtonLocation.centerFloat,
  );
}

  // ✅ Вынесли основной контент в отдельный метод
  Widget _buildMainContent(AuthProvider authProvider, SubscriptionProvider subscriptionProvider) {
    if (!authProvider.isAuthenticated) {
      return _buildUnauthenticatedContent();
    }

    if (kIsWeb) {
      return Row(
        children: [
          const AppDrawer(
            currentScreen: AppScreen.subscriptions,
            isMobile: false,
          ),
          Expanded(
            child: _buildSubscriptionContent(subscriptionProvider),
          ),
        ],
      );
    } else {
      return _buildSubscriptionContent(subscriptionProvider);
    }
  }

  // ✅ Контент для неавторизованных пользователей
  Widget _buildUnauthenticatedContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.login, size: 80, color: Colors.grey[400]),
          SizedBox(height: 20),
          Text(
            'Войдите в систему',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Для просмотра подписок требуется авторизация',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 30),
          ElevatedButton.icon(
            icon: Icon(Icons.login),
            label: Text('Войти'),
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
          ),
          SizedBox(height: 15),
          TextButton(
            child: Text('Зарегистрироваться'),
            onPressed: () {
              Navigator.pushNamed(context, '/register');
            },
          ),
        ],
      ),
    );
  }

  // ✅ Контент с подписками
  Widget _buildSubscriptionContent(SubscriptionProvider provider) {
    if (provider.isLoading && !provider.hasLoaded) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

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

    final activeSubscriptions = provider.activeSubscriptions;

    List<Subscription> filteredSubscriptions = selectedCategory == 'Все'
        ? activeSubscriptions
        : activeSubscriptions.where((sub) => _matchesCategory(sub, selectedCategory)).toList();
 
    if (_searchQuery.isNotEmpty) {
      filteredSubscriptions = filteredSubscriptions.where((sub) =>
        sub.name.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    return Column(
      children: [

        Padding(
          padding: EdgeInsets.all(kIsWeb ? 24 : 16), 
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

        Container(
          height: kIsWeb ? 70 : 60, 
          padding: EdgeInsets.symmetric(
            horizontal: kIsWeb ? 24 : 16,
            vertical: kIsWeb ? 12 : 8,
          ),
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

  // ✅ FAB с проверкой авторизации
  Widget _buildFloatingActionButton(AuthProvider authProvider) {
    if (!authProvider.isAuthenticated) {
      return SizedBox.shrink(); // Не показываем FAB если не авторизован
    }

    return FloatingActionButton(
      onPressed: _showAddSubscriptionModal,
      backgroundColor: Colors.blue,
      child: const Icon(Icons.add, color: Colors.white, size: 28),
    );
  }

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
}