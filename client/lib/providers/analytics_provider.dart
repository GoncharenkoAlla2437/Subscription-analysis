import 'package:flutter/material.dart';
import '../models/analytics.dart';
import '../models/subscription.dart';
import '../services/analytics_service.dart';
import '../utils/category_styles.dart';

class AnalyticsProvider extends ChangeNotifier {
  // Сервис
  AnalyticsService? _analyticsService;
  
  void setAuthToken(String? token) {
    _analyticsService = AnalyticsService(authToken: token);
  }
  
  // Состояние основной аналитики
  AnalyticsPeriod _currentPeriod = AnalyticsPeriod(type: 'month', month: 9, year: 2024);  // За какой период показывать статистику
  List<GeneralAnalytics> _generalAnalytics = [];  // Данные по категориям
  bool _isLoading = false;  // Состояние загрузки основной аналитики
  String? _error;  // Ошибка загрузки основной аналитики
  
  // Состояние детальной аналитики
  List<CategoryAnalytics>? _categoryDetails;  // Детали по выбранной категории
  String? _selectedCategory;   // Выбранная категория для детализации
  bool _isLoadingDetails = false;  // Состояние загрузки детализации
  String? _detailsError;  // Ошибка загрузки детализации
  
  // Геттеры для доступа к состоянию из UI
  AnalyticsPeriod get currentPeriod => _currentPeriod;
  List<GeneralAnalytics> get generalAnalytics => _generalAnalytics;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get totalAmount => _generalAnalytics.fold(0, (sum, cat) => sum + cat.total);
  
  // Геттеры для детализации
  List<CategoryAnalytics>? get categoryDetails => _categoryDetails;
  String? get selectedCategory => _selectedCategory;
  bool get isLoadingDetails => _isLoadingDetails;
  String? get detailsError => _detailsError;
  double get totalAmountByCategory {
    if (_categoryDetails == null) return 0;
    return _categoryDetails!.fold(0, (sum, cat) => sum + cat.total);
  }

  // Методы изменяют состояние  
  // Основная загрузка аналитики
  Future<void> loadGeneralAnalytics() async {
    if (_analyticsService == null) {
      _error = 'Сервис не инициализирован. Авторизуйтесь.';
      _isLoading = false;
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final data = await _analyticsService!.getAnalyticsSummary(
        period: _currentPeriod.type,
        month: _currentPeriod.month,
        quarter: _currentPeriod.quarter,
        year: _currentPeriod.year,
      );
      
      _generalAnalytics = _mapApiToGeneralAnalytics(data);
      _error = null;
    } catch (e) {
      _error = 'Ошибка загрузки аналитики: $e';
      _generalAnalytics = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Загрузка детальной аналитики по категории
  Future<void> loadCategoryAnalytics(String category) async {
    if (_analyticsService == null) {
      _detailsError = 'Сервис не инициализирован. Авторизуйтесь.';
      _isLoadingDetails = false;
      notifyListeners();
      return;
    }
    
    _selectedCategory = category;
    _isLoadingDetails = true;
    _detailsError = null;
    notifyListeners();
    
    try {
      final data = await _analyticsService!.getCategoryAnalytics(
        category: category,
        period: _currentPeriod.type,
        month: _currentPeriod.month,
        quarter: _currentPeriod.quarter,
        year: _currentPeriod.year,
      );
      
      _categoryDetails = _mapApiToCategoryAnalytics(data);
      _detailsError = null;
    } catch (e) {
      _detailsError = 'Ошибка загрузки деталей категории: $e';
      _categoryDetails = null;
    } finally {
      _isLoadingDetails = false;
      notifyListeners();
    }
  }
  
  // Обновление периода
  void updatePeriod({
    String? type,
    int? month,
    int? quarter,
    int? year,
  }) {
    _currentPeriod = AnalyticsPeriod(
      type: type ?? _currentPeriod.type,
      month: month ?? _currentPeriod.month,
      quarter: quarter ?? _currentPeriod.quarter,
      year: year ?? _currentPeriod.year,
    );
    notifyListeners();
    
    // Перезагружаем данные
    loadGeneralAnalytics();
    
    // Если есть выбранная категория, перезагружаем и её
    if (_selectedCategory != null) {
      loadCategoryAnalytics(_selectedCategory!);
    }
  }
  
  // Быстрые методы переключения
  void setPeriodType(String type) => updatePeriod(type: type);
  void selectMonth(int month) => updatePeriod(month: month, quarter: null);
  void selectQuarter(int quarter) => updatePeriod(month: null, quarter: quarter);
  void selectYear(int year) => updatePeriod(year: year);
  
  // Сброс детальной аналитики
  void clearCategoryDetails() {
    _selectedCategory = null;
    _categoryDetails = null;
    notifyListeners();
  }
  
  // Очистка ошибок
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  void clearDetailsError() {
    _detailsError = null;
    notifyListeners();
  }
  
  // Маппинг данных из API
  List<GeneralAnalytics> _mapApiToGeneralAnalytics(Map<String, dynamic> apiData) {
    if (apiData['categories'] == null) return [];
    
    return (apiData['categories'] as List).map((cat) {
      final apiCategory = cat['category'].toString();
      
      return GeneralAnalytics(
        category: _convertApiCategory(apiCategory),
        total: (cat['total'] as num).toDouble(),
        percentage: (cat['percentage'] as num).toDouble(),
        color: CategoryStyles.getColorByApiString(apiCategory),
        icon: CategoryStyles.getIconByApiString(apiCategory),
      );
    }).toList();
  }

  List<CategoryAnalytics> _mapApiToCategoryAnalytics(
  Map<String, dynamic> apiData
  ) {
    final List<CategoryAnalytics> result = [];
    
    // Извлекаем подписки из API-ответа
    final subscriptions = apiData['subscriptions'] as List<dynamic>;
    
    // Преобразуем каждую подписку
    for (var sub in subscriptions) {
      final subTotal = (sub['total'] as num).toDouble();
      
      result.add(CategoryAnalytics(
        subscriptionId: sub['id'].toString(),
        name: sub['name'].toString(),
        total: subTotal,
        percentage: (sub['percentage'] as num).toDouble(), 
        color: _generateColorForSubscription(sub['id'].toString()),
      ));
    }
    
    return result;
  }

  // Генерация цвета на основе ID подписки
  Color _generateColorForSubscription(String id) {
    final hash = id.hashCode;
    return Color(hash & 0xFFFFFF).withOpacity(1.0);
  }

  
  // Конвертация API категории в SubscriptionCategory
  SubscriptionCategory _convertApiCategory(String apiCategory) {
    switch (apiCategory) {
      case 'music': return SubscriptionCategory.music;
      case 'video': return SubscriptionCategory.video;
      case 'books': return SubscriptionCategory.books;
      case 'games': return SubscriptionCategory.games;
      case 'education': return SubscriptionCategory.education;
      case 'social': return SubscriptionCategory.social;
      default: return SubscriptionCategory.other;
    }
  }
}