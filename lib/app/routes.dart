import 'package:flutter/material.dart';
import '../features/analytics/analytics_screen.dart';
import '../features/camera/camera_capture_screen.dart';
import '../features/expenses/expense_history_screen.dart';
import '../features/home/home_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String camera = '/camera';
  static const String history = '/history';
  static const String analytics = '/analytics';

  static Map<String, WidgetBuilder> get routes => {
        home: (context) => const HomeScreen(),
        camera: (context) => const CameraCaptureScreen(),
        history: (context) => const ExpenseHistoryScreen(),
        analytics: (context) => const AnalyticsScreen(),
      };
}
