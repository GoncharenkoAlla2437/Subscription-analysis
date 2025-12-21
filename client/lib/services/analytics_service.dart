// client/lib/services/analytics_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class AnalyticsService {
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

  AnalyticsService({String? authToken}) : _authToken = authToken;

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

    // Общий метод для запросов
  Future<Map<String, dynamic>> _makeAnalyticsRequest(
    String endpoint, 
    Map<String, String> params,
  ) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/$endpoint').replace(queryParameters: params),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Неавторизован. Пожалуйста, войдите снова.');
    } else if (response.statusCode == 404) {
      throw Exception('Данные не найдены для указанного периода');
    } else if (response.statusCode == 400) {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Некорректный запрос');
    } else {
      throw Exception('Ошибка загрузки аналитики: ${response.statusCode}');
    }
  }

  // ========== GET: Получить аналитику с распределением по категориям ==========  
  Future<Map<String, dynamic>> getAnalyticsSummary({
    required String period,
    int? month,
    int? quarter,
    required int year,
  }) async {
    final params = {
      'period': period,
      'year': year.toString(),
      if (month != null) 'month': month.toString(),
      if (quarter != null) 'quarter': quarter.toString(),
    };
    
    return await _makeAnalyticsRequest('analytics', params);
  }
  
    // ========== GET: Получить аналитику по одной из категорий ==========  
  Future<Map<String, dynamic>> getCategoryAnalytics({
    required String category,
    required String period,
    int? month,
    int? quarter,
    required int year,
  }) async {
    final params = {
      'category': category,
      'period': period,
      'year': year.toString(),
      if (month != null) 'month': month.toString(),
      if (quarter != null) 'quarter': quarter.toString(),
    };
    
    return await _makeAnalyticsRequest('analytics/$category', params);
  }
}