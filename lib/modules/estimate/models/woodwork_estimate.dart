import 'estimate_row.dart';

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

class WoodworkEstimate {
  int? id;
  String version;
  String newVersion = "1.1";
  final int? customerId;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final int userId;

  double totalAmount;
  double totalAmount2;
  double totalAmount3;
  double discount;
  double transportCost;
  double gstPercentage;
  String estimateType;
  String status;
  String stage;

  final List<EstimateRow> rows;

  WoodworkEstimate({
    this.id,
    this.customerId,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.totalAmount = 0.0,
    this.totalAmount2 = 0.0,
    this.totalAmount3 = 0.0,
    this.discount = 0.0,
    this.transportCost = 0.0,
    this.gstPercentage = 0.0,
    this.estimateType = 'woodwork',
    required this.version,
    required this.rows,
    required this.userId,
    required this.status,
    required this.stage,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "customerId": customerId,
      "customerName": customerName,
      "customerEmail": customerEmail,
      "customerPhone": customerPhone,
      "totalAmount": totalAmount,
      "totalAmount2": totalAmount2,
      "totalAmount3": totalAmount3,
      "discount": discount,
      "transportCost": transportCost,
      "gstPercentage": gstPercentage,
      "estimateType": estimateType,
      "version": version,
      'userId': userId,
      'status': status,
      'stage': stage,
      "rows": rows.map((row) => row.toMap()).toList(),
    };
  }

  factory WoodworkEstimate.fromMap(
      Map<String, dynamic> map, List<EstimateRow> rows) {
    return WoodworkEstimate(
      id: _parseInt(map['id']),
      customerId: _parseInt(map['customerId']),
      customerName: map['customerName']?.toString() ?? 'Unknown',
      customerEmail: map['customerEmail']?.toString() ?? 'Unknown',
      customerPhone: map['customerPhone']?.toString() ?? 'Unknown',
      totalAmount: _parseDouble(map['totalAmount']),
      totalAmount2: _parseDouble(map['totalAmount2']),
      totalAmount3: _parseDouble(map['totalAmount3']),
      discount: _parseDouble(map['discount']),
      transportCost: _parseDouble(map['transportCost']),
      gstPercentage: _parseDouble(map['gstPercentage']),
      estimateType: map['estimateType']?.toString() ?? 'woodwork',
      version: map['version']?.toString() ?? '1.1',
      userId: map['userId'],
      status: map['status'],
      stage: map['stage'],
      rows: rows,
    );
  }

  // Added fromJson method
  factory WoodworkEstimate.fromJson(
      Map<String, dynamic> json, List<EstimateRow> rows) {
    // Parse rows here
    List<EstimateRow> rows =
        (json['rows'] as List).map((row) => EstimateRow.fromMap(row)).toList();

    return WoodworkEstimate(
      id: _parseInt(json['id']), // Handle null in _parseInt
      customerId: _parseInt(json['customerId']),
      customerName: json['customerName']?.toString() ?? 'Unknown',
      customerEmail: json['customerEmail']?.toString() ?? 'Unknown',
      customerPhone: json['customerPhone']?.toString() ?? 'Unknown',
      totalAmount: _parseDouble(json['totalAmount']),
      totalAmount2: _parseDouble(json['totalAmount2']),
      totalAmount3: _parseDouble(json['totalAmount3']),
      discount: _parseDouble(json['discount']),
      transportCost: _parseDouble(json['transportCost']),
      gstPercentage: _parseDouble(json['gstPercentage']),
      estimateType: json['estimateType']?.toString() ?? 'woodwork',
      version: json['version']?.toString() ?? '1.1',
      userId: _parseInt(json['userId']), // Ensure null handling here as well
      status: json['status'],
      stage: json['stage'],
      rows: (json['rows'] as List)
          .map((row) => EstimateRow.fromMap(row))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ...toMap(),
      'rows': rows.map((row) => row.toMap()).toList(),
    };
  }

  @override
  String toString() {
    return '''
      Estimate(
        id: $id,
        customerId: $customerId,
        customerName: $customerName,
        customerEmail: $customerEmail,
        customerPhone: $customerPhone,
        totalAmount: $totalAmount,
        totalAmount2: $totalAmount2,
        totalAmount3: $totalAmount3,
        discount: $discount,
        transportCost: $transportCost,
        gstPercentage: $gstPercentage,
        estimateType: $estimateType,
        version: $version,
        rows: $rows,
      )
    ''';
  }
}
