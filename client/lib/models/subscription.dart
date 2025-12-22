import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Категории подписок
enum SubscriptionCategory {
  music,
  video,
  books,
  games,
  education,
  social,
  other,
}

// Периодичность списаний
enum BillingCycle {
  monthly,
  yearly,
  quarterly,
}


// История цен для аналитики
class PriceHistory {
  final DateTime startDate;
  final DateTime endDate;
  final int amount;

  PriceHistory({
    required this.startDate,
    required this.endDate,
    required this.amount,
  });

  // Преобразование JSON с бэка в Dart объект
factory PriceHistory.fromJson(Map<String, dynamic> json) => PriceHistory(
  startDate: DateTime.parse(json['startDate'].toString()),  // ← toString()
  
  // endDate МОЖЕТ БЫТЬ NULL в ответе от бекенда!
  endDate: json['endDate'] != null 
      ? DateTime.parse(json['endDate'].toString())  // ← toString()
      : DateTime.now(),  // значение по умолчанию или startDate
  
  amount: (json['amount'] as int?) ?? 0,  // ← проверка на null
);
  // toJson НЕ нужен, потому что фронтенд не отправляет историю цен на бэкенд

  // Для отладки
  @override
  String toString() {
    return 'Payment: ${amount} руб за период ${DateFormat('dd.MM.yy').format(startDate)}-${DateFormat('dd.MM.yy').format(endDate)}';
  }
}


// Основной класс подписки
class Subscription {
  final String id;
  final String name;
  final int currentAmount; // Текущая цена для следующих платежей
  final DateTime nextPaymentDate;  // Дата следующего планируемого платежа
  final DateTime connectedDate; // Дата подключения
  final DateTime? archivedDate; // Дата архивации
  final SubscriptionCategory category;
  final bool notificationsEnabled; // Отправлять ли уведомления
  final int notifyDays; // За сколько дней уведомлять об окончании подписки
  // final bool isTrial; // Функионал отключен на бэкенде
  final bool autoRenewal; // Автопродление подписки
  final BillingCycle billingCycle;
  // final int billingDay;

  // Технические поля (обычно не показываются в UI)
  // final DateTime createdAt;
  // final DateTime updatedAt;
  
  // UI поля (вычисляются на фронтенде)
  final IconData icon;
  final Color color;

  // Вложенные данные (приходят с бэкенда, если запрошены)
  final List<PriceHistory> priceHistory;

  Subscription({
    required this.id,
    required this.name,
    required this.currentAmount,
    required this.nextPaymentDate,
    required this.connectedDate,
    this.archivedDate,
    required this.category,
    required this.notifyDays,
    required this.billingCycle,
    required this.notificationsEnabled,
    required this.autoRenewal,
    required this.icon,
    required this.color,
    this.priceHistory = const [], // по умолчанию пустой список
  });

  
  // ========== fromJson - для получения данных с бэкенда ==========
factory Subscription.fromJson(Map<String, dynamic> json) {
  return Subscription(
    // Преобразуем id в строку (если бэкенд возвращает int)
    id: (json['id']?.toString() ?? ''),
    name: json['name'] as String,
    currentAmount: (json['currentAmount'] ?? 0) as int,
    // nextPaymentDate - МОЖЕТ быть null! Добавляем проверку
    nextPaymentDate: json['nextPaymentDate'] != null 
        ? DateTime.parse(json['nextPaymentDate'].toString())
        : DateTime.now().add(Duration(days: 30)), // значение по умолчанию
    connectedDate: DateTime.parse(json['connectedDate'].toString()),
    // archivedDate - МОЖЕТ быть null! УБИРАЕМ as String
    archivedDate: json['archivedDate'] != null 
        ? DateTime.parse(json['archivedDate'].toString()) // ← .toString() вместо as String!
        : null,
    category: _parseCategory(json['category'] as String),
    notifyDays: (json['notifyDays'] ?? 3) as int,
    billingCycle: _parseBillingCycle(json['billingCycle'] as String),
    notificationsEnabled: (json['notificationsEnabled'] ?? true) as bool,
    autoRenewal: (json['autoRenewal'] ?? false) as bool,
    // UI поля вычисляем на фронтенде
    icon: _getIconForCategory(json['category'] as String),
    color: _getColorForCategory(json['category'] as String),
    // История цен
    priceHistory: json['priceHistory'] != null
        ? (json['priceHistory'] as List)
            .map((item) => PriceHistory.fromJson(item as Map<String, dynamic>))
            .toList()
        : [],
  );
}

  // ========== toJson - для отправки на бэкенд ==========
  
