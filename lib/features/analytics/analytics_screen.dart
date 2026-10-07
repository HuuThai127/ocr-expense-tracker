import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/category_enum.dart';
import '../../painters/category_donut_painter.dart';
import '../../painters/weekly_bar_painter.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/stat_card.dart';
import '../expenses/expense_controller.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _animation;

  int? _selectedCategoryIndex;
  int? _selectedDayIndex;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ExpenseController>();
    final totalSpending = controller.totalSpending;
    final categoryAggregates = controller.categoryAggregates;
    final weeklyAggregates = controller.weeklyAggregates;

    // Build Donut data
    final List<CategoryDonutData> donutData = [];
    for (final cat in ExpenseCategory.values) {
      final amount = categoryAggregates[cat] ?? 0.0;
      final percentage = totalSpending > 0 ? (amount / totalSpending) * 100.0 : 0.0;
      if (amount > 0) {
        donutData.add(CategoryDonutData(
          category: cat,
          amount: amount,
          percentage: percentage,
        ));
      }
    }

    // Build Weekly Bar data
    const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final List<DaySpending> weeklyData = [];
    for (int i = 1; i <= 7; i++) {
      weeklyData.add(DaySpending(
        weekday: i,
        label: weekdayNames[i - 1],
        amount: weeklyAggregates[i] ?? 0.0,
      ));
    }

    if (controller.expenses.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Spending Analytics')),
        body: const EmptyState(
          icon: Icons.pie_chart_outline_rounded,
          title: 'No Data for Analytics',
          description: 'Scan or record your expenses to visualize spending trends.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Analytics'),
      ),
      body: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Total Spending Card
                StatCard(
                  title: 'Total Tracked Expenses',
                  value: CurrencyFormatter.formatVnd(totalSpending),
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: const Color(0xFF4F46E5),
                  subtitle: '${controller.expenses.length} receipts scanned & saved',
                ),

                const SizedBox(height: 24),

                // 2. Category Donut Chart Section
                const Text(
                  'Category Breakdown (CustomPainter Donut)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tap any segment to inspect detailed allocation',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      // Donut Canvas with Interactive Center Details
                      Center(
                        child: SizedBox(
                          width: 220,
                          height: 220,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(220, 220),
                                painter: CategoryDonutPainter(
                                  data: donutData,
                                  animationProgress: _animation.value,
                                  selectedIndex: _selectedCategoryIndex,
                                  strokeWidth: 32,
                                ),
                              ),
                              // Interactive center detail display
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_selectedCategoryIndex != null &&
                                      _selectedCategoryIndex! < donutData.length) ...[
                                    Icon(
                                      donutData[_selectedCategoryIndex!].category.icon,
                                      size: 20,
                                      color: donutData[_selectedCategoryIndex!].category.color,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      donutData[_selectedCategoryIndex!].category.displayName,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: donutData[_selectedCategoryIndex!].category.color,
                                      ),
                                    ),
                                    Text(
                                      '${donutData[_selectedCategoryIndex!].percentage.toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.formatCompact(
                                        donutData[_selectedCategoryIndex!].amount,
                                      ),
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    ),
                                  ] else ...[
                                    const Text(
                                      'Total',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      CurrencyFormatter.formatCompact(totalSpending),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const Text(
                                      '100%',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      const Divider(height: 1),
                      const SizedBox(height: 16),

                      // Interactive Legend Chips
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: List.generate(donutData.length, (idx) {
                          final item = donutData[idx];
                          final isSelected = _selectedCategoryIndex == idx;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedCategoryIndex = isSelected ? null : idx;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? item.category.color.withValues(alpha: 0.12)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? item.category.color
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: item.category.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    item.category.displayName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${item.percentage.toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // 3. Weekly Bar Chart Section
                const Text(
                  'Weekly Spending (CustomPainter Bar Chart)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Daily distribution of receipt totals for current week',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      // Weekly details header if day is tapped
                      if (_selectedDayIndex != null && _selectedDayIndex! < weeklyData.length) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${weeklyData[_selectedDayIndex!].label} Spending:',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                            Text(
                              CurrencyFormatter.formatVnd(weeklyData[_selectedDayIndex!].amount),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Weekly Bar Canvas with Interactive GestureDetector
                      GestureDetector(
                        onTapUp: (details) {
                          final slotWidth = (MediaQuery.of(context).size.width - 80) / 7.0;
                          final tappedIndex = (details.localPosition.dx / slotWidth).floor();
                          if (tappedIndex >= 0 && tappedIndex < 7) {
                            setState(() {
                              _selectedDayIndex = _selectedDayIndex == tappedIndex ? null : tappedIndex;
                            });
                          }
                        },
                        child: SizedBox(
                          width: double.infinity,
                          height: 180,
                          child: CustomPaint(
                            painter: WeeklyBarPainter(
                              days: weeklyData,
                              animationProgress: _animation.value,
                              selectedIndex: _selectedDayIndex,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}
