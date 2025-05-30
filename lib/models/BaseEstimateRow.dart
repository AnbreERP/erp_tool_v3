import 'package:flutter/material.dart';

abstract class BaseEstimateRow {
  int? id;
  int? estimateId; // Foreign key linking to the main estimate
  String? version;
  int sNo;
  String? description;
  int quantity;
  double rate;
  double amount;

  // Text controllers for user input
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  BaseEstimateRow({
    this.id,
    this.estimateId,
    this.version,
    required this.sNo,
    this.description,
    this.quantity = 0,
    this.rate = 0.0,
    this.amount = 0.0,
  });

  // Convert to Map for saving in the database
  Map<String, dynamic> toMap();

  // Populate model from database
  factory BaseEstimateRow.fromMap(Map<String, dynamic> map) {
    throw UnimplementedError("Must be implemented in subclasses");
  }

  // Dispose controllers
  void dispose() {
    descriptionController.dispose();
    quantityController.dispose();
    rateController.dispose();
    amountController.dispose();
  }
}
