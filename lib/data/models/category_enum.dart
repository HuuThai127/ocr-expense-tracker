import 'package:flutter/material.dart';

enum ExpenseCategory {
  food('Food', Icons.restaurant_rounded, Color(0xFFE57373), Color(0xFFFFEBEE)),
  study('Study', Icons.school_rounded, Color(0xFF64B5F6), Color(0xFFE3F2FD)),
  travel('Travel', Icons.directions_car_rounded, Color(0xFF81C784), Color(0xFFE8F5E9)),
  gear('Gear', Icons.laptop_mac_rounded, Color(0xFFFFB74D), Color(0xFFFFF3E0)),
  entertainment('Entertainment', Icons.sports_esports_rounded, Color(0xFFBA68C8), Color(0xFFF3E5F5));

  final String displayName;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const ExpenseCategory(
    this.displayName,
    this.icon,
    this.color,
    this.backgroundColor,
  );

  static ExpenseCategory fromString(String? value) {
    if (value == null) return ExpenseCategory.food;
    final normalized = value.trim().toLowerCase();
    for (final cat in ExpenseCategory.values) {
      if (cat.name.toLowerCase() == normalized ||
          cat.displayName.toLowerCase() == normalized) {
        return cat;
      }
    }
    return ExpenseCategory.food;
  }
}
