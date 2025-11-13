import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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

class SubscriptionsScreen extends StatelessWidget {
  final List<Subscription> subscriptions = [
    Subscription(
      name: 'КиноПоиск',
      date: '20.09.2025',
      amount: 256,
      icon: Icons.movie_creation_outlined,
      color: Colors.orange,
    ),
    Subscription(
      name: 'Spotify',
      date: '23.09.2025',
      amount: 315,
      icon: Icons.music_note_outlined,
      color: Colors.green,
    ),
    Subscription(
      name: 'Яндекс Музыка',
      date: '20.09.2025',
      amount: 256,
      icon: Icons.headphones_outlined,
      color: Colors.red,
    ),
    Subscription(
      name: 'Кинотеатр Okko',
      date: '20.09.2025',
      amount: 256,
      icon: Icons.play_circle_outline,
      color: Colors.purple,
    ),
    Subscription(
      name: 'Литрес',
      date: '20.09.2025',
      amount: 256,
      icon: Icons.menu_book_outlined,
      color: Colors.blue,
    ),
    Subscription(
      name: 'Яндекс Книги',
      date: '20.09.2025',
      amount: 256,
      icon: Icons.book_outlined,
      color: Colors.blue[800]!,
    ),
    Subscription(
      name: 'СберПрайм',
      date: '20.09.2025',
      amount: 256,
      icon: Icons.diamond_outlined,
      color: Colors.green[700]!,
    ),
    Subscription(
      name: 'VK',
      date: '20.09.2025',
      amount: null,
      icon: Icons.chat_outlined,
      color: Colors.blue[400]!,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Мои подписки'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: EdgeInsets.all(16),
        itemCount: subscriptions.length,
        separatorBuilder: (context, index) => Divider(
          height: 24,
          thickness: 1,
          color: Colors.grey[300],
        ),
        itemBuilder: (context, index) {
          final subscription = subscriptions[index];
          return SubscriptionItem(subscription: subscription);
        },
      ),
    );
  }
}

class Subscription {
  final String name;
  final String date;
  final int? amount;
  final IconData icon;
  final Color color;

  Subscription({
    required this.name,
    required this.date,
    this.amount,
    required this.icon,
    required this.color,
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