import 'package:flutter/material.dart';
import 'subscription.dart';

class AnalyticsPeriod {
  final String type; // 'month', 'quarter', 'year'
  final int? month;
  final int? quarter; 
  final int year;
  
  const AnalyticsPeriod({
    required this.type,
    this.month,
    this.quarter,
    required this.year,
  });
  String get description {
    switch (type) {
      case 'month':
        final monthNames = [
          'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
          'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
        ];
        return '${monthNames[(month ?? 1) - 1]} $year';
      case 'quarter':
        return '$quarter квартал $year';
      case 'year':
        return 'Год $year';
      default:
        return '$type $year';
    }
  }

  String get shortDescription {
    switch (type) {
      case 'month':
        return '${_monthName(month)} $year';
      case 'quarter':
        return 'Q$quarter $year';
      case 'year':
        return year.toString();
      default:
        return type;
    }
  }
  String _monthName(int? month) {
    const names = ['янв', 'фев', 'мар', 'апр', 'май', 'июн', 
                    'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
    return names[(month ?? 1) - 1];
  }
}

class GeneralAnalytics {
  final SubscriptionCategory category;
  final double total;  // Сумма по этой категории за период
  final double percentage;
  final Color color;
  final IconData icon;
  
  const GeneralAnalytics({
    required this.category,
    required this.total,
    required this.percentage,
    required this.color,
    required this.icon,
  });
}

class CategoryAnalytics {
  final String subscriptionId;
  final String name;
  final double total;  // Сумма по этой подписке за период
  final double percentage;  // Процент от общей суммы подписок за период
  final Color color;  // Цвет для отображения в диаграмме

  const CategoryAnalytics({
    required this.subscriptionId,
    required this.name,
    required this.total,
    required this.percentage,  // Рассчитывается на основе total и суммы категории
    required this.color,
  });
}