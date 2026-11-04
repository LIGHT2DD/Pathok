class BillExtractionResult {
  const BillExtractionResult({
    this.billerName,
    this.totalAmount,
    this.dueDate,
    this.accountNumber,
    required this.isBill,
  });

  final String? billerName;
  final String? totalAmount;
  final String? dueDate;
  final String? accountNumber;
  final bool isBill;

  bool get hasKeyFields => totalAmount != null || dueDate != null || billerName != null;
}

class BillExtractor {
  static BillExtractionResult extract(String text, String title) {
    final lower = '$title\n$text'.toLowerCase();

    // Check if document has bill or financial indicators
    final isBill = lower.contains(RegExp(
      r'(?:bill|invoice|receipt|vat|tax|total|amount|payable|bdt|tk|ডেসকো|ডিপিডিসি|ওয়াসা|তিতাস|পল্লী বিদ্যুৎ|টাকা|রসিদ|ভাউচার|বিল|মিটার|পরিশোধ)',
      caseSensitive: false,
    ));

    if (!isBill) {
      return const BillExtractionResult(isBill: false);
    }

    String? billerName;
    String? totalAmount;
    String? dueDate;
    String? accountNumber;

    // 1. Identify Biller / Provider
    if (lower.contains('desco') || lower.contains('ডেসকো')) {
      billerName = 'ডেসকো বিদ্যুৎ বিল (DESCO)';
    } else if (lower.contains('dpdc') || lower.contains('ডিপিডিসি')) {
      billerName = 'ডিপিডিসি বিদ্যুৎ বিল (DPDC)';
    } else if (lower.contains('reb') || lower.contains('পল্লী বিদ্যুৎ')) {
      billerName = 'বাংলাদেশ পল্লী বিদ্যুৎ (BREB)';
    } else if (lower.contains('wasa') || lower.contains('ওয়াসা') || lower.contains('ওয়াসা')) {
      billerName = 'ঢাকা ওয়াসা পানি বিল (WASA)';
    } else if (lower.contains('titas') || lower.contains('তিতাস')) {
      billerName = 'তিতাস গ্যাস বিল (Titas Gas)';
    } else if (lower.contains('bakhrabad') || lower.contains('বাখরাবাদ')) {
      billerName = 'বাখরাবাদ গ্যাস বিল (Bakhrabad)';
    } else if (lower.contains('bkash') || lower.contains('বিকাশ')) {
      billerName = 'বিকাশ রসিদ (bKash)';
    } else if (lower.contains('nagad') || lower.contains('নগদ')) {
      billerName = 'নগদ রসিদ (Nagad)';
    } else if (lower.contains('internet') || lower.contains('wifi') || lower.contains('ইন্টারনেট')) {
      billerName = 'ইন্টারনেট বিল (Internet/Wi-Fi)';
    }

    // 2. Extract Total Amount
    final amountRegex = RegExp(
      r'(?:total\s*amount|total\s*payable|net\s*payable|bill\s*amount|amount|total|সর্বমোট|মোট\s*টাকা|মোট|পরিশোধযোগ্য|বিল)\s*[:=]?\s*(?:bdt|tk|টাকা|৳)?\s*([0-9,]+(?:\.[0-9]{1,2})?|[০-৯,]+(?:\.[০-৯]{1,2})?)',
      caseSensitive: false,
    );
    final amountMatch = amountRegex.firstMatch('$title\n$text');
    if (amountMatch != null) {
      final rawAmt = amountMatch.group(1)?.trim();
      if (rawAmt != null && rawAmt.isNotEmpty) {
        totalAmount = '$rawAmt ৳';
      }
    }

    // Fallback amount check for currency symbols followed by numbers
    if (totalAmount == null) {
      final currencyRegex = RegExp(r'(?:৳|bdt|tk\.?)\s*([0-9,]+(?:\.[0-9]{1,2})?|[০-৯,]+(?:\.[০-৯]{1,2})?)', caseSensitive: false);
      final currMatch = currencyRegex.firstMatch('$title\n$text');
      if (currMatch != null) {
        final rawAmt = currMatch.group(1)?.trim();
        if (rawAmt != null && rawAmt.isNotEmpty) {
          totalAmount = '$rawAmt ৳';
        }
      }
    }

    // 3. Extract Due Date
    final dateRegex = RegExp(
      r'(?:due\s*date|last\s*date|pay\s*by|last\s*payment\s*date|bill\s*date|পরিশোধের\s*শেষ\s*তারিখ|শেষ\s*তারিখ|বিলের\s*তারিখ)\s*[:=]?\s*([0-9]{1,2}[\/.-][0-9]{1,2}[\/.-][0-9]{2,4}|[০-৯]{1,2}[\/.-][০-৯]{1,2}[\/.-][০-৯]{2,4}|[0-9]{1,2}\s+[a-zA-Z]+(?:\s+[0-9]{2,4})?|[০-৯]{1,2}\s+(?:জানুয়ারি|ফেব্রুয়ারি|মার্চ|এপ্রিল|মে|জুন|জুলাই|আগস্ট|সেপ্টেম্বর|অক্টোবর|নভেম্বর|ডিসেম্বর)(?:\s+[০-৯]{2,4})?)',
      caseSensitive: false,
    );
    final dateMatch = dateRegex.firstMatch('$title\n$text');
    if (dateMatch != null) {
      dueDate = dateMatch.group(1)?.trim();
    }

    // 4. Extract Account / Meter Number (must contain digits)
    final accRegex = RegExp(
      r'(?:meter|account|consumer|bill|sms|মিটার|হিসাব|গ্রাহক)\s*(?:no|number|num|নম্বর|নং)?\s*[:=]?\s*([0-9a-zA-Z-]*[0-9০-৯]{4,20}[0-9a-zA-Z-]*)',
      caseSensitive: false,
    );
    final accMatch = accRegex.firstMatch('$title\n$text');
    if (accMatch != null) {
      accountNumber = accMatch.group(1)?.trim();
    }

    return BillExtractionResult(
      billerName: billerName,
      totalAmount: totalAmount,
      dueDate: dueDate,
      accountNumber: accountNumber,
      isBill: true,
    );
  }
}
