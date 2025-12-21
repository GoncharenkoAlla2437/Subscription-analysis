// client/lib/utils/category_styles.dart
import 'package:flutter/material.dart';
import '../../models/subscription.dart'; // для SubscriptionCategory

class CategoryStyles {
  // ========== ЦВЕТА ДЛЯ КАТЕГОРИЙ ==========
  // Сопоставление API-категорий с цветами
  static final Map<String, Color> _apiColors = {
    'music': Colors.blue,
    'video': Colors.red,
    'books': Colors.green,
    'games': Colors.orange,
    'education': Colors.purple,
    'social': Colors.teal,
    'other': Colors.grey,
    'news': Colors.indigo,
    'fitness': Colors.lightGreen,
  };

  // Сопоставление SubscriptionCategory с цветами (для использования внутри приложения)
  static final Map<SubscriptionCategory, Color> _categoryColors = {
    SubscriptionCategory.music: Colors.blue,
    SubscriptionCategory.video: Colors.red,
    SubscriptionCategory.books: Colors.green,
    SubscriptionCategory.games: Colors.orange,
    SubscriptionCategory.education: Colors.purple,
    SubscriptionCategory.social: Colors.teal,
    SubscriptionCategory.other: Colors.grey,
  };

  // ========== ИКОНКИ ДЛЯ КАТЕГОРИЙ ==========
  // Сопоставление API-категорий с иконками
  static final Map<String, IconData> _apiIcons = {
    'music': Icons.music_note,
    'video': Icons.videocam,
    'books': Icons.book,
    'games': Icons.videogame_asset,
    'education': Icons.school,
    'social': Icons.people,
    'other': Icons.category,
    'news': Icons.article,
    'fitness': Icons.fitness_center,
  };

  // Сопоставление SubscriptionCategory с иконками
  static final Map<SubscriptionCategory, IconData> _categoryIcons = {
    SubscriptionCategory.music: Icons.music_note,
    SubscriptionCategory.video: Icons.videocam,
    SubscriptionCategory.books: Icons.book,
    SubscriptionCategory.games: Icons.videogame_asset,
    SubscriptionCategory.education: Icons.school,
    SubscriptionCategory.social: Icons.people,
    SubscriptionCategory.other: Icons.category,
  };

  // ========== МЕТОДЫ ДЛЯ API-КАТЕГОРИЙ (строковые) ==========

  /// Получить цвет по API-категории (строка)
  static Color getColorByApiString(String apiCategory) {
    return _apiColors[apiCategory.toLowerCase()] ?? Colors.grey;
  }

  /// Получить иконку по API-категории (строка)
  static IconData getIconByApiString(String apiCategory) {
    return _apiIcons[apiCategory.toLowerCase()] ?? Icons.category;
  }

  // ========== МЕТОДЫ ДЛЯ SubscriptionCategory ==========

  /// Получить цвет по SubscriptionCategory
  static Color getColorByCategory(SubscriptionCategory category) {
    return _categoryColors[category] ?? Colors.grey;
  }

  /// Получить иконку по SubscriptionCategory
  static IconData getIconByCategory(SubscriptionCategory category) {
    return _categoryIcons[category] ?? Icons.category;
  }

  // ========== КОНВЕРТАЦИЯ КАТЕГОРИЙ ==========

  /// Конвертировать API-строку в SubscriptionCategory
  static SubscriptionCategory apiStringToCategory(String apiCategory) {
    switch (apiCategory.toLowerCase()) {
      case 'music':
        return SubscriptionCategory.music;
      case 'video':
        return SubscriptionCategory.video;
      case 'books':
        return SubscriptionCategory.books;
      case 'games':
        return SubscriptionCategory.games;
      case 'education':
        return SubscriptionCategory.education;
      case 'social':
        return SubscriptionCategory.social;
      case 'news':
      case 'fitness':
      case 'other':
      default:
        return SubscriptionCategory.other;
    }
  }

  /// Конвертировать SubscriptionCategory в API-строку
  static String categoryToApiString(SubscriptionCategory category) {
    switch (category) {
      case SubscriptionCategory.music:
        return 'music';
      case SubscriptionCategory.video:
        return 'video';
      case SubscriptionCategory.books:
        return 'books';
      case SubscriptionCategory.games:
        return 'games';
      case SubscriptionCategory.education:
        return 'education';
      case SubscriptionCategory.social:
        return 'social';
      case SubscriptionCategory.other:
        return 'other';
    }
  }

  // ========== ПОЛУЧЕНИЕ СЛУЧАЙНЫХ ЦВЕТОВ ==========

  /// Генерация случайного цвета на основе строки (например, ID подписки)
  static Color getRandomColorFromString(String seedString) {
    // Используем hash код строки для генерации предсказуемого "случайного" цвета
    final hash = seedString.hashCode;
    final hue = (hash % 360).abs(); // 0-360 для HSL
    return HSLColor.fromAHSL(1.0, hue.toDouble(), 0.7, 0.6).toColor();
  }

  // ========== ПОЛУЧЕНИЕ ВСЕХ ЦВЕТОВ ==========

  /// Получить список всех цветов для категорий
  static List<Color> getAllCategoryColors() {
    return _categoryColors.values.toList();
  }

  /// Получить список всех цветов для API-категорий
  static List<Color> getAllApiColors() {
    return _apiColors.values.toList();
  }
}