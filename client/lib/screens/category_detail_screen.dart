import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/analytics_provider.dart';
import '../models/subscription.dart';
import '../models/analytics.dart';


class CategoryDetailScreen extends StatefulWidget {
  final SubscriptionCategory category;
  final String categoryName;

  const CategoryDetailScreen({
    Key? key,
    required this.category,
    required this.categoryName,
  }) : super(key: key);

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _touchedIndex = -1;

  String _getCategoryApiName(SubscriptionCategory category) {
    switch (category) {
      case SubscriptionCategory.music: return 'music';
      case SubscriptionCategory.video: return 'video';
      case SubscriptionCategory.books: return 'books';
      case SubscriptionCategory.games: return 'games';
      case SubscriptionCategory.education: return 'education';
      case SubscriptionCategory.social: return 'social';
      case SubscriptionCategory.other: return 'other';
      default: return 'other';
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    key: _scaffoldKey,
    backgroundColor: const Color.fromARGB(248, 223, 218, 245),
    appBar: AppBar(
      title: Text(widget.categoryName),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.black),
          onPressed: () {
            final provider = context.read<AnalyticsProvider>();
            provider.loadCategoryAnalytics(_getCategoryApiName(widget.category));
          },
        ),
      ],
    ),
    body: Consumer<AnalyticsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingDetails) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.detailsError != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    provider.detailsError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.loadCategoryAnalytics(_getCategoryApiName(widget.category)),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        }

        final details = provider.categoryDetails;
        if (details == null || details.isEmpty) {
          return const Center(
            child: Text('Нет данных по подпискам в этой категории'),
          );
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Общая сумма по категории
                _buildHeader(provider),
                const SizedBox(height: 32),
                
                // Круговая диаграмма по подпискам
                _buildPieChart(details),
                const SizedBox(height: 32),
                
                // Список подписок
                _buildSubscriptionsList(details),
              ],
            ),
          ),
        );
      },
    ),
  );
}

  Widget _buildHeader(AnalyticsProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${provider.totalAmountByCategory.toStringAsFixed(0)} ₽',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _getCurrentPeriodText(provider),
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart(List<CategoryAnalytics> details) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    pieTouchResponse == null ||
                    pieTouchResponse.touchedSection == null) {
                  _touchedIndex = -1;
                  return;
                }
                _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
              });
            },
          ),
          sectionsSpace: 2,
          centerSpaceRadius: 50,
          sections: details.asMap().entries.map((entry) {
            final index = entry.key;
            final subscription = entry.value;
            final isTouched = index == _touchedIndex;
            final fontSize = isTouched ? 16.0 : 14.0;
            final radius = isTouched ? 70.0 : 60.0;

            return PieChartSectionData(
              color: subscription.color,
              value: subscription.total,
              title: '${subscription.percentage.toInt()}%',
              radius: radius,
              titleStyle: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSubscriptionsList(List<CategoryAnalytics> details) {
    return Column(
      children: details.map((subscription) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: subscription.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.monetization_on,
                  color: subscription.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${subscription.total.toStringAsFixed(1)} ₽',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${subscription.percentage.toInt()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getCurrentPeriodText(AnalyticsProvider provider) {
    final period = provider.currentPeriod;
    
    if (period.type == 'month' && period.month != null) {
      final months = [
        'январь', 'февраль', 'март', 'апрель', 'май', 'июнь',
        'июль', 'август', 'сентябрь', 'октябрь', 'ноябрь', 'декабрь'
      ];
      return months[period.month! - 1];
    } else if (period.type == 'quarter' && period.quarter != null) {
      return '${period.quarter}-й квартал ${period.year}';
    } else {
      return '${period.year} год';
    }
  }
}