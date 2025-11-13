import 'package:flutter/material.dart';
import '../models/subscription.dart';

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