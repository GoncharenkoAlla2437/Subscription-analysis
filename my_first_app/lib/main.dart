import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Подписки',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SubscriptionsScreen(), 
    );
  }
}

class SubscriptionsScreen extends StatefulWidget {
  SubscriptionsScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  final List<Subscription> subscriptions = [
    Subscription(
      name: 'КиноПоиск',
      date: '20.09.2025',
      amount: 256,
      icon: Icons.movie_creation_outlined,
      color: Colors.orange,
      category: 'Видео',
    ),
    Subscription(
      name: 'Spotify',
      date: '23.09.2025',
      amount: 315,
      icon: Icons.music_note_outlined,
      color: Colors.green,
      category: 'Музыка',
    ),
    Subscription(
      name: 'Яндекс Музыка',
      date: '20.09.2025',
      amount: 256,
      icon: Icons.headphones_outlined,
      color: Colors.red,
      category: 'Музыка',
    ),
    Subscription(
      name: 'Кинотеатр Okko',
      date: '20.09.2025',
      amount: 256,
      icon: Icons.play_circle_outline,
      color: Colors.purple,
      category: 'Видео',
    ),
    Subscription(
      name: 'Литрес',
      date: '20.09.2025',
      amount: 256,
      icon: Icons.menu_book_outlined,
      color: Colors.blue,
      category: 'Книги',
    ),
    Subscription(
      name: 'Яндекс Книги',
      date: '20.09.2025',
      amount: 256,
      icon: Icons.book_outlined,
      color: Colors.blue[800]!,
      category: 'Книги',
    ),
    Subscription(
      name: 'СберПрайм',
      date: '20.09.2025',
      amount: 256,
      icon: Icons.diamond_outlined,
      color: Colors.green[700]!,
      category: 'Другое',
    ),
    Subscription(
      name: 'VK',
      date: '20.09.2025',
      amount: 199,
      icon: Icons.chat_outlined,
      color: Colors.blue[400]!,
      category: 'Соцсети',
    ),
  ];

  final List<String> categories = ['Все', 'Музыка', 'Видео', 'Книги', 'Соцсети', 'Другое'];
  String selectedCategory = 'Все';

