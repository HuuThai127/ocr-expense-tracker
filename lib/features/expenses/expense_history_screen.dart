import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/category_enum.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/expense_card.dart';
import '../../widgets/loading_view.dart';
import 'expense_controller.dart';
import 'expense_detail_screen.dart';

class ExpenseHistoryScreen extends StatefulWidget {
  const ExpenseHistoryScreen({super.key});

  @override
  State<ExpenseHistoryScreen> createState() => _ExpenseHistoryScreenState();
}

class _ExpenseHistoryScreenState extends State<ExpenseHistoryScreen> {
  ExpenseCategory? _selectedCategory;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ExpenseController>();

    if (controller.isLoading) {
      return const Scaffold(
        body: LoadingView(message: 'Loading expense history...'),
      );
    }

    // Filter expenses
    final filteredExpenses = controller.expenses.where((exp) {
      final matchesCategory = _selectedCategory == null || exp.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          exp.merchantName.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense History'),
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                // Search Field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search merchant...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Category Filter Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // "All" filter chip
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: const Text('All Categories'),
                          selected: _selectedCategory == null,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedCategory = null;
                              });
                            }
                          },
                          selectedColor: const Color(0xFF4F46E5),
                          labelStyle: TextStyle(
                            color: _selectedCategory == null ? Colors.white : const Color(0xFF475569),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          backgroundColor: const Color(0xFFF1F5F9),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      ...ExpenseCategory.values.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  cat.icon,
                                  size: 14,
                                  color: isSelected ? Colors.white : cat.color,
                                ),
                                const SizedBox(width: 4),
                                Text(cat.displayName),
                              ],
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = selected ? cat : null;
                              });
                            },
                            selectedColor: cat.color,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            backgroundColor: const Color(0xFFF1F5F9),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Expenses List using ListView.builder
          Expanded(
            child: filteredExpenses.isEmpty
                ? EmptyState(
                    title: _searchQuery.isNotEmpty || _selectedCategory != null
                        ? 'No Matching Expenses'
                        : 'No Expenses Recorded',
                    description: _searchQuery.isNotEmpty || _selectedCategory != null
                        ? 'Try clearing your search or category filters.'
                        : 'Capture receipts to start keeping track of your purchases.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredExpenses.length,
                    itemBuilder: (context, index) {
                      final expense = filteredExpenses[index];
                      return ExpenseCard(
                        expense: expense,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ExpenseDetailScreen(expense: expense),
                            ),
                          );
                        },
                        onDelete: () async {
                          if (expense.id != null) {
                            await controller.deleteExpense(
                              expense.id!,
                              imagePath: expense.receiptImagePath,
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
