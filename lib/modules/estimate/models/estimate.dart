// lib/modules/estimate/models/estimate.dart

import 'estimate_item.dart';

class Estimate {
  final String id;
  final String projectName;
  final String type; // Added type field to categorize estimates
  final List<EstimateItem> items;
  final double discountPercent;

  Estimate({
    required this.id,
    required this.projectName,
    required this.type, // Make sure type is required in the constructor
    required this.items,
    this.discountPercent = 0,
  });

  double get subtotal {
    return items.fold(0, (sum, item) => sum + item.amount);
  }

  double get discountAmount {
    return subtotal * (discountPercent / 100);
  }

  double get grandTotal {
    return subtotal - discountAmount;
  }
}
