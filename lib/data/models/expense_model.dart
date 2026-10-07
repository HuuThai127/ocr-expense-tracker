import 'category_enum.dart';

class ExpenseModel {
  final int? id;
  final String merchantName;
  final double totalAmount;
  final String currency;
  final DateTime transactionDate;
  final ExpenseCategory category;
  final String? receiptImagePath;
  final DateTime createdAt;
  final String? rawOcrText;

  const ExpenseModel({
    this.id,
    required this.merchantName,
    required this.totalAmount,
    this.currency = 'VND',
    required this.transactionDate,
    required this.category,
    this.receiptImagePath,
    required this.createdAt,
    this.rawOcrText,
  });

  ExpenseModel copyWith({
    int? id,
    String? merchantName,
    double? totalAmount,
    String? currency,
    DateTime? transactionDate,
    ExpenseCategory? category,
    String? receiptImagePath,
    DateTime? createdAt,
    String? rawOcrText,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      merchantName: merchantName ?? this.merchantName,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      transactionDate: transactionDate ?? this.transactionDate,
      category: category ?? this.category,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      createdAt: createdAt ?? this.createdAt,
      rawOcrText: rawOcrText ?? this.rawOcrText,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchant_name': merchantName,
      'total_amount': totalAmount,
      'currency': currency,
      'transaction_date': transactionDate.toIso8601String(),
      'category': category.name,
      'receipt_image_path': receiptImagePath,
      'created_at': createdAt.toIso8601String(),
      'raw_ocr_text': rawOcrText,
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as int?,
      merchantName: (map['merchant_name'] as String?) ?? '',
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0.0,
      currency: (map['currency'] as String?) ?? 'VND',
      transactionDate: map['transaction_date'] != null
          ? DateTime.parse(map['transaction_date'] as String)
          : DateTime.now(),
      category: ExpenseCategory.fromString(map['category'] as String?),
      receiptImagePath: map['receipt_image_path'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      rawOcrText: map['raw_ocr_text'] as String?,
    );
  }

  @override
  String toString() {
    return 'ExpenseModel(id: $id, merchant: $merchantName, total: $totalAmount $currency, date: $transactionDate, category: ${category.name})';
  }
}
