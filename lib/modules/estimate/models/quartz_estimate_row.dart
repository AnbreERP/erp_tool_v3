import 'package:flutter/material.dart';

class QuartzEstimateRow {
  int? id;
  int? estimateId; // Foreign key linking to the main Quartz estimate
  String? version;
  int sNo;
  String? description;
  double length;
  double width;
  double area;
  double rate;
  double labour;
  double amount;
  double panelRft; // Extra column for panel measurement
  bool isSelected = true;

  // Text controllers
  final TextEditingController lengthController = TextEditingController();
  final TextEditingController widthController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController labourController = TextEditingController();

  QuartzEstimateRow({
    this.id,
    this.estimateId,
    this.version,
    this.sNo = 0,
    this.description,
    this.length = 0.0,
    this.width = 0.0,
    this.area = 0.0,
    this.rate = 0.0,
    this.labour = 0.0,
    this.amount = 0.0,
    this.panelRft = 0.0,
  });

  // Convert object to JSON for API communication
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'estimateId': estimateId,
      'version': version,
      'sNo': sNo,
      'description': description,
      'length': length,
      'width': width,
      'area': area,
      'rate': rate,
      'labour': labour,
      'amount': amount,
      'panelRft': panelRft,
    };
  }

  // Convert JSON map to an object
  factory QuartzEstimateRow.fromMap(Map<String, dynamic> map) {
    return QuartzEstimateRow(
      id: map['id'],
      estimateId: map['estimateId'],
      version: map['version'],
      sNo: map['sNo'] ?? 0,
      description: map['description'],
      length: map['length']?.toDouble() ?? 0.0,
      width: map['width']?.toDouble() ?? 0.0,
      area: map['area']?.toDouble() ?? 0.0,
      rate: map['rate']?.toDouble() ?? 0.0,
      labour: map['labour']?.toDouble() ?? 0.0,
      amount: map['amount']?.toDouble() ?? 0.0,
      panelRft: map['panelRft']?.toDouble() ?? 0.0,
    ).._initializeControllers(map);
  }

  // Initialize text controllers with values
  void _initializeControllers(Map<String, dynamic> map) {
    lengthController.text = map['length']?.toString() ?? '';
    widthController.text = map['width']?.toString() ?? '';
    rateController.text = map['rate']?.toString() ?? '';
    labourController.text = map['labour']?.toString() ?? '';
  }

  // Convert object to a Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'estimateId': estimateId,
      'version': version,
      'sNo': sNo,
      'description': description,
      'length': length,
      'width': width,
      'area': area,
      'rate': rate,
      'labour': labour,
      'amount': amount,
      'panelRft': panelRft,
    };
  }

  // Dispose text controllers
  void dispose() {
    lengthController.dispose();
    widthController.dispose();
    rateController.dispose();
    labourController.dispose();
  }
}
