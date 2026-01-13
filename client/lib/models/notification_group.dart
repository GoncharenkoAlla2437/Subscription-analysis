import 'dart:convert';
import 'notification.dart';

class NotificationGroup {
  final int subscriptionId;
  final String subscriptionName;
  final double subscriptionAmount;
  final String? subscriptionCategory;
  final List<Notification> notifications;
  final int unreadCount;
  final DateTime? lastNotificationDate;

  NotificationGroup({
    required this.subscriptionId,
    required this.subscriptionName,
    required this.subscriptionAmount,
    this.subscriptionCategory,
    required this.notifications,
    required this.unreadCount,
    this.lastNotificationDate,
  });


  factory NotificationGroup.fromJson(Map<String, dynamic> json) {
    final notificationsJson = json['notifications'] as List<dynamic>? ?? [];
    
    return NotificationGroup(
      subscriptionId: json['subscription_id'] as int? ?? 0,
      subscriptionName: json['subscription_name'] as String? ?? '',
      subscriptionAmount: (json['subscription_amount'] as num?)?.toDouble() ?? 0.0,
      subscriptionCategory: json['subscription_category'] as String?,
      notifications: notificationsJson
          .map((item) => Notification.fromJson(item as Map<String, dynamic>))
          .toList(),
      unreadCount: json['unread_count'] as int? ?? 0,
      lastNotificationDate: json['last_notification_date'] != null
          ? DateTime.parse(json['last_notification_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subscription_id': subscriptionId,
      'subscription_name': subscriptionName,
      'subscription_amount': subscriptionAmount,
      'subscription_category': subscriptionCategory,
      'notifications': notifications.map((n) => n.toJson()).toList(),
      'unread_count': unreadCount,
      'last_notification_date': lastNotificationDate?.toIso8601String(),
    };
  }

  // Копирование с изменениями
  NotificationGroup copyWith({
    int? subscriptionId,
    String? subscriptionName,
    double? subscriptionAmount,
    String? subscriptionCategory,
    List<Notification>? notifications,
    int? unreadCount,
    DateTime? lastNotificationDate,
  }) {
    return NotificationGroup(
      subscriptionId: subscriptionId ?? this.subscriptionId,
      subscriptionName: subscriptionName ?? this.subscriptionName,
      subscriptionAmount: subscriptionAmount ?? this.subscriptionAmount,
      subscriptionCategory: subscriptionCategory ?? this.subscriptionCategory,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      lastNotificationDate: lastNotificationDate ?? this.lastNotificationDate,
    );
  }

  // Пометка всех уведомлений в группе как прочитанных
  NotificationGroup createCopyWithAllRead() {
    final readNotifications = notifications
        .map((notification) => notification.markAsRead())
        .toList();
    
    return copyWith(
      notifications: readNotifications,
      unreadCount: 0, 
    );
  }

  // Сортировка уведомлений (новые снизу)
  List<Notification> get sortedNotifications {
    final sorted = List<Notification>.from(notifications);
    sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return sorted;
  }

  // Получить последнее уведомление
  Notification? get lastNotification {
    if (notifications.isEmpty) return null;
    final sorted = sortedNotifications;
    return sorted.first;
  }

  bool get hasUnread => unreadCount > 0; // Геттер для удобства

  // Получить первую строку последнего сообщения
String get lastMessagePreview {
  final last = lastNotification;
  if (last == null) return 'Нет уведомлений';
  
  final message = last.message;
  if (message.length <= 50) return message;
  
  // Ищем последний пробел до 50 символов
  final truncated = message.substring(0, 50);
  final lastSpace = truncated.lastIndexOf(' ');
  
  if (lastSpace > 30) {
    return '${truncated.substring(0, lastSpace)}...';
  }
  
  return '$truncated...';
}
  // Получить иконку категории подписки
  String get categoryIcon {
    switch (subscriptionCategory?.toLowerCase()) {
      case 'music':
        return 'music_note';
      case 'video':
        return 'videocam';
      case 'books':
        return 'book';
      case 'games':
        return 'sports_esports';
      case 'education':
        return 'school';
      case 'social':
        return 'groups';
      case 'other':
        return 'category';
      default:
        return 'subscriptions';
    }
  }

  // Получить цвет категории
  int get categoryColor {
    switch (subscriptionCategory?.toLowerCase()) {
      case 'music':
        return 0xFFE91E63; // Розовый
      case 'video':
        return 0xFFF44336; // Красный
      case 'books':
        return 0xFF4CAF50; // Зеленый
      case 'games':
        return 0xFF9C27B0; // Фиолетовый
      case 'education':
        return 0xFF2196F3; // Синий
      case 'social':
        return 0xFF00BCD4; // Голубой
      case 'other':
        return 0xFF607D8B; // Серо-голубой
      default:
        return 0xFF757575; // Серый
    }
  }

  // Форматирование суммы
  String get formattedAmount {
    return '${subscriptionAmount.toStringAsFixed(2)} руб.';
  }

  // Форматирование даты последнего уведомления
  String get formattedLastDate {
    if (lastNotificationDate == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(lastNotificationDate!);
    
    if (difference.inDays == 0) {
      return 'Сегодня';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else {
      return '${_formatDate(lastNotificationDate!)}';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'NotificationGroup(subscriptionId: $subscriptionId, subscriptionName: $subscriptionName, unreadCount: $unreadCount)';
  }

  // Метод для сравнения по дате последнего уведомления (для сортировки)
  static int compareByLastDate(NotificationGroup a, NotificationGroup b) {
    final aDate = a.lastNotificationDate;
    final bDate = b.lastNotificationDate;
    
    if (aDate == null && bDate == null) return 0;
    if (aDate == null) return 1;
    if (bDate == null) return -1;
    
    return bDate.compareTo(aDate); // Новые сверху
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationGroup && other.subscriptionId == subscriptionId;
  }

  @override
  int get hashCode => subscriptionId.hashCode;
}