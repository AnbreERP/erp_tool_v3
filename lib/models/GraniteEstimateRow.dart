import 'package:flutter/material.dart';
import 'BaseEstimateRow.dart';

class GraniteEstimateRow extends BaseEstimateRow {
  double length;
  double width;
  double area;

  // Text Controllers for input fields
  final TextEditingController lengthController = TextEditingController();
  final TextEditingController widthController = TextEditingController();
  final TextEditingController labourController = TextEditingController();

  GraniteEstimateRow({
    super.id,
    super.estimateId,
    super.version,
    required super.sNo, // ✅ Required argument
    super.description,
    super.quantity,
    super.rate,
    super.amount,
    this.length = 0.0,
    this.width = 0.0,
    this.area = 0.0,
  }) {
    // Initialize controllers with existing values
    lengthController.text = length.toString();
    widthController.text = width.toString();
    labourController.text = '0.0'; // Default value
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'estimateId': estimateId,
      'version': version,
      'sNo': sNo,
      'description': description,
      'quantity': quantity,
      'rate': rate,
      'amount': amount,
      'length': length,
      'width': width,
      'area': area,
    };
  }

  factory GraniteEstimateRow.fromMap(Map<String, dynamic> map) {
    var row = GraniteEstimateRow(
      id: map['id'],
      estimateId: map['estimateId'],
      version: map['version'],
      sNo: map['sNo'],
      description: map['description'],
      quantity: map['quantity'],
      rate: map['rate'],
      amount: map['amount'],
      length: map['length'],
      width: map['width'],
      area: map['area'],
    );

    // Set controllers with values
    row.lengthController.text = map['length'].toString();
    row.widthController.text = map['width'].toString();
    row.labourController.text = '0.0'; // Default value

    return row;
  }

  // Dispose controllers when no longer needed
  @override
  void dispose() {
    lengthController.dispose();
    widthController.dispose();
    labourController.dispose();
    super.dispose();
  }
}
