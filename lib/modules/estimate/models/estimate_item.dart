// lib/modules/estimate/models/estimate_item.dart

class EstimateItem {
  final String description;
  final double quantity;
  final double rate;

  EstimateItem({
    required this.description,
    required this.quantity,
    required this.rate,
  });

  double get amount => quantity * rate;
}
