import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../features/expenses/expense_controller.dart';
import '../features/home/home_screen.dart';
import 'routes.dart';
import 'theme.dart';

class OcrExpenseTrackerApp extends StatelessWidget {
  const OcrExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ExpenseController>(
      create: (_) => ExpenseController()
        ..loadExpenses()
        ..seedSampleDataIfEmpty(),
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
        routes: AppRoutes.routes,
      ),
    );
  }
}
