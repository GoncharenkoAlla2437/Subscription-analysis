import 'package:flutter/material.dart';
import 'dart:math';
// class AnalyticsScreen extends StatelessWidget {
//   const AnalyticsScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Аналитика')),
//       body: Center(child: Text('Аналитика - в разработке')),
//     );
//   }
// }

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  AnalyticsScreenState createState() => AnalyticsScreenState();
}

class AnalyticsScreenState extends State<AnalyticsScreen> {
  String selectedPeriod = 'месяц';
  String selectedMonth = 'сентябрь';
  String selectedQuarter = '1 квартал';
  String selectedYear = '2024';

  // Данные для разных периодов
  final Map<String, List<Category>> periodData = {
    'месяц': [
      Category(name: 'Кино', amount: 2120, color: const Color(0xFFFF6B6B), icon: Icons.movie),
      Category(name: 'Книги', amount: 1060, color: const Color(0xFF4ECDC4), icon: Icons.book),
      Category(name: 'Музыка', amount: 795, color: const Color(0xFF45B7D1), icon: Icons.music_note),
      Category(name: 'Еда', amount: 795, color: const Color(0xFF96CEB4), icon: Icons.restaurant),
      Category(name: 'Другое', amount: 530, color: const Color(0xFFFFEAA7), icon: Icons.more_horiz),
    ],
    'квартал': [
      Category(name: 'Кино', amount: 5800, color: const Color(0xFFFF6B6B), icon: Icons.movie),
      Category(name: 'Книги', amount: 3200, color: const Color(0xFF4ECDC4), icon: Icons.book),
      Category(name: 'Транспорт', amount: 2500, color: const Color(0xFF9966CC), icon: Icons.directions_car),
      Category(name: 'Еда', amount: 4200, color: const Color(0xFF96CEB4), icon: Icons.restaurant),
      Category(name: 'Развлечения', amount: 1800, color: const Color(0xFFFFA500), icon: Icons.celebration),
    ],
    'год': [
      Category(name: 'Кино', amount: 21500, color: const Color(0xFFFF6B6B), icon: Icons.movie),
      Category(name: 'Книги', amount: 12800, color: const Color(0xFF4ECDC4), icon: Icons.book),
      Category(name: 'Путешествия', amount: 45000, color: const Color(0xFF32CD32), icon: Icons.flight),
      Category(name: 'Еда', amount: 16800, color: const Color(0xFF96CEB4), icon: Icons.restaurant),
      Category(name: 'Техника', amount: 32000, color: const Color(0xFF808080), icon: Icons.computer),
    ],
  };

  // Данные для детальной аналитики по категориям
  final Map<String, List<SubCategory>> detailedData = {
    'Кино': [
      SubCategory(name: 'Кинопоиск', amount: 850, color: const Color(0xFFFF6B6B)),
      SubCategory(name: 'Okko', amount: 670, color: const Color(0xFFFF8E53)),
      SubCategory(name: 'Иви', amount: 450, color: const Color(0xFFFFB6C1)),
      SubCategory(name: 'More.tv', amount: 150, color: const Color(0xFFFFD700)),
    ],
    'Музыка': [
      SubCategory(name: 'Яндекс Музыка', amount: 450, color: const Color(0xFF45B7D1)),
      SubCategory(name: 'Spotify', amount: 220, color: const Color(0xFF1DB954)),
      SubCategory(name: 'VK Музыка', amount: 125, color: const Color(0xFF0077FF)),
    ],
    'Книги': [
      SubCategory(name: 'Литрес', amount: 680, color: const Color(0xFF4ECDC4)),
      SubCategory(name: 'MyBook', amount: 280, color: const Color(0xFF20B2AA)),
      SubCategory(name: 'Bookmate', amount: 100, color: const Color(0xFF00CED1)),
    ],
    'Еда': [
      SubCategory(name: 'Delivery Club', amount: 320, color: const Color(0xFF96CEB4)),
      SubCategory(name: 'Yandex Eda', amount: 280, color: const Color(0xFFFF6B6B)),
      SubCategory(name: 'Самовывоз', amount: 195, color: const Color(0xFF32CD32)),
    ],
  };

  List<Category> get currentCategories => periodData[selectedPeriod] ?? [];
  double get totalAmount => currentCategories.fold(0, (sum, category) => sum + category.amount);
  






