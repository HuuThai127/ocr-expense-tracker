enum DetectionStatus {
  detected('Detected', 'All receipt fields recognized'),
  partiallyDetected('Partially Detected', 'Some fields require manual verification'),
  notDetected('Not Detected', 'Could not recognize receipt fields');

  final String label;
  final String description;
  const DetectionStatus(this.label, this.description);
}

class ParsedReceipt {
  final String? merchantName;
  final double? totalAmount;
  final DateTime? transactionDate;
  final String rawText;
  final bool isAmountFound;
  final bool isMerchantFound;
  final bool isDateFound;
  final int processingDurationMs;

  const ParsedReceipt({
    this.merchantName,
    this.totalAmount,
    this.transactionDate,
    required this.rawText,
    this.isAmountFound = false,
    this.isMerchantFound = false,
    this.isDateFound = false,
    this.processingDurationMs = 0,
  });

  DetectionStatus get status {
    if (isAmountFound && isMerchantFound && isDateFound) {
      return DetectionStatus.detected;
    } else if (isAmountFound || isMerchantFound || isDateFound) {
      return DetectionStatus.partiallyDetected;
    } else {
      return DetectionStatus.notDetected;
    }
  }

  ParsedReceipt copyWith({
    String? merchantName,
    double? totalAmount,
    DateTime? transactionDate,
    String? rawText,
    bool? isAmountFound,
    bool? isMerchantFound,
    bool? isDateFound,
    int? processingDurationMs,
  }) {
    return ParsedReceipt(
      merchantName: merchantName ?? this.merchantName,
      totalAmount: totalAmount ?? this.totalAmount,
      transactionDate: transactionDate ?? this.transactionDate,
      rawText: rawText ?? this.rawText,
      isAmountFound: isAmountFound ?? this.isAmountFound,
      isMerchantFound: isMerchantFound ?? this.isMerchantFound,
      isDateFound: isDateFound ?? this.isDateFound,
      processingDurationMs: processingDurationMs ?? this.processingDurationMs,
    );
  }
}
