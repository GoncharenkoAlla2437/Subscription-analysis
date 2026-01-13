import 'package:flutter/material.dart' hide Notification;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../widgets/app_drawer.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../models/notification.dart';
import '../models/notification_group.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Загружаем уведомления при инициализации экрана
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<NotificationProvider>();
      if (!provider.hasLoaded) {
        provider.loadNotificationGroups();
      }
    });
  }

  // Функция для обновления (перезагрузки) данных
  void _refreshData() async {
    final provider = context.read<NotificationProvider>();
    await provider.refresh();
    
    if (provider.error == null) {
      _showSnackBar('Уведомления обновлены');
    }
  }

  // Открыть уведомления по конкретной подписке
  void _openSubscriptionNotifications(BuildContext context, NotificationGroup group) async {
    final provider = context.read<NotificationProvider>();
    
    // Пометить все уведомления подписки как прочитанные
    final success = await provider.markSubscriptionAsRead(group.subscriptionId);
    
    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubscriptionNotificationsScreen(
            subscriptionId: group.subscriptionId,
            subscriptionName: group.subscriptionName,
          ),
        ),
      );
    } else if (provider.error != null) {
      _showErrorSnackBar(provider.error!);
    }
  }

  // Вспомогательные функции для уведомлений
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Форматирование времени
  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'только что';
    if (difference.inMinutes < 60) return '${difference.inMinutes} мин назад';
    if (difference.inHours < 24) return '${difference.inHours} ч назад';
    if (difference.inDays < 7) return '${difference.inDays} д назад';
    return '${date.day}.${date.month}.${date.year}';
  }

  // Форматирование даты для заголовка группы
  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeekStart = today.subtract(Duration(days: today.weekday - 1));
    
    final messageDate = DateTime(date.year, date.month, date.day);
    
    if (messageDate == today) return 'Сегодня';
    if (messageDate == yesterday) return 'Вчера';
    if (date.isAfter(thisWeekStart)) return 'На этой неделе';
    
    final monthNames = [
      'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
    ];
    return '${monthNames[date.month - 1]} ${date.year}';
  }

  // Получить цвет для категории подписки
  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'music':
      case 'музыка':
        return const Color(0xFFE91E63); // Розовый
      case 'video':
      case 'видео':
        return const Color(0xFFF44336); // Красный
      case 'books':
      case 'книги':
        return const Color(0xFF4CAF50); // Зеленый
      case 'games':
      case 'игры':
        return const Color(0xFF9C27B0); // Фиолетовый
      case 'education':
      case 'образование':
        return const Color(0xFF2196F3); // Синий
      case 'social':
      case 'соцсети':
        return const Color(0xFF00BCD4); // Голубой
      case 'other':
      case 'другое':
        return const Color(0xFF607D8B); // Серо-голубой
      default:
        return const Color(0xFF757575); // Серый
    }
  }

  // Получить иконку для категории подписки
  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'music':
      case 'музыка':
        return Icons.music_note;
      case 'video':
      case 'видео':
        return Icons.videocam;
      case 'books':
      case 'книги':
        return Icons.book;
      case 'games':
      case 'игры':
        return Icons.sports_esports;
      case 'education':
      case 'образование':
        return Icons.school;
      case 'social':
      case 'соцсети':
        return Icons.people;
      case 'other':
      case 'другое':
        return Icons.category;
      default:
        return Icons.subscriptions;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final notificationProvider = context.read<NotificationProvider>();

    // Инициализация токена, если он еще не установлен
    if (authProvider.user?.token != null && 
        notificationProvider.authToken == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notificationProvider.setAuthToken(authProvider.user!.token);
        notificationProvider.loadNotificationGroups();
      });
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color.fromARGB(248, 223, 218, 245),
      appBar: AppBar(
        title: const Text('Мои уведомления'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: notificationProvider.isLoading ? null : _refreshData,
          ),
          if (!kIsWeb) IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              _scaffoldKey.currentState!.openEndDrawer();
            },
          ),
        ],
      ),
      
      endDrawer: kIsWeb ? null : const AppDrawer(
        currentScreen: AppScreen.notifications,
        isMobile: true,
      ),
      
      body: kIsWeb 
        ? Row(
            children: [
              const AppDrawer(
                currentScreen: AppScreen.notifications,
                isMobile: false,
              ),
              Expanded(
                child: _buildBody(notificationProvider),
              ),
            ],
          )
        : _buildBody(notificationProvider),
    );
  }

  Widget _buildBody(NotificationProvider provider) {
    if (provider.isLoading && !provider.hasLoaded) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (provider.error != null && !provider.hasLoaded) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Ошибка загрузки',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                provider.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.refresh(),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    // Фильтрация групп по поисковому запросу
    List<NotificationGroup> filteredGroups = _searchQuery.isEmpty
        ? provider.notificationGroups
        : provider.notificationGroups.where((group) =>
            group.subscriptionName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            group.notifications.any((notification) =>
              notification.message.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              notification.title.toLowerCase().contains(_searchQuery.toLowerCase())
            )
          ).toList();

    return Column(
      children: [
        // Поиск
        Padding(
          padding: EdgeInsets.all(kIsWeb ? 24 : 16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Поиск уведомлений...',
              prefixIcon: const Icon(Icons.search),
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

        // Счетчики
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Непрочитанные: ${provider.totalUnread}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              Text(
                'Всего: ${filteredGroups.length}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),

        // Список уведомлений
        Expanded(
          child: filteredGroups.isEmpty
              ? _buildEmptyState(provider)
              : RefreshIndicator(
                  onRefresh: () async {
                    await provider.refresh();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredGroups.length,
                    itemBuilder: (context, index) {
                      final group = filteredGroups[index];
                      final lastNotification = group.lastNotification;
                      
                      return _buildSubscriptionCard(
                        group,
                        lastNotification,
                        context,
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionCard(
    NotificationGroup group,
    Notification? lastNotification,
    BuildContext context,
  ) {
    final categoryColor = _getCategoryColor(group.subscriptionCategory);
    final categoryIcon = _getCategoryIcon(group.subscriptionCategory);
    final hasUnread = group.unreadCount > 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: categoryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(categoryIcon, color: categoryColor, size: 28),
        ),
        title: Text(
          group.subscriptionName,
          style: TextStyle(
            fontSize: 16,
            fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              group.lastMessagePreview,
              style: const TextStyle(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            if (lastNotification != null)
              Text(
                _formatTime(lastNotification.createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),
        trailing: hasUnread
            ? Container(
                width: group.unreadCount > 1 ? 24 : 12,
                height: group.unreadCount > 1 ? 24 : 12,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: group.unreadCount > 1
                    ? Center(
                        child: Text(
                          group.unreadCount > 9 ? '9+' : group.unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
              )
            : null,
        onTap: () => _openSubscriptionNotifications(context, group),
      ),
    );
  }

  Widget _buildEmptyState(NotificationProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            _searchQuery.isEmpty 
              ? 'Нет уведомлений'
              : 'Ничего не найдено по запросу "$_searchQuery"',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
              ? 'Здесь будут отображаться уведомления о подписках'
              : 'Попробуйте изменить запрос',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class SubscriptionNotificationsScreen extends StatefulWidget {
  final int subscriptionId;
  final String subscriptionName;

  const SubscriptionNotificationsScreen({
    Key? key,
    required this.subscriptionId,
    required this.subscriptionName,
  }) : super(key: key);

  @override
  State<SubscriptionNotificationsScreen> createState() => _SubscriptionNotificationsScreenState();
}

class _SubscriptionNotificationsScreenState extends State<SubscriptionNotificationsScreen> {
  List<Notification> _notifications = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final provider = context.read<NotificationProvider>();
      final notifications = await provider.loadSubscriptionNotifications(widget.subscriptionId);
      
      setState(() {
        _notifications = notifications;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Форматирование времени
  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Форматирование даты для заголовка группы
  String _getMessageDateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date.isAfter(today)) {
      return 'Сегодня';
    } else if (date.isAfter(yesterday)) {
      return 'Вчера';
    } else {
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    }
  }

  // Группировка уведомлений по дате
  Map<String, List<Notification>> get _groupedNotifications {
    final Map<String, List<Notification>> grouped = {};
    
    for (final notification in _notifications) {
      final dateKey = _getMessageDateGroup(notification.createdAt);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(notification);
    }
    
    // Упорядочиваем даты: Сегодня, Вчера, затем остальные
    final orderedKeys = grouped.keys.toList()
      ..sort((a, b) {
        if (a == 'Сегодня') return -1;
        if (b == 'Сегодня') return 1;
        if (a == 'Вчера') return -1;
        if (b == 'Вчера') return 1;
        
        // Сравниваем даты для остальных
        try {
          final aParts = a.split('.');
          final bParts = b.split('.');
          final aDate = DateTime(int.parse(aParts[2]), int.parse(aParts[1]), int.parse(aParts[0]));
          final bDate = DateTime(int.parse(bParts[2]), int.parse(bParts[1]), int.parse(bParts[0]));
          return bDate.compareTo(aDate); // Новые даты выше
        } catch (e) {
          return 0;
        }
      });
    
    final orderedMap = <String, List<Notification>>{};
    for (final key in orderedKeys) {
      orderedMap[key] = grouped[key]!;
    }
    
    return orderedMap;
  }

  // Получить цвет для типа уведомления
  Color _getNotificationColor(Notification notification) {
    return Color(notification.typeColor);
  }

  // Получить иконку для типа уведомления
  IconData _getNotificationIcon(Notification notification) {
    switch (notification.type) {
      case 'subscription_created':
        return Icons.add_circle;
      case 'price_changed':
        return Icons.attach_money;
      case 'payment_reminder':
        return Icons.notifications;
      case 'payment_date_changed':
        return Icons.event;
      case 'auto_renewal_changed':
        return Icons.autorenew;
      case 'subscription_archived':
        return Icons.archive;
      case 'notifications_disabled':
        return Icons.notifications_off;
      default:
        return Icons.info;
    }
  }

  Widget _buildMessageBubble(Notification notification, BuildContext context) {
    final notificationColor = _getNotificationColor(notification);
    final notificationIcon = _getNotificationIcon(notification);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Аватар уведомления
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: notificationColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(notificationIcon, color: notificationColor, size: 24),
          ),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок уведомления
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                
                // Пузырек сообщения
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: notification.read ? Colors.white : const Color(0xFFF0F8FF),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.message,
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: notification.read ? FontWeight.normal : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(notification.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedNotifications = _groupedNotifications;
    final dateKeys = groupedNotifications.keys.toList();

    return Scaffold(
      backgroundColor: const Color.fromARGB(248, 223, 218, 245),
      appBar: AppBar(
        title: Text(
          widget.subscriptionName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _isLoading ? null : _loadNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        'Ошибка загрузки',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadNotifications,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Нет уведомлений',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'По этой подписке пока нет уведомлений',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: dateKeys.length,
                        itemBuilder: (context, index) {
                          final dateKey = dateKeys[index];
                          final notifications = groupedNotifications[dateKey]!;
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Заголовок с датой
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  dateKey,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              // Сообщения за эту дату
                              ...notifications.map((notification) => 
                                _buildMessageBubble(notification, context)
                              ),
                              
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                      ),
                    ),
    );
  }
}