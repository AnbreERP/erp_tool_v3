// lib/modules/estimate/services/estimate_service.dart

import '../models/estimate.dart';

class EstimateService {
  final List<Estimate> _estimates = [];

  List<Estimate> get estimates => List.unmodifiable(_estimates);

  List<Estimate> getEstimatesByType(String type) {
    return _estimates.where((estimate) => estimate.type == type).toList();
  }

  void addEstimate(Estimate estimate) {
    _estimates.add(estimate);
  }
}