  void _navigateToCategoryDetail(String categoryName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryDetailScreen(
          categoryName: categoryName,
          subCategories: detailedData[categoryName] ?? [],
          selectedPeriod: selectedPeriod,
          selectedMonth: selectedMonth,
          selectedQuarter: selectedQuarter,
          selectedYear: selectedYear,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(248, 223, 218, 245),
      appBar: AppBar(
        title: Text('Аналитика'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Верхняя панель
              // Container(
              //   width: double.infinity,
              //   height: 120,
              //   decoration: BoxDecoration(
              //     gradient: const LinearGradient(
              //       colors: [Color(0xFF9C27B0), Color(0xFFE1BEE7)],
              //       begin: Alignment.topLeft,
              //       end: Alignment.bottomRight,
              //     ),
              //     borderRadius: const BorderRadius.only(
              //       bottomLeft: Radius.circular(20),
              //       bottomRight: Radius.circular(20),
              //     ),
              //   ),
              //   child: const Center(
              //     child: Text(
              //       'Аналитика',
              //       style: TextStyle(
              //         color: Colors.white,
              //         fontSize: 28,
              //         fontWeight: FontWeight.bold,
              //       ),
              //     ),
              //   ),
              // ),

              const SizedBox(height: 20),

              // Общая сумма
              Text(
                '${totalAmount.toInt()} ₽',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7B1FA2),
                ),
              ),

              const SizedBox(height: 10),

              

              // ВЫБОР КОНКРЕТНОГО ПЕРИОДА
              _buildPeriodSelector(),

              const SizedBox(height: 20),

              // Диаграмма банковского стиля
              SizedBox(
                height: 280,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 240,
                      height: 240,
                      child: CustomPaint(
                        painter: BankingPieChartPainter(
                          currentCategories, 
                          totalAmount,
                          strokeWidth: 16.0,
                        ),
                      ),
                    ),
                    
                    // Центральный текст
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${totalAmount.toInt()} ₽',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7B1FA2),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedPeriod == 'месяц' 
                              ? selectedMonth
                              : selectedPeriod == 'квартал'
                                  ? selectedQuarter
                                  : selectedYear,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              // ВЫБОР ПЕРИОДА (месяц/квартал/год)
              _buildPeriodTabs(),

              const SizedBox(height: 10),


//_______________________________________________________


              // Список категорий (кликабельный)
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: currentCategories.map((category) {
                    final percentage = (category.amount / totalAmount * 100).toInt();
                    return InkWell(
                      onTap: () => _navigateToCategoryDetail(category.name),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: category.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                category.name,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            Text(
                              '${category.amount} ₽',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$percentage%',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildPeriodTab('месяц'),
          _buildPeriodTab('квартал'),
          _buildPeriodTab('год'),
        ],
      ),
    );
  }
//______________________________________________________________


  Widget _buildPeriodTab(String period) {
    final isSelected = selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedPeriod = period;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF7B1FA2) : Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            period,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF7B1FA2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    switch (selectedPeriod) {
      case 'месяц':
        return MonthSelector(
          selectedMonth: selectedMonth,
          onMonthChanged: (month) {
            setState(() {
              selectedMonth = month;
            });
          },
        );
      case 'квартал':
        return QuarterSelector(
          selectedQuarter: selectedQuarter,
          onQuarterChanged: (quarter) {
            setState(() {
              selectedQuarter = quarter;
            });
          },
        );
      case 'год':
        return YearSelector(
          selectedYear: selectedYear,
          onYearChanged: (year) {
            setState(() {
              selectedYear = year;
            });
          },
        );
      default:
        return const SizedBox();
    }
  }
}

class CategoryDetailScreen extends StatelessWidget {
  final String categoryName;
  final List<SubCategory> subCategories;
  final String selectedPeriod;
  final String selectedMonth;
  final String selectedQuarter;
  final String selectedYear;

  const CategoryDetailScreen({
    super.key,
    required this.categoryName,
    required this.subCategories,
    required this.selectedPeriod,
    required this.selectedMonth,
    required this.selectedQuarter,
    required this.selectedYear,
  });

