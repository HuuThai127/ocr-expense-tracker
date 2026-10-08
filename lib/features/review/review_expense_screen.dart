import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/category_enum.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/parsed_receipt.dart';
import '../../services/storage/receipt_storage_service.dart';
import '../../services/validation/expense_validator.dart';
import '../../widgets/category_chip.dart';
import '../expenses/expense_controller.dart';

class ReviewExpenseScreen extends StatefulWidget {
  final File? imageFile;
  final Uint8List? imageBytes;
  final ParsedReceipt parsedReceipt;
  final String rawOcrText;
  final int latencyMs;
  final bool isWebDemo;

  const ReviewExpenseScreen({
    super.key,
    this.imageFile,
    this.imageBytes,
    required this.parsedReceipt,
    required this.rawOcrText,
    required this.latencyMs,
    this.isWebDemo = false,
  });

  @override
  State<ReviewExpenseScreen> createState() => _ReviewExpenseScreenState();
}

class _ReviewExpenseScreenState extends State<ReviewExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _merchantController;
  late final TextEditingController _amountController;
  late final TextEditingController _dateController;

  late DateTime _selectedDate;
  ExpenseCategory _selectedCategory = ExpenseCategory.food;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _merchantController = TextEditingController(
      text: widget.parsedReceipt.merchantName ?? '',
    );
    _amountController = TextEditingController(
      text: widget.parsedReceipt.totalAmount != null
          ? widget.parsedReceipt.totalAmount!.round().toString()
          : '',
    );

    _selectedDate = widget.parsedReceipt.transactionDate ?? DateTime.now();
    _dateController = TextEditingController(
      text: DateFormatter.toDdMmYyyy(_selectedDate),
    );

    // Default category heuristic based on merchant name if available
    _inferDefaultCategory();
  }

  void _inferDefaultCategory() {
    final merchant = (widget.parsedReceipt.merchantName ?? '').toLowerCase();
    if (merchant.contains('book') || merchant.contains('fahasa') || merchant.contains('school') || merchant.contains('edu')) {
      _selectedCategory = ExpenseCategory.study;
    } else if (merchant.contains('grab') || merchant.contains('be') || merchant.contains('taxi') || merchant.contains('petrol') || merchant.contains('xang')) {
      _selectedCategory = ExpenseCategory.travel;
    } else if (merchant.contains('gear') || merchant.contains('computer') || merchant.contains('laptop') || merchant.contains('phong vu')) {
      _selectedCategory = ExpenseCategory.gear;
    } else if (merchant.contains('cgv') || merchant.contains('cinema') || merchant.contains('game') || merchant.contains('billiards')) {
      _selectedCategory = ExpenseCategory.entertainment;
    } else {
      _selectedCategory = ExpenseCategory.food;
    }
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F46E5),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormatter.toDdMmYyyy(picked);
      });
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final parsedAmount = double.tryParse(
      _amountController.text.replaceAll(',', '').replaceAll('.', '').trim(),
    );

    final validation = ExpenseValidator.validate(
      merchantName: _merchantController.text.trim(),
      totalAmount: parsedAmount,
      transactionDate: _selectedDate,
      category: _selectedCategory,
    );

    if (!validation.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validation.errorMessage ?? 'Please check all fields'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final controller = Provider.of<ExpenseController>(context, listen: false);
      String? permanentImagePath;
      if (!kIsWeb && widget.imageFile != null) {
        final storageService = ReceiptStorageService();
        // Ensure image is persisted in app document storage
        permanentImagePath = await storageService.saveReceiptImage(widget.imageFile!);
      }

      final newExpense = ExpenseModel(
        merchantName: _merchantController.text.trim(),
        totalAmount: parsedAmount!,
        currency: 'VND',
        transactionDate: _selectedDate,
        category: _selectedCategory,
        receiptImagePath: permanentImagePath,
        createdAt: DateTime.now(),
        rawOcrText: widget.rawOcrText,
      );

      final success = await controller.addExpense(newExpense);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense saved successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        // Pop back to root dashboard
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.errorMessage ?? 'Failed to save expense'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  void _showRawOcrSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Raw ML Kit Extracted Text',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Text(
                    'Measured OCR Latency: ${widget.latencyMs}ms on-device',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const Divider(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SelectableText(
                          widget.rawOcrText.isEmpty
                              ? '(No text extracted by OCR engine)'
                              : widget.rawOcrText,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.parsedReceipt.status;
    final statusColor = status == DetectionStatus.detected
        ? const Color(0xFF10B981)
        : status == DetectionStatus.partiallyDetected
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Expense'),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_snippet_outlined),
            tooltip: 'View Raw OCR Text',
            onPressed: _showRawOcrSheet,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Web Demo Mode notification banner
              if (widget.isWebDemo || kIsWeb)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_rounded, color: Color(0xFF4F46E5), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Web Demo Mode',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF312E81),
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Google ML Kit OCR is available on Android/iOS. Web Demo Mode uses sample OCR text.',
                              style: TextStyle(
                                color: Color(0xFF4338CA),
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // 1. Receipt Thumbnail & Detection Status Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    // Receipt thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 72,
                        height: 90,
                        color: const Color(0xFFF1F5F9),
                        child: widget.imageBytes != null
                            ? Image.memory(
                                widget.imageBytes!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.receipt_long_rounded,
                                  size: 32,
                                  color: Color(0xFF94A3B8),
                                ),
                              )
                            : (!kIsWeb && widget.imageFile != null)
                                ? Image.file(
                                    widget.imageFile!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                      Icons.receipt_long_rounded,
                                      size: 32,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  )
                                : const Icon(
                                    Icons.receipt_long_rounded,
                                    size: 32,
                                    color: Color(0xFF94A3B8),
                                  ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Detection Status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline_rounded, size: 14, color: statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  status.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            status.description,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.speed_rounded, size: 13, color: Color(0xFF6366F1)),
                              const SizedBox(width: 4),
                              Text(
                                'OCR Latency: ${widget.latencyMs} ms',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. Merchant Name Field
              const Text(
                'Merchant Name',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _merchantController,
                decoration: InputDecoration(
                  hintText: 'e.g. Co.opmart, Highlands Coffee',
                  prefixIcon: const Icon(Icons.storefront_rounded, size: 20),
                  suffixIcon: widget.parsedReceipt.isMerchantFound
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18)
                      : null,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Merchant name is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),

              // 3. Total Amount Field
              const Text(
                'Total Amount (VND)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'e.g. 150000',
                  prefixIcon: const Icon(Icons.payments_outlined, size: 20),
                  suffixText: 'VND',
                  suffixIcon: widget.parsedReceipt.isAmountFound
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18)
                      : null,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Total amount is required';
                  }
                  final parsed = double.tryParse(val.replaceAll(',', '').replaceAll('.', '').trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),

              // 4. Transaction Date Field
              const Text(
                'Transaction Date',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(12),
                child: IgnorePointer(
                  child: TextFormField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      hintText: 'DD/MM/YYYY',
                      prefixIcon: const Icon(Icons.calendar_today_rounded, size: 20),
                      suffixIcon: widget.parsedReceipt.isDateFound
                          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18)
                          : const Icon(Icons.arrow_drop_down_rounded),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // 5. Category Selection
              const Text(
                'Category',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 10,
                children: ExpenseCategory.values.map((cat) {
                  return CategoryChip(
                    category: cat,
                    isSelected: _selectedCategory == cat,
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 36),

              // 6. Save Expense CTA
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveExpense,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.check_rounded, size: 20),
                  label: Text(_isSaving ? 'Saving Expense...' : 'Save Expense'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
