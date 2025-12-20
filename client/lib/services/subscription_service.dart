import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/subscription.dart';

// Сервис для работы с API подписок
class SubscriptionService {
  // static const String _baseUrl = 'http://10.0.2.2:8000/api'; // Для Android эмулятора
  static const String _baseUrl = 'http://localhost:8000/api'; // Для iOS/Web
  
  final String? _authToken;

  SubscriptionService({String? authToken}) : _authToken = authToken;

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

  // ========== GET: Получить все подписки ==========
  Future<List<Subscription>> getSubscriptions({
    bool archived = false,
    String? category,
  }) async {
    try {
      // Формируем query параметры
      final params = <String, String>{'archived': archived.toString()};
      if (category != null && category != 'Все') {
        params['category'] = _categoryToApi(category);
      }

      final uri = Uri.parse('$_baseUrl/subscriptions').replace(queryParameters: params);
      
      final response = await http.get(
        uri,
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Subscription.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Неавторизован. Пожалуйста, войдите снова.');
      } else {
        throw Exception('Ошибка загрузки подписок: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка в getSubscriptions: $e');
      rethrow;
    }
  }

  // ========== POST: Создать новую подписку ==========
  Future<Subscription> createSubscription(Subscription subscription) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/subscriptions'),
        headers: _headers,
        body: json.encode(subscription.toCreateJson()),
      );

      if (response.statusCode == 201) {
        return Subscription.fromJson(json.decode(response.body));
      } else if (response.statusCode == 400) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Ошибка валидации данных');
      } else if (response.statusCode == 401) {
        throw Exception('Неавторизован. Пожалуйста, войдите снова.');
      } else {
        throw Exception('Ошибка создания подписки: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка в createSubscription: $e');
      rethrow;
    }
  }

  // ========== PATCH: Обновить подписку ==========
  Future<Subscription> updateSubscription(Subscription subscription) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/subscriptions/${subscription.id}'),
        headers: _headers,
        body: json.encode(subscription.toUpdateJson()),
      );

      if (response.statusCode == 200) {
        return Subscription.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Подписка не найдена');
      } else if (response.statusCode == 401) {
        throw Exception('Неавторизован. Пожалуйста, войдите снова.');
      } else {
        throw Exception('Ошибка обновления подписки: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка в updateSubscription: $e');
      rethrow;
    }
  }

  // ========== PATCH: Архивировать подписку ==========
  Future<Subscription> archiveSubscription(String subscriptionId) async {
    try {
      final archiveData = {
        'confirm': true,
        'archivedDate': DateTime.now().toIso8601String(),
      };

      final response = await http.patch(
        Uri.parse('$_baseUrl/subscriptions/$subscriptionId/archive'),
        headers: _headers,
        body: json.encode(archiveData),
      );

      if (response.statusCode == 200) {
        return Subscription.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Подписка не найдена');
      } else if (response.statusCode == 401) {
        throw Exception('Неавторизован. Пожалуйста, войдите снова.');
      } else {
        throw Exception('Ошибка архивации подписки: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка в archiveSubscription: $e');
      rethrow;
    }
  }

  // ========== DELETE: Удалить подписку ==========
  Future<void> deleteSubscription(String subscriptionId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/subscriptions/$subscriptionId'),
        headers: _headers,
      );

      if (response.statusCode == 204) {
        return;
      } else if (response.statusCode == 404) {
        throw Exception('Подписка не найдена');
      } else if (response.statusCode == 401) {
        throw Exception('Неавторизован. Пожалуйста, войдите снова.');
      } else {
        throw Exception('Ошибка удаления подписки: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка в deleteSubscription: $e');
      rethrow;
    }
  }

  // ========== Вспомогательные методы ==========
  
  // Преобразование категории UI → API
  String _categoryToApi(String uiCategory) {
    switch (uiCategory) {
      case 'Музыка': return 'music';
      case 'Видео': return 'video';
      case 'Книги': return 'books';
      case 'Соцсети': return 'social';
      case 'Другое': return 'other';
      case 'Игры': return 'games';
      case 'Образование': return 'education';
      default: return 'other';
    }
  }

  // Преобразование категории API → UI
  String _categoryToUi(String apiCategory) {
    switch (apiCategory) {
      case 'music': return 'Музыка';
      case 'video': return 'Видео';
      case 'books': return 'Книги';
      case 'social': return 'Соцсети';
      case 'other': return 'Другое';
      case 'games': return 'Игры';
      case 'education': return 'Образование';
      default: return 'Другое';
    }
  }
}