  // Для создания новой подписки
  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'currentAmount': currentAmount,
      'nextPaymentDate': _formatDate(nextPaymentDate),
      'category': _categoryToString(category),
      'notifyDays': notifyDays,
      'billingCycle': _billingCycleToString(billingCycle),
      'notificationsEnabled': notificationsEnabled,
      'autoRenewal': autoRenewal,
    };
  }

  // Для редактирования подписки
  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'currentAmount': currentAmount,
      'nextPaymentDate': _formatDate(nextPaymentDate),
      'category': _categoryToString(category),
      'notifyDays': notifyDays,
      'billingCycle': _billingCycleToString(billingCycle),
      'notificationsEnabled': notificationsEnabled,
      'autoRenewal': autoRenewal,
    };
  }

  // Для архивации подписки - не исопользуется, см. сервис
  // Map<String, dynamic> toArchiveJson() {
  //   return {
  //     'confirm': true,
  //     'archivedDate': archivedDate?.toIso8601String(),
  //   };
  // }


    // ========== Вспомогательные методы ==========
  

  static String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static SubscriptionCategory _parseCategory(String category) {
    switch (category.toLowerCase()) {
      case 'music': return SubscriptionCategory.music;
      case 'video': return SubscriptionCategory.video;
      case 'books': return SubscriptionCategory.books;
      case 'games': return SubscriptionCategory.games;
      case 'education': return SubscriptionCategory.education;
      case 'social': return SubscriptionCategory.social;
      case 'other': return SubscriptionCategory.other;
      default: return SubscriptionCategory.other;
    }
  }

  static String _categoryToString(SubscriptionCategory category) {
    return category.toString().split('.').last;
  }

  static BillingCycle _parseBillingCycle(String cycle) {
    switch (cycle.toLowerCase()) {
      case 'monthly': return BillingCycle.monthly;
      case 'yearly': return BillingCycle.yearly;
      case 'quarterly': return BillingCycle.quarterly;
      default: return BillingCycle.monthly;
    }
  }

  static String _billingCycleToString(BillingCycle cycle) {
    return cycle.toString().split('.').last;
  }


  static IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'music': return Icons.music_note;
      case 'video': return Icons.movie;
      case 'books': return Icons.menu_book;
      case 'games': return Icons.videogame_asset;
      case 'education': return Icons.school;
      case 'social': return Icons.group;
      case 'other': return Icons.category;
      default: return Icons.category;
    }
  }

  static Color _getColorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'music': return Colors.purple;
      case 'video': return Colors.red;
      case 'books': return Colors.blue;
      case 'games': return Colors.green;
      case 'education': return Colors.orange;
      case 'social': return Colors.blueAccent;
      case 'other': return Colors.grey;
      default: return Colors.grey;
    }
  }

    // ========== UI методы ==========
  
  String get formattedNextPayment {
    return DateFormat('dd.MM.yyyy').format(nextPaymentDate);
  }

  String get billingCycleText {
    switch (billingCycle) {
      case BillingCycle.monthly: return 'Ежемесячно';
      case BillingCycle.yearly: return 'Ежегодно';
      case BillingCycle.quarterly: return 'Ежеквартально';
    }
  }

  String get categoryText {
  switch (category) {
    case SubscriptionCategory.music: return 'Музыка';
    case SubscriptionCategory.video: return 'Стриминг';
    case SubscriptionCategory.books: return 'Книги';
    case SubscriptionCategory.games: return 'Игры';
    case SubscriptionCategory.education: return 'Образование';
    case SubscriptionCategory.social: return 'Социальные сети';
    case SubscriptionCategory.other: return 'Другое';
    }
  }

  String get formattedAmount {
    return '${(currentAmount).toStringAsFixed(2)} ₽';
  }

  bool get isArchived => archivedDate != null;

  int get daysUntilPayment {
    return nextPaymentDate.difference(DateTime.now()).inDays;
  }

  bool get isOverdue => daysUntilPayment < 0;
  
  // ========== copyWith ==========
  
  Subscription copyWith({
    String? id,
    String? name,
    int? currentAmount,
    DateTime? nextPaymentDate,
    DateTime? connectedDate,
    DateTime? archivedDate,
    SubscriptionCategory? category,
    int? notifyDays,
    BillingCycle? billingCycle,
    bool? notificationsEnabled,
    bool? autoRenewal,
    IconData? icon,
    Color? color,
    List<PriceHistory>? priceHistory,
  }) {
    return Subscription(
      id: id ?? this.id,
      name: name ?? this.name,
      currentAmount: currentAmount ?? this.currentAmount,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      connectedDate: connectedDate ?? this.connectedDate,
      archivedDate: archivedDate ?? this.archivedDate,
      category: category ?? this.category,
      notifyDays: notifyDays ?? this.notifyDays,
      billingCycle: billingCycle ?? this.billingCycle,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      autoRenewal: autoRenewal ?? this.autoRenewal,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      priceHistory: priceHistory ?? this.priceHistory,
    );
  }

  @override
  String toString() {
    return 'Subscription{id: $id, name: $name, amount: $formattedAmount, nextPayment: $formattedNextPayment}';
  }
}
  

  // Данные методы реализуются на бэкенде
  // bool get isOverdue => nextPaymentDate.isBefore(DateTime.now());

  // // Автообновление даты
  // Subscription getUpdatedSubscription() {
  //   if (isOverdue) {
  //     return copyWith(
  //       nextPaymentDate: getNextPaymentDate(),
  //     );
  //   }
  //   return this;
  // }
  // int get daysUntilPayment => nextPaymentDate.difference(DateTime.now()).inDays;

  //   DateTime getNextPaymentDate() {
  //   switch (billingCycle) {
  //     case BillingCycle.monthly:
  //       return DateTime(
  //         nextPaymentDate.year,
  //         nextPaymentDate.month + 1,
  //         billingDay,
  //       );
  //     case BillingCycle.yearly:
  //       return DateTime(
  //         nextPaymentDate.year + 1,
  //         nextPaymentDate.month,
  //         billingDay,
  //       );
  //     case BillingCycle.quarterly:
  //       return DateTime(
  //         nextPaymentDate.year,
  //         nextPaymentDate.month + 3,
  //         billingDay,
  //       );
  //   }
  // }