import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fl_chart/fl_chart.dart';
import '../providers/analytics_provider.dart';
import '../models/subscription.dart';
import '../widgets/app_drawer.dart';
import 'category_detail_screen.dart';


class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AnalyticsProvider>();
      provider.loadGeneralAnalytics();
    });
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    key: _scaffoldKey,
    backgroundColor: const Color.fromARGB(248, 223, 218, 245),
    appBar: AppBar(
      title: const Text(
        'Аналитика',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      actions: [
        if (!kIsWeb)
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => _scaffoldKey.currentState!.openEndDrawer(),
          ),
      ],
    ),
    
    endDrawer: kIsWeb ? null : const AppDrawer(
      currentScreen: AppScreen.analytics,
      isMobile: true,
    ),
    
    body: kIsWeb 
      ? Row(
          children: [
            const AppDrawer(
              currentScreen: AppScreen.analytics,
              isMobile: false,
            ),
            Expanded(
              child: _buildBody(context),
            ),
          ],
        )
      : _buildBody(context),
  );
}

  Widget _buildBody(BuildContext context) {
    return Consumer<AnalyticsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Ошибка загрузки аналитики',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: provider.loadGeneralAnalytics,
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: kIsWeb ? 32 : 16,
              vertical: kIsWeb ? 24 : 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок с общей суммой
                _buildHeader(provider),
                const SizedBox(height: kIsWeb ? 32 : 24),
                
                // Переключатель периода
                _buildPeriodSelector(provider),
                const SizedBox(height: kIsWeb ? 40 : 32),
                
                // Круговая диаграмма по категориям
                _buildPieChart(provider),
                const SizedBox(height: kIsWeb ? 40 : 32),
                
                // Список категорий
                _buildCategoriesList(context, provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(AnalyticsProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${provider.totalAmount.toStringAsFixed(0)} ₽',
          style: TextStyle(
            fontSize: kIsWeb ? 40 : 32,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _getCurrentPeriodText(provider),
          style: TextStyle(
            fontSize: kIsWeb ? 18 : 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector(AnalyticsProvider provider) {
    final periods = ['месяц', 'квартал', 'год'];
    final currentType = provider.currentPeriod.type;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: periods.map((type) {
          final isSelected = currentType == type;
          return Expanded(
            child: GestureDetector(
              onTap: () => provider.setPeriodType(type),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: kIsWeb ? 16 : 12,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  type,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: kIsWeb ? 16 : 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? Colors.black : Colors.grey[600],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPieChart(AnalyticsProvider provider) {
    if (provider.generalAnalytics.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('Нет данных для диаграммы'),
        ),
      );
    }

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
          sections: provider.generalAnalytics.asMap().entries.map((entry) {
            final index = entry.key;
            final category = entry.value;
            final isTouched = index == _touchedIndex;
            final fontSize = isTouched ? 16.0 : 14.0;
            final radius = isTouched ? 70.0 : 60.0;

            return PieChartSectionData(
              color: category.color,
              value: category.total,
              title: '${category.percentage.toInt()}%',
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

  Widget _buildCategoriesList(BuildContext context, AnalyticsProvider provider) {
    if (provider.generalAnalytics.isEmpty) {
      return const Center(
        child: Text('Нет категорий для отображения'),
      );
    }

    return Column(
      children: provider.generalAnalytics.map((category) {
        return GestureDetector(
          onTap: () => _navigateToCategoryDetail(context, category.category),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(kIsWeb ? 20 : 16),
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
                  width: kIsWeb ? 48 : 40,
                  height: kIsWeb ? 48 : 40,
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    category.icon,
                    color: category.color,
                    size: kIsWeb ? 28 : 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getCategoryDisplayName(category.category),
                        style: TextStyle(
                          fontSize: kIsWeb ? 18 : 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${category.total.toStringAsFixed(1)} ₽',
                        style: TextStyle(
                          fontSize: kIsWeb ? 16 : 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${category.percentage.toInt()}%',
                  style: TextStyle(
                    fontSize: kIsWeb ? 18 : 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _navigateToCategoryDetail(BuildContext context, SubscriptionCategory category) {
    final categoryName = _getCategoryApiName(category);
    final provider = context.read<AnalyticsProvider>();
    
    provider.loadCategoryAnalytics(categoryName).then((_) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CategoryDetailScreen(
            category: category,
            categoryName: _getCategoryDisplayName(category),
          ),
        ),
      );
    });
  }

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

  String _getCategoryDisplayName(SubscriptionCategory category) {
    switch (category) {
      case SubscriptionCategory.music: return 'Музыка';
      case SubscriptionCategory.video: return 'Кино';
      case SubscriptionCategory.books: return 'Книги';
      case SubscriptionCategory.games: return 'Игры';
      case SubscriptionCategory.education: return 'Обучение';
      case SubscriptionCategory.social: return 'Соцсети';
      case SubscriptionCategory.other: return 'Прочее';
      default: return 'Неизвестно';
    }
  }
}