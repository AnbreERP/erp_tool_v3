import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../database/f_database_helper.dart';
import '../../../widgets/sidebar_menu.dart';
import '../../providers/notification_provider.dart';
import 'FalseCeilingEstimateListPage.dart';

class EstimateFRow {
  final int id;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final double length;
  final double height;
  final double gstPercentage;
  final List<EstimateFRow> rows;
  final TextEditingController lengthController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController description = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController widthController = TextEditingController();
  double area;
  double rate;
  double amount;
  String type;
  String? status;
  String? stage;
  String? lengthInput; // Raw input for length
  String? heightInput; // Raw input for width

  EstimateFRow({
    required this.id,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.type,
    required this.length,
    required this.height,
    required this.area,
    required this.rate,
    required this.amount,
    required this.gstPercentage,
    required this.rows,
    this.status,
    this.stage,
    this.lengthInput,
    this.heightInput,
  });
}

class FalseCeilingEstimatePage extends StatefulWidget {
  final bool isEditMode;
  final Map<String, dynamic>? estimateData;
  final int customerId;
  final int? estimateId;
  final Map<String, dynamic>? customerInfo;
  final String customerName; // Ensure these are passed correctly
  final String customerEmail;
  final String customerPhone;

  const FalseCeilingEstimatePage({
    super.key,
    this.isEditMode = false,
    this.estimateData,
    required this.customerId,
    this.estimateId,
    this.customerInfo,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
  });

  @override
  _FalseCeilingEstimatePageState createState() =>
      _FalseCeilingEstimatePageState();
}

class _FalseCeilingEstimatePageState extends State<FalseCeilingEstimatePage> {
  static const String falseCeilingDraftKey = 'false_ceiling_draft';
  double _gstAmount = 0.0;
  double _grandTotal = 0.0;
  static const double mmToFeet = 304.8;
  final TextEditingController gstController = TextEditingController();

  final List<EstimateFRow> _estimateRows = [
    EstimateFRow(
      id: 0,
      type: 'Ceiling', // Fixed row for Ceiling
      area: 0.0,
      amount: 0.0,
      customerName: '',
      customerEmail: '',
      customerPhone: '',
      length: 0.0,
      height: 0.0,
      rate: 0.0,
      gstPercentage: 0.0,
      rows: [],
    ),
    EstimateFRow(
      id: 1,
      type: 'Cove',
      // Fixed row for Cove
      area: 0.0,
      amount: 0.0,
      customerName: '',
      customerEmail: '',
      customerPhone: '',
      length: 0.0,
      height: 0.0,
      rate: 0.0,
      gstPercentage: 0.0,
      rows: [],
    ),
  ];

  static const double _gstPercentage = 18;
  final List<Map<String, dynamic>> _customers = [];
  Map<String, dynamic>? _selectedCustomer;
  static const String baseUrl = "http://127.0.0.1:4000/api";

  @override
  void initState() {
    super.initState();
    _checkAndLoadDraft(); // 🧠 Load the draft if any
    _fetchCustomers();

    if (widget.isEditMode && widget.estimateData != null) {
      _initializeForEdit(widget.estimateData!);
    }

    if (widget.estimateId != null) {
      _loadEstimateData(widget.estimateId!);
    }
  }

  void _initializeForEdit(Map<String, dynamic> estimateData) {
    final estimate = estimateData['estimate'] ?? {};
    final rows = List<Map<String, dynamic>>.from(estimateData['rows'] ?? []);

    gstController.text = estimate['gst'].toString();
    _grandTotal = estimate['totalAmount'];

    _estimateRows.clear();
    for (var row in rows) {
      final newRow = EstimateFRow(
        id: row['id'],
        type: row['type'],
        customerName: '',
        customerEmail: '',
        customerPhone: '',
        length: (row['length'] as num?)?.toDouble() ?? 0.0,
        height: (row['width'] as num?)?.toDouble() ?? 0.0,
        area: (row['area'] as num?)?.toDouble() ?? 0.0,
        rate: (row['rate'] as num?)?.toDouble() ?? 0.0,
        amount: (row['amount'] as num?)?.toDouble() ?? 0.0,
        gstPercentage: 0.0,
        rows: [],
      );

      newRow.lengthController.text = newRow.length.toString();
      newRow.heightController.text = newRow.height.toString();
      newRow.rateController.text = newRow.rate.toString();
      newRow.description.text = row['description'] ?? '';
      newRow.quantityController.text =
          (row['quantity'] as num?)?.toDouble().toString() ?? '0.0';

      _estimateRows.add(newRow);
    }

    // Recalculate all estimates
    for (int i = 0; i < _estimateRows.length; i++) {
      _calculateEstimate(i);
    }

    _calculateGrandTotal();
  }

