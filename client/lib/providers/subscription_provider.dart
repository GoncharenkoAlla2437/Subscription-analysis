import 'package:flutter/material.dart';
import '../models/subscription.dart';
import '../services/subscription_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  // Состояние
  List<Subscription> _subscriptions = []; // Какие данные показывать
  bool _isLoading = false;  // Какой экран показывать (спиннер/данные)
  String? _error;  // Что показывать в случае ошибки
  bool _hasLoaded = false;  // Уже загрузились или нет

  // Геттеры для доступа к состоянию из UI
  List<Subscription> get subscriptions => _subscriptions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasLoaded => _hasLoaded;

  // Только активные подписки
  List<Subscription> get activeSubscriptions =>
      _subscriptions.where((sub) => !sub.isArchived).toList();

  // Только архивные подписки
  List<Subscription> get archivedSubscriptions =>
      _subscriptions.where((sub) => sub.isArchived).toList();

  // Сервис будет инициализирован с токеном
  SubscriptionService? _subscriptionService;
  
  void setAuthToken(String? token) {
    _subscriptionService = SubscriptionService(authToken: token);
  }

  // ========== Загрузка подписок ==========
  Future<void> loadSubscriptions({bool forceRefresh = false}) async {
    // Если уже загружаем или уже загружено (и не форсируем) - пропускаем
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

  // ========== Создание подписки ==========
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

  // ========== Обновление подписки ==========
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

  // ========== Архивирование подписки ==========
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

  // ========== Удаление подписки ==========
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

  // ========== Фильтрация по категории ==========
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

  // ========== Поиск по названию ==========
  List<Subscription> search(String query) {
    if (query.isEmpty) return activeSubscriptions;
    
    return activeSubscriptions.where((sub) =>
      sub.name.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  // ========== Очистка ошибки ==========
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ========== Принудительная перезагрузка ==========
  void refresh() {
    _hasLoaded = false;
    loadSubscriptions(forceRefresh: true);
  }
}