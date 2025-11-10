import 'package:flutter/material.dart';

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