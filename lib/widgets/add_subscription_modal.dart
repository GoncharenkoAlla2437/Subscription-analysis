import 'package:flutter/material.dart';


// Модальное окно для добавления новой подписки
class AddSubscriptionModal extends StatefulWidget {
  @override
  State<AddSubscriptionModal> createState() => _AddSubscriptionModalState();
}

class _AddSubscriptionModalState extends State<AddSubscriptionModal> { // приватный state класс
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
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
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
                SizedBox(height: 16),
              ],
            ),
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

