import 'dart:convert';

class Notification {
  final String id;
  final String userId;
  final int subscriptionId;
  final String type;
  final String title;
  final String message;
  final DateTime? scheduledDate;
  final DateTime? sentAt;
  final bool read;
  final String? actionUrl;
  final DateTime createdAt;

  Notification({
    required this.id,
    required this.userId,
    required this.subscriptionId,
    required this.type,
    required this.title,
    required this.message,
    this.scheduledDate,
    this.sentAt,
    required this.read,
    this.actionUrl,
    required this.createdAt,
  });

  // Преобразование из JSON
  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      subscriptionId: json['subscription_id'] as int? ?? 0,
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      scheduledDate: json['scheduled_date'] != null
          ? DateTime.parse(json['scheduled_date'])
          : null,
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'])
          : null,
      read: json['read'] as bool? ?? false,
      actionUrl: json['action_url'] as String?,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  // Преобразование в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'subscription_id': subscriptionId,
      'type': type,
      'title': title,
      'message': message,
      'scheduled_date': scheduledDate?.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'read': read,
      'action_url': actionUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Копирование с изменениями
  Notification copyWith({
    String? id,
    String? userId,
    int? subscriptionId,
    String? type,
    String? title,
    String? message,
    DateTime? scheduledDate,
    DateTime? sentAt,
    bool? read,
    String? actionUrl,
    DateTime? createdAt,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      sentAt: sentAt ?? this.sentAt,
      read: read ?? this.read,
      actionUrl: actionUrl ?? this.actionUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Пометить как прочитанное
  Notification markAsRead() {
    return copyWith(read: true);
  }

  // Тип уведомления в читаемом формате (на будущее, пока что только payment_reminder)
  String get readableType {
    switch (type) {
      case 'subscription_created':
        return 'Подписка создана';
      case 'price_changed':
        return 'Изменение цены';
      case 'payment_date_changed':
        return 'Изменение даты платежа';
      case 'payment_reminder':
        return 'Напоминание о платеже';
      case 'auto_renewal_changed':
        return 'Автопродление изменено';
      case 'notifications_disabled':
        return 'Уведомления отключены';
      case 'subscription_archived':
        return 'Подписка в архиве';
      case 'custom_notification':
        return 'Уведомление';
      default:
        return 'Уведомление';
    }
  }

  // Получить цвет для типа уведомления (на будущее)
  int get typeColor {
    switch (type) {
      case 'subscription_created':
        return 0xFF4CAF50; // Зеленый
      case 'price_changed':
        return 0xFFFF9800; // Оранжевый
      case 'payment_reminder':
        return 0xFF9C27B0; // Фиолетовый
      case 'payment_date_changed':
        return 0xFF2196F3; // Синий
      case 'auto_renewal_changed':
        return 0xFFE91E63; // Розовый
      case 'subscription_archived':
        return 0xFFF44336; // Красный
      default:
        return 0xFF607D8B; // Серо-голубой
    }
  }

  // Иконка для типа уведомления (на будущее)
  String get typeIcon {
    switch (type) {
      case 'subscription_created':
        return 'add_circle';
      case 'price_changed':
        return 'attach_money';
      case 'payment_reminder':
        return 'notifications';
      case 'payment_date_changed':
        return 'event';
      case 'auto_renewal_changed':
        return 'autorenew';
      case 'subscription_archived':
        return 'archive';
      case 'notifications_disabled':
        return 'notifications_off';
      default:
        return 'info';
    }
  }

  // Форматирование даты
  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notificationDate = DateTime(
      createdAt.year,
      createdAt.month,
      createdAt.day,
    );

    if (notificationDate == today) {
      return 'Сегодня в ${_formatTime(createdAt)}';
    } else if (notificationDate == yesterday) {
      return 'Вчера в ${_formatTime(createdAt)}';
    } else {
      return '${_formatDate(createdAt)} в ${_formatTime(createdAt)}';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  String toString() {
    return 'Notification(id: $id, subscriptionId: $subscriptionId, type: $type, title: $title, read: $read)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Notification && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}