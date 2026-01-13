import 'package:flutter/material.dart';
import '../models/subscription.dart';
import '../services/subscription_service.dart';
import 'auth_provider.dart';

class SubscriptionProvider extends ChangeNotifier {
  // Состояние
  List<Subscription> _subscriptions = []; // Какие данные показывать
  bool _isLoading = false;  // Какой экран показывать (спиннер/данные)
  String? _error;  // Что показывать в случае ошибки
  bool _hasLoaded = false;  // Уже загрузились или нет

  String? _authToken;
  SubscriptionService? _subscriptionService;

  // Геттеры для доступа к состоянию из UI
  List<Subscription> get subscriptions => _subscriptions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasLoaded => _hasLoaded;
  String? get authToken => _authToken; 

  List<Subscription> get activeSubscriptions =>
      _subscriptions.where((sub) => !sub.isArchived).toList();

  List<Subscription> get archivedSubscriptions =>
      _subscriptions.where((sub) => sub.isArchived).toList();


  void setAuthToken(String? token) {
    _authToken = token; // ← сохраняем
    _subscriptionService = SubscriptionService(authToken: token);
  }

  void clearData() {
    _subscriptions.clear(); // или _subscriptions = [];
    _hasLoaded = false;
    _authToken = null;
    _error = null;
    notifyListeners();
  }
  
  Future<void> loadSubscriptions({bool forceRefresh = false}) async {
    if (_isLoading || (_hasLoaded && !forceRefresh)) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_subscriptionService == null) {
        throw Exception('Сервис не инициализирован. Авторизуйтесь.');
      }

      final subscriptions = await _subscriptionService!.getSubscriptions();
      _subscriptions = subscriptions;
      _hasLoaded = true;
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('Ошибка загрузки подписок: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Subscription?> createSubscription(Subscription subscription) async {
    if (_subscriptionService == null) {
      _error = 'Сервис не инициализирован. Авторизуйтесь.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final createdSubscription = await _subscriptionService!.createSubscription(subscription);
      _subscriptions.add(createdSubscription);
      _error = null;
      notifyListeners();
      return createdSubscription;
    } catch (e) {
      _error = 'Ошибка создания подписки: $e';
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Subscription?> updateSubscription(Subscription subscription) async {
    if (_subscriptionService == null) {
      _error = 'Сервис не инициализирован. Авторизуйтесь.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedSubscription = await _subscriptionService!.updateSubscription(subscription);
      
      final index = _subscriptions.indexWhere((s) => s.id == subscription.id);
      if (index != -1) {
        _subscriptions[index] = updatedSubscription;
      }
      
      _error = null;
      notifyListeners();
      return updatedSubscription;
    } catch (e) {
      _error = 'Ошибка обновления подписки: $e';
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> archiveSubscription(String subscriptionId) async {
    if (_subscriptionService == null) {
      _error = 'Сервис не инициализирован. Авторизуйтесь.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final archivedSubscription = await _subscriptionService!.archiveSubscription(subscriptionId);
      
      final index = _subscriptions.indexWhere((s) => s.id == subscriptionId);
      if (index != -1) {
        _subscriptions[index] = archivedSubscription;
      }
      
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка архивации подписки: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteSubscription(String subscriptionId) async {
    if (_subscriptionService == null) {
      _error = 'Сервис не инициализирован. Авторизуйтесь.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _subscriptionService!.deleteSubscription(subscriptionId);
      
      _subscriptions.removeWhere((s) => s.id == subscriptionId);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка удаления подписки: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Subscription> filterByCategory(String category) {
    if (category == 'Все') return activeSubscriptions;
    
    return activeSubscriptions.where((sub) {
      switch (sub.category) {
        case SubscriptionCategory.music: return category == 'Музыка';
        case SubscriptionCategory.video: return category == 'Видео';
        case SubscriptionCategory.books: return category == 'Книги';
        case SubscriptionCategory.games: return category == 'Игры';
        case SubscriptionCategory.education: return category == 'Образование';
        case SubscriptionCategory.social: return category == 'Соцсети';
        case SubscriptionCategory.other: return category == 'Другое';
        default: return false;
      }
    }).toList();
  }

  List<Subscription> search(String query) {
    if (query.isEmpty) return activeSubscriptions;
    
    return activeSubscriptions.where((sub) =>
      sub.name.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void refresh() {
    _hasLoaded = false;
    loadSubscriptions(forceRefresh: true);
  }
}