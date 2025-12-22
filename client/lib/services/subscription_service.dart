import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/subscription.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

// Сервис для работы с API подписок
class SubscriptionService {

  // Базовый URL API в зависимости от платформы  
  String get _baseUrl {
    if (kIsWeb) {
      // Для web - localhost работает
      return 'http://localhost:8000/api';
    } else if (Platform.isAndroid) {
      // Для Android эмулятора
      return 'http://10.0.2.2:8000/api';
    } else {
      // Для iOS симулятора и реальных устройств
      return 'http://localhost:8000/api';
    }
  }

  final String? _authToken;  // Приватное поле токена авторизации

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
    print('📤 [SubscriptionService] Отправляю запрос на создание подписки...');
    final subscriptionData = subscription.toCreateJson();
    print('📤 Данные для отправки: ${json.encode(subscriptionData)}');
    print('📤 URL: $_baseUrl/subscriptions');
    
    final response = await http.post(
      Uri.parse('$_baseUrl/subscriptions'),
      headers: _headers,
      body: json.encode(subscriptionData),
    );

    print('📥 [SubscriptionService] Получен ответ от сервера:');
    print('📥 Status Code: ${response.statusCode}');
    print('📥 Response Body: ${response.body}');
    print('📥 Response Headers: ${response.headers}');

    if (response.statusCode == 201) {
      try {
        print('🔄 [SubscriptionService] Пытаюсь распарсить JSON ответ...');
        final responseBody = response.body;
        final decodedJson = json.decode(responseBody) as Map<String, dynamic>;
        print('✅ [SubscriptionService] JSON успешно распарсен');
        print('📊 Содержимое ответа:');
        decodedJson.forEach((key, value) {
          print('   $key: $value (тип: ${value.runtimeType})');
        });
        
        final createdSubscription = Subscription.fromJson(decodedJson);
        print('✅ [SubscriptionService] Subscription.fromJson() успешно выполнен');
        return createdSubscription;
      } catch (e) {
        print('❌ [SubscriptionService] Ошибка при парсинге ответа: $e');
        print('❌ Сырой ответ: ${response.body}');
        throw Exception('Ошибка при обработке ответа сервера: $e');
      }
    } else if (response.statusCode == 400) {
      try {
        final error = json.decode(response.body) as Map<String, dynamic>;
        final errorMessage = error['message'] ?? error['detail'] ?? 'Ошибка валидации данных';
        print('❌ [SubscriptionService] Ошибка 400: $errorMessage');
        throw Exception(errorMessage);
      } catch (e) {
        print('❌ [SubscriptionService] Ошибка при парсинге ошибки 400: $e');
        throw Exception('Ошибка валидации данных: ${response.body}');
      }
    } else if (response.statusCode == 401) {
      print('🔒 [SubscriptionService] Ошибка 401: Неавторизован');
      throw Exception('Неавторизован. Пожалуйста, войдите снова.');
    } else if (response.statusCode == 422) {
      print('❌ [SubscriptionService] Ошибка 422: Неверные данные');
      try {
        final error = json.decode(response.body) as Map<String, dynamic>;
        final details = error['detail'] ?? 'Неверные данные';
        print('❌ Детали ошибки: $details');
        throw Exception('Неверные данные: $details');
      } catch (e) {
        throw Exception('Ошибка валидации: ${response.body}');
      }
    } else if (response.statusCode == 500) {
      print('🔥 [SubscriptionService] Ошибка 500: Внутренняя ошибка сервера');
      throw Exception('Внутренняя ошибка сервера. Попробуйте позже.');
    } else {
      print('⚠️ [SubscriptionService] Неизвестный статус код: ${response.statusCode}');
      print('⚠️ Response: ${response.body}');
      throw Exception('Ошибка создания подписки: ${response.statusCode}');
    }
  } on http.ClientException catch (e) {
    print('🌐 [SubscriptionService] Ошибка сети: $e');
    throw Exception('Ошибка сети. Проверьте подключение к интернету.');
  } on FormatException catch (e) {
    print('📄 [SubscriptionService] Ошибка формата JSON: $e');
    throw Exception('Некорректный ответ от сервера.');
  } catch (e) {
    print('💥 [SubscriptionService] Неожиданная ошибка в createSubscription: $e');
    print('💥 Stack trace: ${e.toString()}');
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