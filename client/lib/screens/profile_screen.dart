// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'archive_screen.dart';
import '../providers/subscription_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key); // Убираем required subscriptions

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Начальные данные пользователя
  String _userName = "Иван Иванов";
  String _userEmail = "ivan@example.com";
  String _userPhone = "+7 (900) 123-45-67";
  String _avatarUrl = "https://via.placeholder.com/150";

  @override
  void initState() {
    super.initState();
    _nameController.text = _userName;
    _emailController.text = _userEmail;
    _phoneController.text = _userPhone;
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _saveChanges();
      }
    });
  }

  void _saveChanges() {
    setState(() {
      _userName = _nameController.text;
      _userEmail = _emailController.text;
      _userPhone = _phoneController.text;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Изменения сохранены')),
    );
  }

  void _navigateToArchive() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArchiveScreen(), // Без параметра
      ),
    );
  }

  void _changeAvatar() {
    if (_isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Функция смены аватарки в разработке')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Получаем провайдер подписок для отображения количества архивных
    final subscriptionProvider = context.watch<SubscriptionProvider>();
    final archivedCount = subscriptionProvider.archivedSubscriptions.length;

    return Scaffold(
      backgroundColor: Color.fromARGB(248, 223, 218, 245),
      appBar: AppBar(
        title: Text('Личный кабинет'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.check : Icons.edit,
              color: Colors.black,
            ),
            onPressed: _toggleEditing,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            // Аватарка с иконкой редактирования
            Stack(
              children: [
                GestureDetector(
                  onTap: _changeAvatar,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(_avatarUrl),
                    backgroundColor: Colors.grey[300],
                  ),
                ),
                if (_isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 24),

            // Имя пользователя
            _buildEditableField(
              label: 'Имя',
              value: _userName,
              controller: _nameController,
              isEditing: _isEditing,
              icon: Icons.person,
            ),
            SizedBox(height: 20),

            // Email
            _buildEditableField(
              label: 'Email',
              value: _userEmail,
              controller: _emailController,
              isEditing: _isEditing,
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),

            // Телефон
            _buildEditableField(
              label: 'Телефон',
              value: _userPhone,
              controller: _phoneController,
              isEditing: _isEditing,
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 32),

            // Архив подписок
            _buildArchiveButton(archivedCount),
          ],
        ),
      ),
    );
  }

  // Виджет для редактируемого поля
  Widget _buildEditableField({
    required String label,
    required String value,
    required TextEditingController controller,
    required bool isEditing,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(icon, color: Colors.grey[500], size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: isEditing
                      ? TextField(
                          controller: controller,
                          keyboardType: keyboardType,
                          style: TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Введите $label',
                          ),
                        )
                      : Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            value,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Кнопка архива подписок
  Widget _buildArchiveButton(int archivedCount) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(Icons.archive, color: Colors.blue),
        title: Text(
          'Архив подписок',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (archivedCount > 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  archivedCount.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
        onTap: _navigateToArchive,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}