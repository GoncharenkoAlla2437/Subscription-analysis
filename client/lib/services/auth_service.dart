import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_response.dart';
import '../models/user.dart';

class AuthService {
  // Как сейчас делаются запросы к API
  static const String baseUrl = 'http://127.0.0.1:8000';

  Future<ApiResponse> register(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: data['message'] ?? 'Registration successful',
          data: data,
        );
      } else {
        return ApiResponse(
          success: false,
          message: data['detail'] ?? 'Registration failed',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error. Please check your connection.',
      );
    }
  }

  Future<ApiResponse> login(String email, String password) async {
    try {
      print('🔐 Login attempt for: $email');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      print('📊 Login status: ${response.statusCode}');
      print('📦 Login response body: ${response.body}');

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        // ✅ Проверяем наличие токена в ответе
        if (data['access_token'] == null) {
          print('⚠️ Warning: access_token missing in response');
        }
        
        return ApiResponse(
          success: true,
          message: data['message'] ?? 'Login successful',
          data: data,
        );
      } else {
        return ApiResponse(
          success: false,
          message: data['detail'] ?? 'Login failed',
        );
      }
    } catch (e) {
      print('❌ Login error: $e');
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
      );
    }
  }
} // ✅ ДОБАВЬТЕ ЭТУ ЗАКРЫВАЮЩУЮ СКОБКУ