  void _loadEstimateData(int estimateId) async {
    try {
      // Fetch estimate details from API
      final estimateData =
          await FDatabaseHelper.fetchEstimateDetails(estimateId);

      setState(() {
        // Populate main estimate fields
        gstController.text =
            (estimateData['estimate']['gst'] ?? 0.0).toString();
        _grandTotal = estimateData['estimate']['totalAmount'] ?? 0.0;

        // Reset and populate rows
        _estimateRows.clear();
        for (var row in estimateData['rows']) {
          final newRow = EstimateFRow(
            id: row['id'],
            type: row['type'],
            customerName: '',
            customerEmail: '',
            customerPhone: '',
            length: (row['length'] as num?)?.toDouble() ?? 0.0,
            height: (row['width'] as num?)?.toDouble() ?? 0.0,
            area: (row['area'] as num?)?.toDouble() ?? 0.0,
            rate: (row['rate'] as num?)?.toDouble() ?? 0.0,
            amount: (row['amount'] as num?)?.toDouble() ?? 0.0,
            gstPercentage: 0.0,
            rows: [],
          );

          newRow.lengthController.text = newRow.length.toString();
          newRow.heightController.text = newRow.height.toString();
          newRow.rateController.text = newRow.rate.toString();
          newRow.description.text = row['description'] ?? '';
          newRow.quantityController.text =
              (row['quantity'] as num?)?.toDouble().toString() ?? '0.0';

          _estimateRows.add(newRow);
        }

        // Recalculate all estimates
        for (int i = 0; i < _estimateRows.length; i++) {
          _calculateEstimate(i);
        }

        // Recalculate grand total
        _calculateGrandTotal();
      });

      print('Debug: False Ceiling estimate and rows loaded successfully.');
    } catch (e) {
      print('Error loading False Ceiling estimate data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error loading False Ceiling estimate data: $e')),
      );
    }
  }

  Future<void> _fetchCustomers() async {
    try {
      print("🔥 Fetching customer details for ID: ${widget.customerId}");

      final response = await http.get(
        Uri.parse("$baseUrl/customers/${widget.customerId}"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final customerData = jsonDecode(response.body);
        setState(() {
          _selectedCustomer = {
            "id": customerData["id"],
            "name": customerData["name"]
          };
        });
        print("✅ Customer Data Loaded: $_selectedCustomer");
      } else {
        throw Exception("❌ Failed to fetch customer details.");
      }
    } catch (e) {
      print("❌ Error fetching customer details: $e");
    }
  }

  // Function to round values to the nearest 76.2 mm
  double roundToNearest76_2(double value) {
    final remainder = value % 76.2;
    return remainder <= 3 ? value - remainder : value + (76.2 - remainder);
  }

  @override
  void dispose() {
    gstController.dispose();
    for (var row in _estimateRows) {
      row.lengthController.dispose();
      row.heightController.dispose();
      row.rateController.dispose();
      row.description.dispose();
      row.quantityController.dispose();
    }
    super.dispose();
  }

  void _calculateEstimate(int rowIndex) {
    final row = _estimateRows[rowIndex];

    String lengthInput = row.lengthController.text;
    String heightInput = row.heightController.text;

    double length = evaluateExpression(lengthInput);
    double height = evaluateExpression(heightInput);
    double rate = double.tryParse(row.rateController.text) ?? 0;
    double qty = double.tryParse(row.quantityController.text) ?? 0;

    double roundedLengthMM = roundToNearest76_2(length);
    double roundHeightMM = roundToNearest76_2(height);
    double lengthFeet = roundedLengthMM / mmToFeet;
    double heightFeet = roundHeightMM / mmToFeet;

    rate = rate < 130 ? 130 : rate;

    setState(() {
      switch (row.type) {
        case 'Ceiling':
          // Ceiling row: normal area calculation
          row.area = lengthFeet * heightFeet;
          row.amount = row.area.ceilToDouble() * rate;

          // Update Cove row based on Ceiling input
          final coveRow = _estimateRows.firstWhere((r) => r.type == 'Cove');
          coveRow.lengthController.text = (length * 4).toString();
          coveRow.heightController.text = (height * 4).toString();
          _calculateEstimate(1); // Recalculate Cove
          break;

        case 'Cove':
          // Cove row: special calculation based on Ceiling values
          row.area = ((lengthFeet) + (heightFeet)).ceilToDouble();
          row.amount = row.area.ceilToDouble() * rate;
          break;

        case 'Wooden':
          // Wooden row calculation
          if (rate <= 1000) {
            rate = 1000;
            row.area = (lengthFeet * heightFeet).ceilToDouble();
            row.amount = row.area.ceilToDouble() * rate;
          } else {
            row.area = lengthFeet * heightFeet;
            row.amount = row.area.ceilToDouble() * rate;
          }
          break;

        case 'Wooden Painted':
          //Wooden Painted row calculation
          if (rate <= 350) {
            row.area = (3 * lengthFeet).ceilToDouble();
            row.amount = row.area.ceilToDouble() * qty * 350;
          } else {
            row.area = (3 * lengthFeet);
            row.amount = row.area.ceilToDouble() * qty * rate;
          }
          break;

        case 'Fan Cut Out':
          // For Fan Cut Out, amount is calculated based on quantity
          rate = 750;
          row.amount = qty * rate;
          break;

        default:
          // Default calculation for other row types
          row.area = (lengthFeet * heightFeet).ceilToDouble();
          row.amount = row.area * rate;
      }
      _calculateGrandTotal();
    });
  }

  void _clearData() {
    setState(() {
      for (var row in _estimateRows) {
        row.lengthController.clear();
        row.heightController.clear();
        row.description.clear();
        row.rateController.clear();
        row.quantityController.clear();
      }
      _gstAmount = 0;
      _grandTotal = 0;
    });
  }

  void _calculateGrandTotal() {
    try {
      double totalAmount =
          _estimateRows.fold(0, (sum, row) => sum + row.amount);
      double gstAmount = totalAmount * _gstPercentage / 100;

      setState(() {
        _gstAmount = gstAmount.ceilToDouble();
        _grandTotal = (totalAmount + gstAmount).ceilToDouble();
      });
    } catch (e) {
      _showErrorSnackBar('Error calculating grand total: $e');
    }
  }

  double evaluateExpression(String input) {
    try {
      if (input.isEmpty) return 0.0;
      if (input.startsWith('=')) {
        String expression = input.substring(1);
        Parser parser = Parser();
        Expression exp = parser.parse(expression);
        ContextModel context = ContextModel();
        return exp.evaluate(EvaluationType.REAL, context);
      } else {
        double? value = double.tryParse(input);
        if (value == null) throw const FormatException("Invalid number");
        return value;
      }
    } catch (e) {
      print('Error evaluating expression "$input": $e');
      return 0.0;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _addRow() {
    setState(() {
      _estimateRows.add(EstimateFRow(
        type: 'Wooden',
        area: 0.0,
        amount: 0.0,
        id: 0,
        customerName: '',
        customerEmail: '',
        customerPhone: '',
        length: 0.0,
        height: 0.0,
        rate: 0.0,
        gstPercentage: 0.0,
        rows: [],
      ));
    });
  }

  void _deleteRow(int index) {
    setState(() {
      if (_estimateRows.length > 1) {
        _estimateRows.removeAt(index);
      }
      _calculateGrandTotal();
    });
  }

  // auto save
  Future<void> _saveDraftLocally() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final draftData = _estimateRows.map((row) {
      return {
        "type": row.type,
        "length": row.lengthController.text,
        "height": row.heightController.text,
        "rate": row.rateController.text,
        "description": row.description.text,
        "quantity": row.quantityController.text,
      };
    }).toList();

    String jsonData = jsonEncode(draftData);
    await prefs.setString(falseCeilingDraftKey, jsonData);
    debugPrint("✅ Draft saved locally");
  }

  Future<void> _checkAndLoadDraft() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? raw = prefs.getString(falseCeilingDraftKey);

    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is List<dynamic>) {
        _showRestoreDialog(decoded);
      } else {
        debugPrint("❌ Draft is not a list. Found type: ${decoded.runtimeType}");
      }
    } else {
      debugPrint("⚠️ No draft found in SharedPreferences.");
    }
  }

  Future<void> loadDraftLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(falseCeilingDraftKey);

    debugPrint("🟡 Loaded raw draft JSON: $raw");

    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _showRestoreDialog(decoded); // ✅ pass the list to the dialog
      } else {
        debugPrint(
            "⚠️ Draft data is not a List. Found: ${decoded.runtimeType}");
      }
    }
  }

  Future<void> clearDraftLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('falseCeilingDraftKey');
    debugPrint("🗑️ Draft cleared from SharedPreferences.");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Draft cleared successfully')),
    );
  }

  void _loadDraftEstimate(List<dynamic> draftRows) {
    setState(() {
      _estimateRows.clear();
      for (var item in draftRows) {
        final row = EstimateFRow(
          id: 0,
          customerName: widget.customerName,
          customerEmail: widget.customerEmail,
          customerPhone: widget.customerPhone,
          type: item['type'] ?? 'Ceiling',
          length: 0,
          height: 0,
          area: 0,
          rate: 0,
          amount: 0,
          gstPercentage: 0,
          rows: [],
        );

        row.lengthController.text = item['length'] ?? '';
        row.heightController.text = item['height'] ?? '';
        row.rateController.text = item['rate'] ?? '';
        row.description.text = item['description'] ?? '';
        row.quantityController.text = item['quantity'] ?? '';

        _estimateRows.add(row);
      }

      for (int i = 0; i < _estimateRows.length; i++) {
        _calculateEstimate(i);
      }

      _calculateGrandTotal();
      debugPrint("✅ Draft restored into table");
    });
  }

  void _showRestoreDialog(List<dynamic> draftRows) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Restore Draft?"),
          content:
              const Text("We found a saved draft. Do you want to restore it?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                debugPrint("🗑️ User declined draft restoration.");
              },
              child: const Text("No"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _loadDraftEstimate(draftRows);
              },
              child: const Text("Yes, Restore"),
            ),
          ],
        );
      },
    );
  }

  //end
  Widget _buildGrandTotalCard() {
    double totalAmount = _estimateRows.fold(0, (sum, row) => sum + row.amount);
    double gstAmount = (totalAmount) * _gstPercentage / 100;
    return Align(
      alignment: Alignment.topRight,
      child: Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Amt.      : ₹${totalAmount.ceil()}'),
              Text('GST (18%)      : ₹${gstAmount.ceil()}'),
              Text(
                'Grand Total : ₹${(totalAmount + gstAmount).ceil()}',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.green),
              ),
              const Divider(),
              const SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                // Space buttons evenly
                children: <Widget>[
                  ElevatedButton(
                    onPressed: _addRow,
                    child: const Text('Add Row'),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  ElevatedButton(
                    onPressed: _clearData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Clear All'),
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                // Space buttons evenly
                children: <Widget>[
                  ElevatedButton(
                    onPressed: _saveEstimateToDatabase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save '),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Using Navigator.push to navigate to the EstimateListPage
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const FalseCeilingEstimateListPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.blueAccent,
                    ),
                    child: const Text('View Estimates'),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstimateTable() {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 5),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20.0,
          headingRowHeight: 50,
          dataRowHeight: 60,
          columns: const [
            DataColumn(label: Text('S.No')),
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Description')),
            DataColumn(label: Text('Length(mm)')),
            DataColumn(label: Text('Height(mm)')),
            DataColumn(label: Text('Length(ft)')),
            DataColumn(label: Text('Height(ft)')),
            DataColumn(label: Text('Area (sq.m)')),
            DataColumn(label: Text('Quantity')),
            DataColumn(label: Text('Rate')),
            DataColumn(label: Text('Amount')),
            DataColumn(label: Text('Actions')),
          ],
          rows: List.generate(_estimateRows.length, (index) {
            final row = _estimateRows[index];

            String lengthInput = row.lengthController.text;
            String heightInput = row.heightController.text;
            double length = evaluateExpression(lengthInput);
            double height = evaluateExpression(heightInput);
            double lengthFeet = (length / mmToFeet);
            double heightFeet = (height / mmToFeet);

            return DataRow(cells: [
              DataCell(Text('${index + 1}')),
              DataCell(
                DropdownButton<String>(
                  value: _estimateRows[index].type.isNotEmpty &&
                          [
                            'Ceiling',
                            'Cove',
                            'Wooden',
                            'Wooden Painted',
                            'Design',
                            'Fan Cut Out'
                          ].contains(_estimateRows[index].type)
                      ? _estimateRows[index].type
                      : 'Ceiling', // Fallback to a default value if not found
                  items: const [
                    DropdownMenuItem(value: 'Ceiling', child: Text('Ceiling')),
                    DropdownMenuItem(value: 'Cove', child: Text('Cove')),
                    DropdownMenuItem(value: 'Wooden', child: Text('Wooden')),
                    DropdownMenuItem(
                        value: 'Wooden Painted', child: Text('W-Painted')),
                    DropdownMenuItem(value: 'Design', child: Text('Design')),
                    DropdownMenuItem(
                        value: 'Fan Cut Out', child: Text('Fan Cut Out')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _estimateRows[index].type = value!;
                      _calculateEstimate(index);
                      _saveDraftLocally();
                    });
                  },
                ),
              ),
              // Description Field
              _buildEditableDataCell(row.description, index, false),
              if (row.type != 'Fan Cut Out')
                // Length Field
                _buildEditableExpressionCell(
                    row.lengthController, row.lengthInput ?? '', index, true)
              else
                const DataCell(SizedBox.shrink()),
              // Height Field
              if (row.type != 'Fan Cut Out')
                if (row.type == 'Wooden Painted')
                  const DataCell(Text('150 * 120 * 150'))
                else
                  _buildEditableExpressionCell(
                      row.heightController, row.heightInput ?? '', index, false)
              else
                const DataCell(SizedBox.shrink()),
              // Display Length in feet
              if (row.type != 'Fan Cut Out')
                DataCell(Text(lengthFeet.toStringAsFixed(2)))
              else
                const DataCell(SizedBox.shrink()),
              // Display Height in feet
              if (row.type != 'Fan Cut Out')
                if (row.type == 'Wooden Painted')
                  const DataCell(Text('3'))
                else
                  DataCell(Text(heightFeet.toStringAsFixed(2)))
              else
                const DataCell(SizedBox.shrink()),
              // Display Area
              if (row.type != 'Fan Cut Out')
                DataCell(Text((row.area.ceilToDouble()).toStringAsFixed(2)))
              else
                const DataCell(SizedBox.shrink()),
              // Display Quantity
              if (row.type == 'Fan Cut Out' || row.type == 'Wooden Painted')
                _buildEditableDataCell(row.quantityController, index, false)
              else
                const DataCell(SizedBox.shrink()),
              // Hide quantity if not 'Fan Cut Out'
              // Display Rate
              _buildEditableDataCell(row.rateController, index, false),
              // Display Amount
              DataCell(Text(row.amount.toStringAsFixed(2))),
              DataCell(IconButton(
                onPressed: () => _deleteRow(index),
                icon: const Icon(Icons.delete, color: Colors.red),
              )),
            ]);
          }),
        ),
      ),
    );
  }

  DataCell _buildEditableExpressionCell(TextEditingController controller,
      String expression, int index, bool isLength) {
    return DataCell(
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              onChanged: (_) => _calculateEstimate(index),
              onSubmitted: (value) {
                _onFieldSubmitted(index, value, isLength: isLength);
                _saveDraftLocally();
              },
              decoration: const InputDecoration(
                  hintText: 'eg."=100+20"',
                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                  // hintStyle
                  contentPadding: EdgeInsets.symmetric(vertical: 8.0)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, size: 15),
            onPressed: () {
              _editExpressionDialog(index, expression, isLength);
            },
          ),
        ],
      ),
    );
  }

  DataCell _buildEditableDataCell(
      TextEditingController controller, int index, bool isLength) {
    return DataCell(
      TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        onChanged: (_) {
          _calculateEstimate(index);
          _saveDraftLocally(); // ✅ Call this inside a block
        },
      ),
    );
  }

  void _editExpressionDialog(int index, String expression, bool isLength) {
    final controller = TextEditingController(text: expression);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Expression'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Enter Expression'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _onFieldSubmitted(index, controller.text, isLength: isLength);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _onFieldSubmitted(int rowIndex, String value, {required bool isLength}) {
    setState(() {
      final row = _estimateRows[rowIndex];
      if (isLength) {
        row.lengthInput = value;
        row.lengthController.text = evaluateExpression(value).toString();
      } else {
        row.heightInput = value;
        row.heightController.text = evaluateExpression(value).toString();
      }
      _calculateEstimate(rowIndex);
      _calculateGrandTotal();
      _saveDraftLocally();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.isEditMode ? 'Edit Estimate' : 'False Ceiling Estimation'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Clear Draft',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Clear Draft?"),
                    content: const Text(
                        "Are you sure you want to remove the saved draft?"),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel")),
                      ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Clear")),
                    ],
                  ),
                );

                if (confirm == true) {
                  await clearDraftLocally();
                }
              }),
          ElevatedButton(
            onPressed: _saveEstimateToDatabase,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('Save'),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {
              SidebarController.of(context)?.openPage(
                const FalseCeilingEstimateListPage(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('View Estimates'),
          ),
          const SizedBox(width: 20),
        ],
      ),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row containing Customer Info & Total Summary in a Card
            Card(
              color: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        bool isMobile = constraints.maxWidth < 600;

                        if (isMobile) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCustomerSelection(),
                              const SizedBox(height: 16),
                              Divider(
                                  color: Colors.grey.shade300, thickness: 1),
                              const SizedBox(height: 16),
                              _buildSummaryCard(),
                            ],
                          );
                        } else {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 400,
                                child: _buildCustomerSelection(),
                              ),
                              Container(
                                width: 2,
                                height: 200,
                                color: Colors.grey.shade300,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              Expanded(child: _buildSummaryCard()),
                            ],
                          );
                        }
                      },
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Estimate Table
            _buildEstimateTable(),
            const SizedBox(height: 20),

            // Buttons Below Table
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: _addRow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Add Row'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _clearData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 14, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