  @override
  Widget build(BuildContext context) {
    final totalAmount = subCategories.fold(0.0, (sum, sub) => sum + sub.amount);

    return Scaffold(
      appBar: AppBar(
        title: Text('Аналитика: $categoryName'),
        backgroundColor: const Color(0xFF9C27B0),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Общая сумма по категории
              Text(
                '${totalAmount.toInt()} ₽',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7B1FA2),
                ),
              ),

              const SizedBox(height: 10),
              Text(
                'Всего за $categoryName',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 10),

              // Селектор периода для детального экрана
              _buildDetailPeriodSelector(),

              const SizedBox(height: 20),
//______________________________________________


              // Диаграмма для подкатегорий
              SizedBox(
                height: 280,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 240,
                      height: 240,
                      child: CustomPaint(
                        painter: BankingPieChartPainter(
                          subCategories.map((sub) => Category(
                            name: sub.name,
                            amount: sub.amount.toDouble(),
                            color: sub.color,
                            icon: Icons.circle,
                          )).toList(),
                          totalAmount,
                          strokeWidth: 16.0,
                        ),
                      ),
                    ),
                    
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${totalAmount.toInt()} ₽',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7B1FA2),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          categoryName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Список подкатегорий
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: subCategories.map((subCategory) {
                    final percentage = (subCategory.amount / totalAmount * 100).toInt();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: subCategory.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              subCategory.name,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          Text(
                            '${subCategory.amount} ₽',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$percentage%',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );

                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailPeriodSelector() {
    switch (selectedPeriod) {
      case 'месяц':
        return MonthSelector(
          selectedMonth: selectedMonth,
          onMonthChanged: (month) {
            // Можно добавить обновление данных при изменении месяца
          },
        );
      case 'квартал':
        return QuarterSelector(
          selectedQuarter: selectedQuarter,
          onQuarterChanged: (quarter) {
            // Можно добавить обновление данных при изменении квартала
          },
        );
      case 'год':
        return YearSelector(
          selectedYear: selectedYear,
          onYearChanged: (year) {
            // Можно добавить обновление данных при изменении года
          },
        );
      default:
        return const SizedBox();
    }
  }
}

class Category {
  final String name;
  final double amount;
  final Color color;
  final IconData icon;

  const Category({
    required this.name,
    required this.amount,
    required this.color,
    required this.icon,
  });
}

class SubCategory {
  final String name;
  final int amount;
  final Color color;

  const SubCategory({
    required this.name,
    required this.amount,
    required this.color,
  });
}

class BankingPieChartPainter extends CustomPainter {
  final List<Category> categories;
  final double totalAmount;
  final double strokeWidth;

  const BankingPieChartPainter(
    this.categories,
    this.totalAmount, {
    this.strokeWidth = 15.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    double startAngle = -90.0;

    // Фоновая окружность (серый фон)
    final backgroundPaint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Рисуем сегменты как прогресс-бары
    for (final category in categories) {
      final percentage = category.amount / totalAmount;
      final sweepAngle = percentage * 360;

      final segmentPaint = Paint()
        ..color = category.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle * (pi / 180),
        sweepAngle * (pi / 180),
        false,
        segmentPaint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class MonthSelector extends StatefulWidget {
  final String selectedMonth;
  final Function(String) onMonthChanged;

  const MonthSelector({
    super.key,
    required this.selectedMonth,
    required this.onMonthChanged,
  });

  @override
  MonthSelectorState createState() => MonthSelectorState();
}

class MonthSelectorState extends State<MonthSelector> {
  bool _expanded = false;
  
  final List<String> months = [
    'январь', 'февраль', 'март', 'апрель', 'май', 'июнь',
    'июль', 'август', 'сентябрь', 'октябрь', 'ноябрь', 'декабрь'
  ];

//__________________________________________________


  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              widget.selectedMonth,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Icon(
              _expanded ? Icons.expand_less : Icons.expand_more,
              color: const Color(0xFF7B1FA2),
            ),
            onTap: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
          ),
          
          if (_expanded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 200,
              child: ListView.builder(
                itemCount: months.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(months[index]),
                    onTap: () {
                      widget.onMonthChanged(months[index]);
                      setState(() {
                        _expanded = false;
                      });
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class QuarterSelector extends StatefulWidget {
  final String selectedQuarter;
  final Function(String) onQuarterChanged;

  const QuarterSelector({
    super.key,
    required this.selectedQuarter,
    required this.onQuarterChanged,
  });

  @override
  QuarterSelectorState createState() => QuarterSelectorState();
}

class QuarterSelectorState extends State<QuarterSelector> {
  bool _expanded = false;
  
  final List<String> quarters = [
    '1 квартал',
    '2 квартал', 
    '3 квартал',
    '4 квартал'
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              widget.selectedQuarter,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Icon(
              _expanded ? Icons.expand_less : Icons.expand_more,
              color: const Color(0xFF7B1FA2),
            ),
            onTap: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
          ),
          
          if (_expanded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 160,
              child: ListView.builder(
                itemCount: quarters.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(quarters[index]),
                    onTap: () {
                      widget.onQuarterChanged(quarters[index]);
                      setState(() {
                        _expanded = false;
                      });
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class YearSelector extends StatefulWidget {
  final String selectedYear;
  final Function(String) onYearChanged;


  const YearSelector({
    super.key,
    required this.selectedYear,
    required this.onYearChanged,
  });

  @override
  YearSelectorState createState() => YearSelectorState();
}

class YearSelectorState extends State<YearSelector> {
  bool _expanded = false;
  
  final List<String> years = [
    '2024',
    '2023',
    '2022',
    '2021',
    '2020'
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              widget.selectedYear,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Icon(
              _expanded ? Icons.expand_less : Icons.expand_more,
              color: const Color(0xFF7B1FA2),
            ),
            onTap: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
          ),
          
          if (_expanded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 200,
              child: ListView.builder(
                itemCount: years.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(years[index]),
                    onTap: () {
                      widget.onYearChanged(years[index]);
                      setState(() {
                        _expanded = false;
                      });
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

