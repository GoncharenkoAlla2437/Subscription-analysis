import 'package:flutter/material.dart';
import '../models/subscription.dart';
import '../services/subscription_service.dart';
import 'auth_provider.dart';

class SubscriptionProvider extends ChangeNotifier {
  // Состояние для активных подписок
  List<Subscription> _activeSubscriptions = [];
  bool _isLoading = false;
  String? _error;
  bool _hasLoaded = false;

  // Состояние для архивных подписок
  List<Subscription> _archivedSubscriptions = [];
  bool _isLoadingArchived = false;
  String? _errorArchived;
  bool _hasLoadedArchived = false;

  String? _authToken;
  SubscriptionService? _subscriptionService;

  // Геттеры для активных подписок
  List<Subscription> get activeSubscriptions => _activeSubscriptions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasLoaded => _hasLoaded;

  // Геттеры для архивных подписок
  List<Subscription> get archivedSubscriptions => _archivedSubscriptions;
  bool get isLoadingArchived => _isLoadingArchived;
  String? get errorArchived => _errorArchived;
  bool get hasLoadedArchived => _hasLoadedArchived;

  String? get authToken => _authToken; 

  void setAuthToken(String? token) {
    _authToken = token; // ← сохраняем
    _subscriptionService = SubscriptionService(authToken: token);
  }

  void clearData() {
    _activeSubscriptions.clear();
    _archivedSubscriptions.clear();
    _hasLoaded = false;
    _hasLoadedArchived = false;
    _authToken = null;
    _error = null;
    _errorArchived = null;
    notifyListeners();
  }
  
  // Загрузить активные подписки
  Future<void> loadSubscriptions({bool forceRefresh = false}) async {
    if (_isLoading || (_hasLoaded && !forceRefresh)) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_subscriptionService == null) {
        throw Exception('Сервис не инициализирован. Авторизуйтесь.');
      }

      final subscriptions = await _subscriptionService!.getSubscriptions(archived: false);
      _activeSubscriptions = subscriptions;
      _hasLoaded = true;
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('Ошибка загрузки активных подписок: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Загрузить архивные подписки
  Future<void> loadArchivedSubscriptions({bool forceRefresh = false}) async {
    if (_isLoadingArchived || (_hasLoadedArchived && !forceRefresh)) return;
    
    _isLoadingArchived = true;
    _errorArchived = null;
    notifyListeners();

    try {
      if (_subscriptionService == null) {
        throw Exception('Сервис не инициализирован. Авторизуйтесь.');
      }

      // Используем новый метод для загрузки архивных подписок
      _archivedSubscriptions = await _subscriptionService!.getArchivedSubscriptions();
      _hasLoadedArchived = true;
      _errorArchived = null;
    } catch (e) {
      _errorArchived = e.toString();
      print('Ошибка загрузки архивных подписок: $e');
      
      // Если API не поддерживает фильтрацию, фильтруем локально из активных
      if (e.toString().contains('Эндпоинт не найден') || 
          e.toString().contains('404')) {
        _filterArchivedLocally();
      }
    } finally {
      _isLoadingArchived = false;
      notifyListeners();
    }
  }

  // Локальная фильтрация архивных подписок (запасной вариант)
  void _filterArchivedLocally() {
    try {
      // Фильтруем подписки с установленным archivedDate
      final allSubscriptions = [..._activeSubscriptions];
      // В реальном приложении здесь нужно загрузить все подписки
      // и отфильтровать те, у которых isArchived == true
      _archivedSubscriptions = allSubscriptions.where((sub) => sub.isArchived).toList();
      _hasLoadedArchived = true;
      _errorArchived = null;
      print('Локальная фильтрация: найдено ${_archivedSubscriptions.length} архивных подписок');
    } catch (e) {
      _errorArchived = 'Ошибка локальной фильтрации: $e';
    }
  }

  // Обновить архивные подписки
  Future<void> refreshArchived() async {
    _hasLoadedArchived = false;
    await loadArchivedSubscriptions(forceRefresh: true);
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
      _activeSubscriptions.add(createdSubscription);
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
      
      // Обновляем в активных подписках
      int index = _activeSubscriptions.indexWhere((s) => s.id == subscription.id);
      if (index != -1) {
        _activeSubscriptions[index] = updatedSubscription;
      }
      
      // Обновляем в архивных подписках
      index = _archivedSubscriptions.indexWhere((s) => s.id == subscription.id);
      if (index != -1) {
        _archivedSubscriptions[index] = updatedSubscription;
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
      
      // Удаляем из активных и добавляем в архивные
      _activeSubscriptions.removeWhere((s) => s.id == subscriptionId);
      _archivedSubscriptions.add(archivedSubscription);
      
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

  // Восстановить подписку из архива
  Future<bool> restoreFromArchive(String subscriptionId) async {
    if (_subscriptionService == null) {
      _error = 'Сервис не инициализирован. Авторизуйтесь.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Для восстановления из архива нужно обновить подписку, установив archivedDate в null
      final subscription = _archivedSubscriptions.firstWhere(
        (s) => s.id == subscriptionId,
        orElse: () => throw Exception('Подписка не найдена в архиве'),
      );
      
      final restoredSubscription = subscription.copyWith(
        archivedDate: null,
      );
      
      final updatedSubscription = await _subscriptionService!.updateSubscription(restoredSubscription);
      
      // Удаляем из архивных и добавляем в активные
      _archivedSubscriptions.removeWhere((s) => s.id == subscriptionId);
      _activeSubscriptions.add(updatedSubscription);
      
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка восстановления подписки: $e';
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
      
      // Удаляем из обоих списков
      _activeSubscriptions.removeWhere((s) => s.id == subscriptionId);
      _archivedSubscriptions.removeWhere((s) => s.id == subscriptionId);
      
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

  void clearArchivedError() {
    _errorArchived = null;
    notifyListeners();
  }

  void refresh() {
    _hasLoaded = false;
    loadSubscriptions(forceRefresh: true);
  }

  void refreshAll() {
    _hasLoaded = false;
    _hasLoadedArchived = false;
    loadSubscriptions(forceRefresh: true);
    loadArchivedSubscriptions(forceRefresh: true);
  }
}