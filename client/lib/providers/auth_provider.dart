import 'package:flutter/material.dart';
import 'package:my_first_app/providers/subscription_provider.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../models/api_response.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;
  String? _error;

  // Добавляем ссылку на SubscriptionProvider
  SubscriptionProvider? _subscriptionProvider;

  // Метод для установки связи с SubscriptionProvider
  void setSubscriptionProvider(SubscriptionProvider provider) {
    _subscriptionProvider = provider;
    // При смене пользователя обновляем токен в SubscriptionProvider
    if (_user?.token != null) {
      _subscriptionProvider?.setAuthToken(_user!.token);
    }
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null && _user!.token != null;

  Future<ApiResponse> register(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _authService.register(email, password);

    _isLoading = false;

    if (response.success) {
      // После успешной регистрации автоматически входим
      final loginResponse = await login(email, password);
      notifyListeners();
      return loginResponse;
    } else {
      _error = response.message;
      notifyListeners();
      return response;
    }
  }

  Future<ApiResponse> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _authService.login(email, password);

    _isLoading = false;

    if (response.success) {
      _user = User(
        id: response.data?['id'] ?? 1,
        email: email,
        token: response.data?['token'] ?? 'dummy_token_here',
      );
      _error = null;

      // Устанавливаем токен в SubscriptionProvider после успешного логина
      if (_subscriptionProvider != null) {
        _subscriptionProvider!.setAuthToken(_user!.token);
      }

      notifyListeners();
      return response;
    } else {
      _error = response.message;
      notifyListeners();
      return response;
    }
  }

  Future<void> logout() async {
    _user = null;
    _error = null;

    // Очищаем токен в SubscriptionProvider
    if (_subscriptionProvider != null) {
      _subscriptionProvider!.setAuthToken(null);
    }

    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