// ✅ Grand Total Card - Optimized for Layout Issues
  Widget _buildSummaryCard() {
    double totalAmount = _estimateRows.fold(0, (sum, row) => sum + row.amount);
    double gstAmount = totalAmount * _gstPercentage / 100;
    double grandTotal = totalAmount + gstAmount;

    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        bool isMobile = screenWidth < 500;

        return Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryRow("Total Amount", "₹${totalAmount.ceil()}",
                    isMobile: isMobile),
                const SizedBox(height: 10),
                _buildSummaryRow("GST", "₹${gstAmount.ceil()}",
                    isMobile: isMobile),
                const SizedBox(height: 10),
                _buildSummaryRow("Grand Total", "₹${grandTotal.ceil()}",
                    isBold: true, color: Colors.green, isMobile: isMobile),
              ],
            ),
          ),
        );
      },
    );
  }

// 🔹 Helper Function for Side-by-side Label and Field
  Widget _buildSummaryRow(String label, String value,
      {bool isBold = false, Color? color, bool isMobile = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
          SizedBox(
            width: 100,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: color ?? Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSelection() {
    return Card(
      elevation: 5, // Increase elevation for a more prominent look
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(12), // Add rounded corners for a softer look
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Text
            Text(
              'Customer Information',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(
                height: 10), // Spacing between the title and the first field

            // Customer Name
            Row(
              children: [
                Icon(Icons.person, color: Colors.blue[800]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Name: ${widget.customerInfo?['name'] ?? 'N/A'}', // Handle null values
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Customer Email
            Row(
              children: [
                Icon(Icons.email, color: Colors.blue[800]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Email: ${widget.customerInfo?['email'] ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Customer Phone
            Row(
              children: [
                Icon(Icons.phone, color: Colors.blue[800]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Phone: ${widget.customerInfo?['phone'] ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveEstimateToDatabase() async {
    try {
      double latestVersion = 0.0;
      String newVersion = '';

      // Step 1: Retrieve userId from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? userId = prefs.getInt('userId'); // Retrieve as integer directly
      String? token = prefs.getString('token');

      if (userId == null) {
        print('❌ Error: UserId is null');
        throw Exception("User is not authenticated. Cannot save estimate.");
      }

      print("UserId being sent to backend: $userId");

      // Step 1: Fetch latest version for the customer
      final latestVersionResponse = await http.get(
          Uri.parse("$baseUrl/false-ceiling/latest/${widget.customerId}"),
          headers: {
            'Authorization': 'Bearer $token',
          });

      if (latestVersionResponse.statusCode == 200) {
        var data = jsonDecode(latestVersionResponse.body);
        latestVersion = double.tryParse(data['version'].toString()) ?? 0.0;
      } else {
        throw Exception(
            "Failed to fetch the latest version. Server responded with ${latestVersionResponse.statusCode}");
      }

      // Debugging output
      print(
          "Fetched latest version for customer ${widget.customerId}: $latestVersion");

      // Step 2: Calculate new version number
      if (latestVersion == 0.0) {
        newVersion = "1.1"; // First version if no estimate exists
      } else {
        // Extract major and minor version parts from latestVersion
        List<String> versionParts = latestVersion.toString().split('.');
        int major = int.parse(versionParts[0]); // Extract major version
        int minor = int.parse(versionParts[1]); // Extract minor version

        // Debugging output
        print("Current major: $major, minor: $minor");

        // Increment the minor version by 1 if it's less than 9, else reset minor and increment major
        if (minor >= 9) {
          major += 1; // Increment the major version if minor is 9
          minor = 0; // Reset minor version to 0
        } else {
          minor += 1; // Increment minor version
        }

        // Now construct the new version properly
        newVersion = "$major.$minor"; // Construct new version string

        // Debugging output for new version
        print("New version calculated: $newVersion");
      }
      String getStageFromVersion(String version) {
        int major = int.tryParse(version.split('.').first) ?? 1;
        if (major == 1) return 'Sales';
        if (major == 2) return 'Pre-Designer';
        if (major == 3) return 'Designer';
        return 'Sales';
      }

      String computedStage = getStageFromVersion(newVersion);

      List<Map<String, dynamic>> estimateRows = _estimateRows.map((row) {
        // ✅ Ensure 'description' is not empty
        String description = row.description.text.isNotEmpty
            ? row.description.text
            : "No Description";
        double quantity = double.tryParse(row.quantityController.text) ?? 1.0;

        return {
          "type": row.type,
          "description": description,
          "length": double.tryParse(row.lengthController.text) ?? 1.0,
          "width": double.tryParse(row.heightController.text) ?? 1.0,
          "area": (double.tryParse(row.lengthController.text) ?? 1.0) *
              (double.tryParse(row.heightController.text) ?? 1.0),
          "quantity": quantity,
          "rate": double.tryParse(row.rateController.text) ?? 1.0,
          "amount": row.amount,
        };
      }).toList();

      // ✅ Ensure at least one valid row exists
      if (estimateRows.isEmpty) {
        throw Exception(
            "❌ No valid estimate rows found. Please add at least one row.");
      }

      // Step 2: Prepare the request body
      Map<String, dynamic> estimateData = {
        "customerId": widget.customerId,
        "customerName": _selectedCustomer!['name'],
        "estimateType": "False Ceiling",
        "gst": double.tryParse(gstController.text) ?? 0.0,
        "totalAmount": _grandTotal,
        "version": newVersion,
        "timestamp": DateTime.now().toIso8601String(),
        "userId": userId, // Include userId in the request body
        "status": 'InProgress',
        "stage": computedStage,
        "details": estimateRows,
      };

      print("📝 Final Estimate Data Sent: ${jsonEncode(estimateData)}");
      await Provider.of<NotificationProvider>(context, listen: false)
          .refreshNotifications();

      // Step 3: Call the API to save the estimate
      int? estimateId = await FDatabaseHelper.saveEstimate(estimateData);

      print('✅ Debug: Created new False Ceiling estimate with ID: $estimateId');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('False Ceiling estimate saved successfully')),
      );
    } catch (e) {
      print('❌ Error saving estimate: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving estimate: $e')),
      );
    }
  }
}
