import 'dart:io';
import 'package:flutter/material.dart';
import '../core/utils/currency_formatter.dart';
import '../core/utils/date_formatter.dart';
import '../data/models/expense_model.dart';

class ExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cat = expense.category;
    final hasImage = expense.receiptImagePath != null &&
        File(expense.receiptImagePath!).existsSync();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Thumbnail or Category Icon
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 52,
                    height: 52,
                    color: cat.backgroundColor,
                    child: hasImage
                        ? Image.file(
                            File(expense.receiptImagePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              cat.icon,
                              color: cat.color,
                              size: 26,
                            ),
                          )
                        : Icon(
                            cat.icon,
                            color: cat.color,
                            size: 26,
                          ),
                  ),
                ),
                const SizedBox(width: 14),

                // Merchant & Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.merchantName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: cat.backgroundColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              cat.displayName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: cat.color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormatter.toReadable(expense.transactionDate),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.formatVnd(expense.totalAmount),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        color: const Color(0xFF94A3B8),
                        splashRadius: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: onDelete,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
