// Сервис для работы с API
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification.dart';
import '../models/notification_group.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class NotificationService {
  // Базовый URL API
  String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api';
    } else {
      return 'http://localhost:8000/api';
    }
  }

  final String? _authToken;

  NotificationService({String? authToken}) : _authToken = authToken;

  // Заголовки с авторизацией
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    return headers;
  }

  // ========== GET: Получить уведомления, сгруппированные по подпискам ========== (обязательный)
  Future<List<NotificationGroup>> getGroupedNotifications() async {
    try {
      print('[NotificationService] Запрос группированных уведомлений');
      print('URL: $_baseUrl/notifications/grouped');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/notifications/grouped'),
        headers: _headers,
      );

      print('[NotificationService] Ответ с сервера:');
      print('Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = json.decode(response.body);
          print('[NotificationService] Получено ${data.length} групп уведомлений');
          
          final groups = data
              .map((json) => NotificationGroup.fromJson(json as Map<String, dynamic>))
              .toList();
          
          // Сортируем по дате (новые сверху)
          groups.sort((a, b) => b.lastNotificationDate?.compareTo(a.lastNotificationDate ?? DateTime(0)) ?? 0);
          
          return groups;
        } catch (e) {
          print('Response body: ${response.body}');
          throw Exception('Ошибка обработки данных от сервера: $e');
        }
      } else if (response.statusCode == 401) {
        print('[NotificationService] Ошибка 401: Неавторизован');
        throw Exception('Неавторизован. Пожалуйста, войдите снова.');
      } else {
        print('[NotificationService] Ошибка ${response.statusCode}: ${response.body}');
        throw Exception('Ошибка загрузки уведомлений: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      print('[NotificationService] Ошибка сети: $e');
      throw Exception('Ошибка сети. Проверьте подключение к интернету.');
    } catch (e) {
      print('[NotificationService] Неожиданная ошибка: $e');
      rethrow;
    }
  }

  // ========== GET: Получить все уведомления по конкретной подписке ========== (обязательный)
  Future<List<Notification>> getSubscriptionNotifications(int subscriptionId) async {
    try {
      print('[NotificationService] Запрос уведомлений для подписки $subscriptionId');
      print('URL: $_baseUrl/notifications/subscription/$subscriptionId');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/notifications/subscription/$subscriptionId'),
        headers: _headers,
      );

      print('[NotificationService] Ответ с сервера:');
      print('Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = json.decode(response.body);
          print('[NotificationService] Получено ${data.length} уведомлений по подписке $subscriptionId');
          
          final notifications = data
              .map((json) => Notification.fromJson(json as Map<String, dynamic>))
              .toList();
          
          // Сортируем по дате (новые снизу)
          notifications.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          
          return notifications;
        } catch (e) {
          print('Response body: ${response.body}');
          throw Exception('Ошибка обработки данных от сервера: $e');
        }
      } else if (response.statusCode == 401) {
        print('[NotificationService] Ошибка 401: Неавторизован');
        throw Exception('Неавторизован. Пожалуйста, войдите снова.');
      } else if (response.statusCode == 404) {
        print('[NotificationService] Ошибка 404: Подписка не найдена');
        throw Exception('Подписка не найдена');
      } else {
        print('[NotificationService] Ошибка ${response.statusCode}: ${response.body}');
        throw Exception('Ошибка загрузки уведомлений по подписке: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      print('[NotificationService] Ошибка сети: $e');
      throw Exception('Ошибка сети. Проверьте подключение к интернету.');
    } catch (e) {
      print('[NotificationService] Неожиданная ошибка: $e');
      rethrow;
    }
  }

  // ========== POST: Пометить все уведомления подписки как прочитанные ==========(обязательный)
  Future<void> markSubscriptionNotificationsAsRead(int subscriptionId) async {
    try {
      print('[NotificationService] Помечаю уведомления подписки $subscriptionId как прочитанные');
      print('URL: $_baseUrl/notifications/subscription/$subscriptionId/read-all');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/notifications/subscription/$subscriptionId/read-all'),
        headers: _headers,
      );

      print('Status Code: ${response.statusCode}');
      print('Response: ${response.body}');

      if (response.statusCode == 200) {
        print('Уведомления помечены как прочитанные');
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Неавторизован. Пожалуйста, войдите снова.');
      } else if (response.statusCode == 404) {
        throw Exception('Подписка не найдена');
      } else {
        throw Exception('Ошибка пометки уведомлений как прочитанных: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      print('Ошибка сети: $e');
      throw Exception('Ошибка сети. Проверьте подключение к интернету.');
    } catch (e) {
      print('Ошибка: $e');
      rethrow;
    }
  }

  // ========== GET: Получить количество непрочитанных уведомлений по подписке ==========(обязательный)
  Future<int> getSubscriptionUnreadCount(int subscriptionId) async {
    try {
      print('[NotificationService] Запрашиваю количество непрочитанных для подписки $subscriptionId');
      print('URL: $_baseUrl/notifications/subscription/$subscriptionId/unread-count');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/notifications/subscription/$subscriptionId/unread-count'),
        headers: _headers,
      );

      print('Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> data = json.decode(response.body);
          final int unreadCount = data['unread_count'] as int;
          print('Непрочитанных: $unreadCount');
          return unreadCount;
        } catch (e) {
          print('Ошибка парсинга: $e');
          throw Exception('Ошибка обработки данных: $e');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Неавторизован. Пожалуйста, войдите снова.');
      } else if (response.statusCode == 404) {
        throw Exception('Подписка не найдена');
      } else {
        throw Exception('Ошибка получения количества уведомлений: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      print('Ошибка сети: $e');
      throw Exception('Ошибка сети. Проверьте подключение к интернету.');
    } catch (e) {
      print('Ошибка: $e');
      rethrow;
    }
  }

  // ========== GET: Получить количество всех непрочитанных уведомлений ========== (пока не нужен)
  // Future<int> getUnreadCount() async {
  //   try {
  //     print('[NotificationService] Запрос количества всех непрочитанных уведомлений');
      
  //     final response = await http.get(
  //       Uri.parse('$_baseUrl/notifications/unread-count'),
  //       headers: _headers,
  //     );

  //     print('Status Code: ${response.statusCode}');

  //     if (response.statusCode == 200) {
  //       try {
  //         final Map<String, dynamic> data = json.decode(response.body);
  //         final int unreadCount = data['unread_count'] as int;
  //         print('Всего непрочитанных: $unreadCount');
  //         return unreadCount;
  //       } catch (e) {
  //         print('Ошибка парсинга: $e');
  //         throw Exception('Ошибка обработки данных: $e');
  //       }
  //     } else if (response.statusCode == 401) {
  //       throw Exception('Неавторизован. Пожалуйста, войдите снова.');
  //     } else {
  //       throw Exception('Ошибка получения количества уведомлений: ${response.statusCode}');
  //     }
  //   } on http.ClientException catch (e) {
  //     print('Ошибка сети: $e');
  //     throw Exception('Ошибка сети. Проверьте подключение к интернету.');
  //   } catch (e) {
  //     print('Ошибка: $e');
  //     rethrow;
  //   }
  // }

  // ========== POST: Пометить все уведомления как прочитанные ==========(пока не нужен)
  // Future<void> markAllNotificationsAsRead() async {
  //   try {
  //     print('[NotificationService] Помечаю все уведомления как прочитанные');
      
  //     final response = await http.post(
  //       Uri.parse('$_baseUrl/notifications/read-all'),
  //       headers: _headers,
  //     );

  //     print('Status Code: ${response.statusCode}');
  //     print('Response: ${response.body}');

  //     if (response.statusCode == 200) {
  //       print('Все уведомления помечены как прочитанные');
  //       return;
  //     } else if (response.statusCode == 401) {
  //       throw Exception('Неавторизован. Пожалуйста, войдите снова.');
  //     } else {
  //       throw Exception('Ошибка пометки уведомлений как прочитанных: ${response.statusCode}');
  //     }
  //   } on http.ClientException catch (e) {
  //     print('Ошибка сети: $e');
  //     throw Exception('Ошибка сети. Проверьте подключение к интернету.');
  //   } catch (e) {
  //     print('Ошибка: $e');
  //     rethrow;
  //   }
  // }

  // ========== PATCH: Пометить конкретное уведомление как прочитанное ==========(пока не нужен)
  // Future<Notification> markNotificationAsRead(String notificationId) async {
  //   try {
  //     print('[NotificationService] Помечаю уведомление $notificationId как прочитанное');
      
  //     final data = {'read': true};
      
  //     final response = await http.patch(
  //       Uri.parse('$_baseUrl/notifications/$notificationId/read'),
  //       headers: _headers,
  //       body: json.encode(data),
  //     );

  //     print('Status Code: ${response.statusCode}');

  //     if (response.statusCode == 200) {
  //       final Map<String, dynamic> data = json.decode(response.body);
  //       return Notification.fromJson(data);
  //     } else if (response.statusCode == 401) {
  //       throw Exception('Неавторизован. Пожалуйста, войдите снова.');
  //     } else if (response.statusCode == 404) {
  //       throw Exception('Уведомление не найдено');
  //     } else {
  //       throw Exception('Ошибка пометки уведомления как прочитанного: ${response.statusCode}');
  //     }
  //   } on http.ClientException catch (e) {
  //     print('Ошибка сети: $e');
  //     throw Exception('Ошибка сети. Проверьте подключение к интернету.');
  //   } catch (e) {
  //     print('Ошибка: $e');
  //     rethrow;
  //   }
  // }
}