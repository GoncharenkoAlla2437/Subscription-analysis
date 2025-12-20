// lib/screens/archive_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/subscription.dart';
import '../providers/subscription_provider.dart';

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({Key? key}) : super(key: key); // Убираем required subscriptions

  @override
  Widget build(BuildContext context) {
    // Получаем архивные подписки из провайдера
    final subscriptionProvider = context.watch<SubscriptionProvider>();
    final archivedSubscriptions = subscriptionProvider.archivedSubscriptions;

    return Scaffold(
      backgroundColor: Color.fromARGB(248, 223, 218, 245),
      appBar: AppBar(
        title: Text('Архив подписок'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: archivedSubscriptions.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: archivedSubscriptions.length,
              itemBuilder: (context, index) {
                final subscription = archivedSubscriptions[index];
                return _buildArchivedSubscriptionItem(subscription);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.archive,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 20),
          Text(
            'Архив пуст',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Здесь будут ваши завершенные подписки',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchivedSubscriptionItem(Subscription subscription) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Верхняя строка с информацией
            Row(
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
                        'Категория: ${subscription.category.toString().split('.').last}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Заархивирована: ${DateFormat('dd.MM.yyyy').format(subscription.archivedDate!)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (subscription.currentAmount > 0)
                  Text(
                    '${subscription.currentAmount} руб.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
              ],
            ),
            
            // Дополнительная информация
            Padding(
              padding: EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Дата подключения:', 
                      DateFormat('dd.MM.yyyy').format(subscription.connectedDate)),
                  _buildDetailRow('Периодичность списаний:', subscription.billingCycleText),
                  
                  // История цен если есть изменения
                  if (subscription.priceHistory.length > 1) ...[
                    SizedBox(height: 8),
                    Text(
                      'История изменений цены:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 4),
                    ...subscription.priceHistory.map((history) => 
                      _buildPriceHistoryItem(history)
                    ).toList(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceHistoryItem(PriceHistory history) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Text(
            '${history.amount} руб.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 8),
          Text(
            'с ${DateFormat('dd.MM.yyyy').format(history.startDate)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          if (history.endDate != null) ...[
            Text(
              ' по ${DateFormat('dd.MM.yyyy').format(history.endDate!)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }
}