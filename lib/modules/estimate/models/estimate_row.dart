import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EstimateRow {
  static const String baseUrl = "http://127.0.0.1:4000/api/woodwork";
  int? id;
  int? estimateId; // Foreign key linking to `WoodworkEstimate`
  String? version;
  int sNo;
  // Fields for unit, finishes, and profile handle selection
  String? widthInput;
  String? heightInput;
  String? selectedUnit;
  String? selectedFinish;
  String? selectedProfileHandle;
  String? selectedSecondFinish;
  String? selectedThirdFinish;
  String? room;
  List<String> availableRooms = [
    'Living Room',
    'Bedroom',
    'Kitchen',
    'Pooja',
    'Bathroom',
    'Balcony'
  ];
  // Text controllers for inputs
  final TextEditingController heightController = TextEditingController();
  final TextEditingController widthController = TextEditingController();
  final TextEditingController lengthController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController roomController = TextEditingController();

  //auto focus

  final FocusNode widthFocus = FocusNode();
  final FocusNode heightFocus = FocusNode();
  final FocusNode quantityFocus = FocusNode();
  final FocusNode descriptionFocus = FocusNode();

  // Dimensional fields
  double heightInFeet = 0.0;
  double widthInFeet = 0.0;
  double squareFeet = 0.0;

  // Base and calculated amount fields
  double rate = 0.0;
  double amount = 0.0;
  double baseAmount = 0.0;
  double secondAmount = 0.0;
  double thirdAmount = 0.0;
  double baseSecondAmount = 0.0;
  double baseThirdAmount = 0.0;

  // Side panel fields
  String? selectedSidePanel1;
  double sidePanelRate1 = 0.0;
  int sidePanelQuantity1 = 0;
  double sidePanelAmount1 = 0.0;

  String? selectedSidePanel2;
  double sidePanelRate2 = 0.0;
  int sidePanelQuantity2 = 0;
  double sidePanelAmount2 = 0.0;

  String? selectedSidePanel3;
  double sidePanelRate3 = 0.0;
  int sidePanelQuantity3 = 0;
  double sidePanelAmount3 = 0.0;

  // Dimensions
  double widthMM;
  double heightMM;
  String? description;
  double selectedFinishRate;
  double selectedFinishRate2;
  double selectedFinishRate3;
  int? quantity;

  // Available finish types with rates
  Map<String, double> availableFinishTypes;

  // Constructor
  EstimateRow({
    this.id,
    this.estimateId,
    this.version,
    this.sNo = 0,
    this.room,
    this.selectedUnit,
    this.description,
    this.availableFinishTypes = const {},
    this.selectedFinish,
    this.selectedProfileHandle,
    this.selectedSecondFinish,
    this.selectedThirdFinish,
    this.selectedFinishRate = 0.0,
    this.selectedFinishRate2 = 0.0,
    this.selectedFinishRate3 = 0.0,
    this.baseAmount = 0.0,
    this.baseSecondAmount = 0.0,
    this.baseThirdAmount = 0.0,
    this.amount = 0.0,
    this.secondAmount = 0.0,
    this.thirdAmount = 0.0,
    this.sidePanelAmount1 = 0.0,
    this.sidePanelAmount2 = 0.0,
    this.sidePanelAmount3 = 0.0,
    this.selectedSidePanel1,
    this.selectedSidePanel2,
    this.selectedSidePanel3,
    this.sidePanelRate1 = 0.0,
    this.sidePanelRate2 = 0.0,
    this.sidePanelRate3 = 0.0,
    this.sidePanelQuantity1 = 0,
    this.sidePanelQuantity2 = 0,
    this.sidePanelQuantity3 = 0,
    this.widthMM = 0,
    this.heightMM = 0,
    this.widthInFeet = 0.0,
    this.heightInFeet = 0.0,
    this.squareFeet = 0.0,
    this.quantity,
    this.widthInput = '',
    this.heightInput = '',
  });

  EstimateRow copyWithNextSerial(int nextSerialNumber) {
    return EstimateRow(
      id: null, // Ensure it's treated as a new row on save
      estimateId: estimateId,
      version: version,
      sNo: nextSerialNumber, // Set the new serial number manually
      room: room,
      selectedUnit: selectedUnit,
      description: descriptionController.text,
      availableFinishTypes: Map<String, double>.from(availableFinishTypes),
      selectedFinish: selectedFinish,
      selectedProfileHandle: selectedProfileHandle,
      selectedSecondFinish: selectedSecondFinish,
      selectedThirdFinish: selectedThirdFinish,
      selectedFinishRate: selectedFinishRate,
      selectedFinishRate2: selectedFinishRate2,
      selectedFinishRate3: selectedFinishRate3,
      baseAmount: baseAmount,
      baseSecondAmount: baseSecondAmount,
      baseThirdAmount: baseThirdAmount,
      amount: amount,
      secondAmount: secondAmount,
      thirdAmount: thirdAmount,
      selectedSidePanel1: selectedSidePanel1,
      selectedSidePanel2: selectedSidePanel2,
      selectedSidePanel3: selectedSidePanel3,
      sidePanelRate1: sidePanelRate1,
      sidePanelRate2: sidePanelRate2,
      sidePanelRate3: sidePanelRate3,
      sidePanelQuantity1: sidePanelQuantity1,
      sidePanelQuantity2: sidePanelQuantity2,
      sidePanelQuantity3: sidePanelQuantity3,
      sidePanelAmount1: sidePanelAmount1,
      sidePanelAmount2: sidePanelAmount2,
      sidePanelAmount3: sidePanelAmount3,
      widthMM: widthMM,
      heightMM: heightMM,
      widthInFeet: widthInFeet,
      heightInFeet: heightInFeet,
      squareFeet: squareFeet,
      quantity: quantity,
      widthInput: widthInput,
      heightInput: heightInput,
    )
      ..heightController.text = heightController.text
      ..widthController.text = widthController.text
      ..lengthController.text = lengthController.text
      ..quantityController.text = quantityController.text
      ..descriptionController.text = descriptionController.text
      ..roomController.text = roomController.text;
  }

  // toJson method to convert EstimateRow instance to Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'estimateId': estimateId,
      'version': version,
      'sNo': sNo,
      'room': room,
      'selectedUnit': selectedUnit,
      'description': description,
      'widthInput': widthInput,
      'widthMM': widthMM,
      'heightMM': heightMM,
      'widthFeet': widthInFeet,
      'heightFeet': heightInFeet,
      'squareFeet': squareFeet,
      'quantity': quantity,
      'finishType1': selectedFinish,
      'selectedFinishRate': selectedFinishRate,
      'amount1': baseAmount,
      'totalAmount': amount,
      'finishType2': selectedSecondFinish,
      'selectedFinishRate2': selectedFinishRate2,
      'amount2': baseSecondAmount,
      'totalAmount2': secondAmount,
      'finishType3': selectedThirdFinish,
      'selectedFinishRate3': selectedFinishRate3,
      'amount3': baseThirdAmount,
      'totalAmount3': thirdAmount,
      'sidePanel1': selectedSidePanel1,
      'sideRate1': sidePanelRate1,
      'sideQuantity1': sidePanelQuantity1,
      'sideAmount1': sidePanelAmount1,
      'sidePanel2': selectedSidePanel2,
      'sideRate2': sidePanelRate2,
      'sideQuantity2': sidePanelQuantity2,
      'sideAmount2': sidePanelAmount2,
      'sidePanel3': selectedSidePanel3,
      'sideRate3': sidePanelRate3,
      'sideQuantity3': sidePanelQuantity3,
      'sideAmount3': sidePanelAmount3,
    };
  }

  void initControllers() {
    descriptionController.text = description ?? '';
    roomController.text = roomController.toString();
    widthController.text = widthMM.toString();
    heightController.text = heightMM.toString();
    quantityController.text = quantity?.toString() ?? '0';
  }

  /// Getter for description
  // String get description => descriptionController.text;

  /// Setter for description
  // set description(String value) {
  //   descriptionController.text = value;
  // }

  /// Calculate total square feet based on height and width
  double get totalSquareFeet {
    final height = double.tryParse(heightController.text) ?? 0;
    final width = double.tryParse(widthController.text) ?? 0;
    return height * width / 304.8 / 304.8; // Convert mm to square feet
  }

  /// Update unit and populate default values
  void onUnitSelected(String? unit, Map<String, double>? measurements) {
    selectedUnit = unit;
    if (measurements != null) {
      heightController.text = measurements['height']?.toString() ?? '';
      widthController.text = measurements['width']?.toString() ?? '';
      calculateAmount();
    }
  }

  /// Handle finish type selection and update rate
  void onFinishSelected(String? finish) {
    selectedFinish = finish;
    rate = availableFinishTypes[finish] ?? 0.0;
    calculateAmount();
  }

  /// Handle side panel selection and rate updates
  void onSidePanelSelected(int panelIndex, String? panel, double rate) {
    if (panelIndex == 1) {
      selectedSidePanel1 = panel;
      sidePanelRate1 = rate;
    } else if (panelIndex == 2) {
      selectedSidePanel2 = panel;
      sidePanelRate2 = rate;
    } else if (panelIndex == 3) {
      selectedSidePanel3 = panel;
      sidePanelRate3 = rate;
    }
    calculateSidePanelAmounts();
  }

  /// Calculate amounts for side panels
  void calculateSidePanelAmounts() {
    sidePanelAmount1 = sidePanelRate1 * sidePanelQuantity1;
    sidePanelAmount2 = sidePanelRate2 * sidePanelQuantity2;
    sidePanelAmount3 = sidePanelRate3 * sidePanelQuantity3;
  }

  /// Calculate total amount based on square feet or quantity
  void calculateAmount() {
    // Assuming you have quantities and finish rates, recalculate the amounts
    if (selectedUnit == 'Kitchen' || selectedUnit == 'Bedroom') {
      squareFeet = totalSquareFeet;
      amount = squareFeet * selectedFinishRate;
      secondAmount = squareFeet * selectedFinishRate2;
      thirdAmount = squareFeet * selectedFinishRate3;
    } else {
      final quantity = int.tryParse(quantityController.text) ?? 0;
      amount = quantity * selectedFinishRate;
      secondAmount = quantity * selectedFinishRate2;
      thirdAmount = quantity * selectedFinishRate3;
    }
  }

  /// Convert the instance to a Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id, // Primary Key (autoincrement by SQLite)
      'estimateId': estimateId, // Foreign Key
      'version': version,
      'sNo': sNo,
      'room': room,
      'selectedUnit': selectedUnit,
      'description': description,
      'widthInput': widthInput,
      'heightInput': heightInput,
      'widthMM': widthMM, // Use the calculated width in mm
      'heightMM': heightMM, // Use the calculated height in mm
      'widthFeet': widthInFeet,
      'heightFeet': heightInFeet,
      'squareFeet': squareFeet,
      'quantity': quantity,
      'finishType1': selectedFinish,
      'selectedFinishRate': selectedFinishRate, // Correct column na
      'amount1': baseAmount,
      'totalAmount': amount,
      'finishType2': selectedSecondFinish,
      'selectedFinishRate2': selectedFinishRate2,
      'amount2': baseSecondAmount,
      'totalAmount2': secondAmount,
      'finishType3': selectedThirdFinish,
      'selectedFinishRate3': selectedFinishRate3,
      'amount3': baseThirdAmount,
      'totalAmount3': thirdAmount,
      'sidePanel1': selectedSidePanel1,
      'sideRate1': sidePanelRate1,
      'sideQuantity1': sidePanelQuantity1,
      'sideAmount1': sidePanelAmount1,
      'sidePanel2': selectedSidePanel2,
      'sideRate2': sidePanelRate2,
      'sideQuantity2': sidePanelQuantity2,
      'sideAmount2': sidePanelAmount2,
      'sidePanel3': selectedSidePanel3,
      'sideRate3': sidePanelRate3,
      'sideQuantity3': sidePanelQuantity3,
      'sideAmount3': sidePanelAmount3,
    };
  }

  /// Create an instance from a Map retrieved from the database
  factory EstimateRow.fromMap(Map<String, dynamic> map) {
    final row = EstimateRow(
      id: parseInt(map['id']),
      estimateId: parseInt(map['estimateId']),
      version: map['version']?.toString() ?? "1.1",
      sNo: parseInt(map['sNo']),
      room: map['room'],
      selectedUnit: map['selectedUnit'],
      availableFinishTypes: {}, // You can fill this if needed
      selectedFinish: map['finishType1'],
      selectedProfileHandle: map['selectedProfileHandle'],
      selectedSecondFinish: map['finishType2'],
      selectedThirdFinish: map['finishType3'],
    );

    row.descriptionController.text = map['description']?.toString() ?? '';
    row.heightInput = map['heightInput']?.toString() ?? '';
    row.widthInput = map['widthInput']?.toString() ?? '';
    row.widthMM = parseDouble(map['widthMM']);
    row.heightMM = parseDouble(map['heightMM']);
    row.quantity = parseInt(map['quantity'] ?? 0);
    row.selectedFinishRate = parseDouble(map['selectedFinishRate']);
    row.selectedFinishRate2 = parseDouble(map['selectedFinishRate2']);
    row.selectedFinishRate3 = parseDouble(map['selectedFinishRate3']);
    row.baseAmount = parseDouble(map['amount1']);
    row.amount = parseDouble(map['totalAmount']);
    row.baseSecondAmount = parseDouble(map['amount2']);
    row.secondAmount = parseDouble(map['totalAmount2']);
    row.baseThirdAmount = parseDouble(map['amount3']);
    row.thirdAmount = parseDouble(map['totalAmount3']);
    row.widthInFeet = parseDouble(map['widthFeet']);
    row.heightInFeet = parseDouble(map['heightFeet']);
    row.squareFeet = parseDouble(map['squareFeet']);

    row.selectedSidePanel1 = map['sidePanel1'];
    row.sidePanelRate1 = parseDouble(map['sideRate1']);
    row.sidePanelQuantity1 = parseInt(map['sideQuantity1']);
    row.sidePanelAmount1 = parseDouble(map['sideAmount1']);

    row.selectedSidePanel2 = map['sidePanel2'];
    row.sidePanelRate2 = parseDouble(map['sideRate2']);
    row.sidePanelQuantity2 = parseInt(map['sideQuantity2']);
    row.sidePanelAmount2 = parseDouble(map['sideAmount2']);

    row.selectedSidePanel3 = map['sidePanel3'];
    row.sidePanelRate3 = parseDouble(map['sideRate3']);
    row.sidePanelQuantity3 = parseInt(map['sideQuantity3']);
    row.sidePanelAmount3 = parseDouble(map['sideAmount3']);

    return row;
  }

  static double parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // 🔹 Create an instance from API response
  factory EstimateRow.fromJson(Map<String, dynamic> json) {
    final row = EstimateRow(
      id: parseInt(json['id']),
      estimateId: parseInt(json['estimateId']),
      version: json['version'] ?? "1.1",
      sNo: parseInt(json['sNo']),
      room: json['room'],
      selectedUnit: json['selectedUnit'],
      description: json['description'],
      widthInput: json['widthInput'],
      heightInput: json['heightInput'],
      widthMM: parseDouble(json['widthMM']),
      heightMM: parseDouble(json['heightMM']),
      widthInFeet: parseDouble(json['widthFeet']),
      heightInFeet: parseDouble(json['heightFeet']),
      squareFeet: parseDouble(json['squareFeet']),
      quantity: parseInt(json['quantity']),
      selectedFinish: json['finishType1'],
      selectedFinishRate: parseDouble(json['selectedFinishRate']),
      amount: parseDouble(json['totalAmount']),
      baseAmount: parseDouble(json['amount1']),
      baseSecondAmount: parseDouble(json['amount2']),
      baseThirdAmount: parseDouble(json['amount3']),
      secondAmount: parseDouble(json['totalAmount2']),
      thirdAmount: parseDouble(json['totalAmount3']),
      selectedSecondFinish: json['finishType2'],
      selectedThirdFinish: json['finishType3'],
      selectedFinishRate2: parseDouble(json['selectedFinishRate2']),
      selectedFinishRate3: parseDouble(json['selectedFinishRate3']),
      selectedSidePanel1: json['sidePanel1'],
      sidePanelRate1: parseDouble(json['sideRate1']),
      sidePanelQuantity1: parseInt(json['sideQuantity1']),
      sidePanelAmount1: parseDouble(json['sideAmount1']),
      selectedSidePanel2: json['sidePanel2'],
      sidePanelRate2: parseDouble(json['sideRate2']),
      sidePanelQuantity2: parseInt(json['sideQuantity2']),
      sidePanelAmount2: parseDouble(json['sideAmount2']),
      selectedSidePanel3: json['sidePanel3'],
      sidePanelRate3: parseDouble(json['sideRate3']),
      sidePanelQuantity3: parseInt(json['sideQuantity3']),
      sidePanelAmount3: parseDouble(json['sideAmount3']),
    );

    // 🔥 Add this line
    row.initControllers();

    return row;
  }

  get rateController => null;

  // 🔹 Fetch estimate rows from MySQL
  static Future<List<EstimateRow>> fetchEstimateDetails(int estimateId) async {
    final response = await http
        .get(Uri.parse("$baseUrl/woodwork-estimate-details/$estimateId"));

    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((e) => EstimateRow.fromJson(e)).toList();
    } else {
      throw Exception("Failed to fetch estimate details");
    }
  }

  // 🔹 Save estimate row to MySQL
  Future<bool> saveEstimateRow() async {
    final response = await http.post(
      Uri.parse("$baseUrl/woodwork-estimate-details"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(toJson()),
    );
    return response.statusCode == 200;
  }

  // 🔹 Update estimate row in MySQL
  Future<bool> updateEstimateRow() async {
    final response = await http.put(
      Uri.parse("$baseUrl/woodwork-estimate-details/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(toJson()),
    );
    return response.statusCode == 200;
  }

  // 🔹 Delete estimate row from MySQL
  Future<bool> deleteEstimateRow(int id) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/woodwork-estimate-details/$id"),
    );
    return response.statusCode == 200;
  }

  /// Dispose controllers to release resources
  void dispose() {
    heightController.dispose();
    widthController.dispose();
    lengthController.dispose();
    quantityController.dispose();
    descriptionController.dispose();
  }
}