  // Функция для показа модального окна добавления подписки
  void _showAddSubscriptionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddSubscriptionModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Фильтрация подписок по выбранной категории
    final filteredSubscriptions = selectedCategory == 'Все'
        ? subscriptions
        : subscriptions.where((sub) => sub.category == selectedCategory).toList();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Color.fromARGB(248, 223, 218, 245),
      appBar: AppBar(
        title: Text('Мои подписки'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              // Открываем правую боковую панель
              _scaffoldKey.currentState!.openEndDrawer();
            },
          ),
        ],
      ),
      
      // ЗАМЕНА: используем endDrawer вместо drawer для правой панели
      endDrawer: _buildDrawer(context),
      
      // Кнопка добавления новой подписки
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSubscriptionModal,
        backgroundColor: Colors.blue,
        child: Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      body: Column(
        children: [
          // Горизонтальная полоска с категориями
          Container(
            height: 60,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (context, index) => SizedBox(width: 12),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category == selectedCategory;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = category;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Список подписок
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.all(16),
              itemCount: filteredSubscriptions.length,
              separatorBuilder: (context, index) => Divider(
                height: 24,
                thickness: 1,
                color: Colors.grey[300],
              ),
              itemBuilder: (context, index) {
                final subscription = filteredSubscriptions[index];
                return SubscriptionItem(subscription: subscription);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Функция для построения боковой панели
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      // Добавляем выравнивание для правой панели
      child: SafeArea(
        child: Column(
          children: [
            // Заголовок боковой панели
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              color: Colors.blue,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 25,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Пользователь',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'user@example.com',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            // Пункты меню
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    icon: Icons.subscriptions,
                    title: 'Подписки',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.person,
                    title: 'Личный кабинет',
                    onTap: () {
                      Navigator.pop(context);
                      _showComingSoonMessage(context, 'Личный кабинет');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.analytics,
                    title: 'Аналитика',
                    onTap: () {
                      Navigator.pop(context);
                      _showComingSoonMessage(context, 'Аналитика');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.notifications,
                    title: 'Уведомления',
                    onTap: () {
                      Navigator.pop(context);
                      _showComingSoonMessage(context, 'Уведомления');
                    },
                  ),
                  
                  // Разделитель
                  Divider(height: 24, thickness: 1),
                  
                  _buildDrawerItem(
                    icon: Icons.exit_to_app,
                    title: 'Выйти',
                    onTap: () {
                      Navigator.pop(context);
                      _showLogoutDialog(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Вспомогательная функция для создания пунктов меню
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(fontSize: 16),
      ),
      onTap: onTap,
    );
  }

  // Функция для показа сообщения "Скоро будет"
  void _showComingSoonMessage(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - скоро будет доступно!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Функция для показа диалога выхода
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Выход'),
          content: Text('Вы уверены, что хотите выйти?'),
          actions: [
            TextButton(
              child: Text('Отмена'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Выйти', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _showComingSoonMessage(context, 'Выход');
              },
            ),
          ],
        );
      },
    );
  }
}

// Модальное окно для добавления новой подписки
class AddSubscriptionModal extends StatefulWidget {
  @override
  _AddSubscriptionModalState createState() => _AddSubscriptionModalState();
}

class _AddSubscriptionModalState extends State<AddSubscriptionModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();
  
  bool _isTrial = false;
  DateTime? _selectedDate;

  // Функция для выбора даты
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = "${picked.day}.${picked.month}.${picked.year}";
      });
    }
  }

  // Функция для добавления подписки
  void _addSubscription() {
    if (_formKey.currentState!.validate()) {
      // Здесь будет логика сохранения подписки
      print('Добавлена подписка:');
      print('Название: ${_nameController.text}');
      print('Стоимость: ${_amountController.text}');
      print('Дата: ${_dateController.text}');
      print('Пробная: $_isTrial');
      print('Оповещение за: ${_daysController.text} дней');
      
      // Закрываем модальное окно
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок
              Center(
                child: Text(
                  'Добавить подписку',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 24),
              
              // Поле "Название"
              Text(
                'Название',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Введите название подписки',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите название';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              // Поле "Стоимость"
              Text(
                'Стоимость',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Введите стоимость',
                  border: OutlineInputBorder(),
                  suffixText: 'руб.',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите стоимость';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Пожалуйста, введите число';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              // Поле "Дата оплаты"
              Text(
                'Дата оплаты',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: _selectDate,
                decoration: InputDecoration(
                  hintText: 'Выберите дату',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, выберите дату';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              // Чекбокс "Пробная подписка"
              Row(
                children: [
                  Checkbox(
                    value: _isTrial,
                    onChanged: (bool? value) {
                      setState(() {
                        _isTrial = value ?? false;
                      });
                    },
                  ),
                  Text('Пробная подписка'),
                ],
              ),
              SizedBox(height: 16),
              
              // Поле "Оповестить за ___ дней"
              Text(
                'Оповестить за',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _daysController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Количество дней',
                  border: OutlineInputBorder(),
                  suffixText: 'дней',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите количество дней';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Пожалуйста, введите число';
                  }
                  return null;
                },
              ),
              SizedBox(height: 32),
              
              // Кнопка "Добавить подписку"
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _addSubscription,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Добавить подписку',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _daysController.dispose();
    super.dispose();
  }
}

class Subscription {
  final String name;
  final String date;
  final int? amount;
  final IconData icon;
  final Color color;
  final String category;

  Subscription({
    required this.name,
    required this.date,
    this.amount,
    required this.icon,
    required this.color,
    required this.category,
  });
}

class SubscriptionItem extends StatelessWidget {
  final Subscription subscription;

  const SubscriptionItem({Key? key, required this.subscription}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: subscription.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            subscription.icon,
            color: subscription.color,
            size: 24,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subscription.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Дата списания: ${subscription.date}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        if (subscription.amount != null)
          Text(
            '${subscription.amount} руб.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
      ],
    );
  }
}