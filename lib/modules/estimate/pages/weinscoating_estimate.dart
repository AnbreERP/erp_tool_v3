import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../modules/estimate/pages/WeinscoatingEstimateListPage.dart';
import '../../../services/customer_database_service.dart';
import 'package:math_expressions/math_expressions.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../widgets/sidebar_menu.dart';
import '../../providers/notification_provider.dart';

class EstimateWCRow {
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String description;
  String? status;
  String? stage;
  final double length;
  final double width;
  final double laying;
  final double transportCost;
  final double gstPercentage;
  final List<EstimateWCRow> rows;
  final TextEditingController lengthController = TextEditingController();
  final TextEditingController widthController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController labourController = TextEditingController();
  final TextEditingController layingController = TextEditingController();
  double area;
  double panel;
  double rate;
  double amount;
  String? lengthInput; // Raw input for length
  String? widthInput; // Raw input for width

  EstimateWCRow({
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.description,
    required this.length,
    required this.width,
    required this.area,
    required this.panel,
    required this.rate,
    required this.laying,
    required double labour,
    required this.amount,
    required this.transportCost,
    required this.gstPercentage,
    required this.rows,
    this.lengthInput,
    this.widthInput,
    this.status,
    this.stage,
  });
}

class WeinscoatingEstimatePage extends StatefulWidget {
  final bool isEditMode;
  final Map<String, dynamic>? estimateData;
  final int customerId;
  final int? estimateId;
  final Map<String, dynamic>? customerInfo;
  final String customerName; // Ensure these are passed correctly
  final String customerEmail;
  final String customerPhone;

  const WeinscoatingEstimatePage({
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
  _WeinscoatingEstimatePageState createState() =>
      _WeinscoatingEstimatePageState();
}

class _WeinscoatingEstimatePageState extends State<WeinscoatingEstimatePage> {
  double _gstAmount = 0.0;
  double _grandTotal = 0.0;
  final TextEditingController transportController = TextEditingController();
  final TextEditingController gstController = TextEditingController();
  final TextEditingController hikeController = TextEditingController();
  bool _showHikeField = true;
  List<EstimateWCRow> _estimateRows = [
    EstimateWCRow(
      description: 'Weinscoating Panel',
      area: 0.0,
      panel: 0.0,
      amount: 0.0,
      customerName: '',
      customerEmail: '',
      customerPhone: '',
      length: 0.0,
      width: 0.0,
      rate: 0.0,
      laying: 0.0,
      labour: 0.0,
      transportCost: 0.0,
      gstPercentage: 0.0,
      rows: [],
    )
  ];

  static const double _gstPercentage = 18;
  final List<Map<String, dynamic>> _customers = [];

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
    _checkAndLoadDraft();
    print("Customer Info: ${widget.customerInfo}");
    if (widget.isEditMode && widget.estimateData != null) {
      _initializeForEdit(widget.estimateData!);
    }
    if (widget.estimateId != null) {
      _loadEstimateData(widget.estimateId!);
    }
  }

  //auto save
  Future<void> _saveDraftLocally() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final draftRows = _estimateRows
        .map((row) => {
              'description': row.description,
              'length': row.lengthController.text,
              'width': row.widthController.text,
              'rate': row.rateController.text,
              'labour': row.labourController.text,
              'laying': row.layingController.text,
            })
        .toList();

    final draftData = {
      'rows': draftRows,
      'transport': transportController.text,
      'gst': gstController.text,
      'hike': hikeController.text,
    };

    await prefs.setString('wainscoting_draft', jsonEncode(draftData));
    debugPrint("✅ Draft saved locally");
  }

  void _showRestoreDialog(
      List<dynamic> draftRows, Map<String, dynamic> otherFields) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Restore Draft?"),
        content:
            const Text("We found a saved draft. Do you want to restore it?"),
        actions: [
          TextButton(
            child: const Text("No"),
            onPressed: () {
              Navigator.of(context).pop();
              debugPrint("🛑 User declined to restore draft.");
            },
          ),
          ElevatedButton(
            child: const Text("Yes, Restore"),
            onPressed: () {
              Navigator.of(context).pop();
              _loadDraftEstimate(draftRows, otherFields);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _checkAndLoadDraft() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('wainscoting_draft');
    debugPrint("🧠 Loaded raw draft JSON: $raw");

    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final rows = List<Map<String, dynamic>>.from(decoded['rows'] ?? []);
        _showRestoreDialog(rows, decoded);
      } else {
        debugPrint("❌ Draft is not valid. Found type: ${decoded.runtimeType}");
      }
    }
  }

  void _loadDraftEstimate(
      List<dynamic> draftRows, Map<String, dynamic> otherFields) {
    setState(() {
      _estimateRows.clear();

      for (var row in draftRows) {
        final newRow = EstimateWCRow(
          description: row['description'] ?? '',
          area: 0.0,
          panel: 0.0,
          amount: 0.0,
          customerName: '',
          customerEmail: '',
          customerPhone: '',
          length: 0.0,
          width: 0.0,
          rate: 0.0,
          laying: 0.0,
          labour: 0.0,
          transportCost: 0.0,
          gstPercentage: 0.0,
          rows: [],
        );
        newRow.lengthController.text = row['length'] ?? '';
        newRow.widthController.text = row['width'] ?? '';
        newRow.rateController.text = row['rate'] ?? '';
        newRow.labourController.text = row['labour'] ?? '';
        newRow.layingController.text = row['laying'] ?? '';
        _estimateRows.add(newRow);
      }

      transportController.text = otherFields['transport'] ?? '';
      gstController.text = otherFields['gst'] ?? '';
      hikeController.text = otherFields['hike'] ?? '';

      for (int i = 0; i < _estimateRows.length; i++) {
        _calculateEstimate(i);
      }

      _calculateGrandTotal();
    });
  }

  Future<void> clearDraftLocally() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('wainscoting_draft');
    debugPrint("🗑️ Draft cleared");
  }

  //end

  Future<void> _fetchCustomers() async {
    final dbService = CustomerDatabaseService();
    final response = await dbService.fetchCustomers();
    setState(() {
      _customers.clear();
      _customers.addAll(response['customers']);
    });
  }

  Future<void> _loadEstimateData(int estimateId) async {
    try {
      final response = await http.get(Uri.parse(
          "http://127.0.0.1:4000/api/weinscoating/weinscoating-estimates/$estimateId")); // Update your AWS IP
      print("📩 Status Code: ${response.statusCode}");
      print("📄 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final estimate = data['estimate'];
        final rows = data['rows'];

        setState(() {
          // Populate main estimate fields
          transportController.text = estimate['transportCharges'].toString();
          gstController.text = estimate['gst'].toString();
          _grandTotal =
              double.tryParse(estimate['totalAmount'].toString()) ?? 0.0;
          _gstAmount = double.tryParse(estimate['gst'].toString()) ?? 0.0;
          hikeController.text = estimate['version'].toString();

          // Clear existing rows
          _estimateRows.clear();

          // Populate rows
          for (var row in rows) {
            _estimateRows.add(
              EstimateWCRow(
                description: row['description'] ?? '',
                length: double.tryParse(row['length'].toString()) ?? 0.0,
                width: double.tryParse(row['width'].toString()) ?? 0.0,
                area: double.tryParse(row['area'].toString()) ?? 0.0,
                panel: double.tryParse(row['panel'].toString()) ?? 0.0,
                rate: double.tryParse(row['rate'].toString()) ?? 0.0,
                laying: double.tryParse(row['laying'].toString()) ?? 0.0,
                labour: double.tryParse(row['labour'].toString()) ?? 0.0,
                amount: double.tryParse(row['amount'].toString()) ?? 0.0,
                customerName: '',
                customerEmail: '',
                customerPhone: '',
                transportCost: 0.0,
                gstPercentage: 0.0,
                rows: [],
              )
                ..lengthController.text = row['length'].toString()
                ..widthController.text = row['width'].toString()
                ..rateController.text = row['rate'].toString()
                ..layingController.text = row['laying'].toString()
                ..labourController.text = row['labour'].toString(),
            );
          }
        });

        print('Debug: Loaded estimate data successfully for ID: $estimateId');
      } else {
        throw Exception('Failed to load estimate data');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading estimate data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _initializeForEdit(Map<String, dynamic> estimateData) {
    // Pre-fill the controllers with the existing data
    transportController.text = estimateData['transportCharges'].toString();
    gstController.text = estimateData['gst'].toString();
    _grandTotal = estimateData['grandTotal'];

    // Populate estimate rows
    setState(() {
      // Initialize _estimateRows with existing data from estimateData['EstimateWCRow']
      _estimateRows = [];

      for (var row in estimateData['EstimateWCRow'] ?? []) {
        _estimateRows.add(
          EstimateWCRow(
            description: row['description'] ?? '',
            area: row['area'] ?? 0.0,
            amount: row['amount'] ?? 0.0,
            customerName: '',
            customerEmail: '',
            customerPhone: '',
            length: 0.0,
            width: 0.0,
            panel: 0.0,
            rate: 0.0,
            laying: 0.0,
            labour: 0.0,
            transportCost: 0.0,
            gstPercentage: 0.0,
            rows: [],
          )
            ..lengthController.text = (row['lengthInput'] ?? 0.0).toString()
            ..widthController.text = (row['widthInput'] ?? 0.0).toString()
            ..rateController.text = (row['rate'] ?? 0.0).toString()
            ..layingController.text = (row['laying'] ?? 0.0).toString(),
        );
      }
    });
  }

  @override
  void dispose() {
    transportController.dispose();
    gstController.dispose();
    for (var row in _estimateRows) {
      row.lengthController.dispose();
      row.widthController.dispose();
      row.rateController.dispose();
      row.labourController.dispose();
      row.layingController.dispose();
    }
    super.dispose();
  }

  void _calculateEstimate(int rowIndex) {
    final row = _estimateRows[rowIndex];
    String lengthInput = row.lengthController.text;
    String widthInput = row.widthController.text;

    double length = evaluateExpression(lengthInput);
    double width = evaluateExpression(widthInput);
    double rate = double.tryParse(row.rateController.text) ?? 0;
    double labour = double.tryParse(row.labourController.text) ?? 0;
    double laying = double.tryParse(row.layingController.text) ?? 0;
    double hikePercentage = double.tryParse(hikeController.text) ?? 0;

    if (rate <= 4500) {
      rate = 4500;
    }
    if (hikePercentage <= 20) {
      hikePercentage = 20;
    }
    if (laying <= 500) {
      laying = 500;
    }
    double area = ((length / 304.8) * (width / 304.8)).ceilToDouble();
    double panel = (area / (8 * 0.5)).ceilToDouble();
    double amount = panel * (rate + labour);
    amount = ((amount / (1 - hikePercentage / 100)) +
            (laying / (1 - hikePercentage / 100)))
        .ceilToDouble();

    setState(() {
      row.area = area;
      row.panel = panel;
      row.amount = amount.ceilToDouble();
      _calculateGrandTotal();
    });
  }

  void _calculateGrandTotal() {
    try {
      double transport = double.tryParse(transportController.text) ?? 0;
      double hikePercentage = double.tryParse(hikeController.text) ?? 0;
      if (hikePercentage < 20) {
        hikePercentage = 20;
      }
      transport = transport / (1 - hikePercentage / 100);
      double totalAmount =
          _estimateRows.fold(0, (sum, row) => sum + row.amount);
      double gstAmount = (totalAmount + transport) * _gstPercentage / 100;

      setState(() {
        _gstAmount = gstAmount.ceilToDouble();
        _grandTotal = (totalAmount + transport + gstAmount).ceilToDouble();
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

  void _clearData() {
    setState(() {
      for (var row in _estimateRows) {
        row.lengthController.clear();
        row.widthController.clear();
        row.rateController.clear();
        row.labourController.clear();
        row.layingController.clear();
        row.area = 0;
        row.panel = 0;
        row.amount = 0;
      }
      transportController.clear();
      _gstAmount = 0;
      _grandTotal = 0;
    });
  }

  void _addRow() {
    setState(() {
      _estimateRows.add(EstimateWCRow(
        description: 'Weinscoating Panel',
        area: 0.0,
        panel: 0.0,
        amount: 0.0,
        customerName: '',
        customerEmail: '',
        customerPhone: '',
        length: 0.0,
        width: 0.0,
        rate: 0.0,
        laying: 0.0,
        labour: 0.0,
        transportCost: 0.0,
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

  Widget _buildCustomerInfo() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildInfoRow("Customer Name", widget.customerInfo?['name'] ?? "-"),
          _buildInfoRow("Email", widget.customerInfo?['email'] ?? "-"),
          _buildInfoRow("Phone", widget.customerInfo?['phone'] ?? "-"),
        ],
      ),
    );
  }

// ✅ Helper method to align label & value in the same margin
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow(String label, TextEditingController controller) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
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
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            onChanged: (_) {
              setState(() {
                _calculateGrandTotal();
                _saveDraftLocally();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Row(
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
    );
  }

  Widget _buildSummaryCard() {
    double gstAmount = (_grandTotal * 18 / 100);

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 600;

        return Card(
          color: Colors.white,
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryRow(
                          "GST (18%)", "₹${gstAmount.toStringAsFixed(2)}"),
                      const SizedBox(height: 10),
                      _buildSummaryRow(
                        "Grand Total",
                        "₹${_grandTotal.toStringAsFixed(2)}",
                        isBold: true,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 16),
                      if (_showHikeField) ...[
                        _buildInputRow("Hike (%)", hikeController),
                        const SizedBox(height: 10),
                        _buildInputRow("Transport (₹)", transportController),
                      ],
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT COLUMN — GST & Total
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSummaryRow("GST (18%)",
                                "₹${gstAmount.toStringAsFixed(2)}"),
                            const SizedBox(height: 10),
                            _buildSummaryRow(
                              "Grand Total",
                              "₹${_grandTotal.toStringAsFixed(2)}",
                              isBold: true,
                              color: Colors.green,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 30),
                      // RIGHT COLUMN — Inputs
                      Expanded(
                        child: Visibility(
                          visible: _showHikeField,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputRow("Hike (%)", hikeController),
                              const SizedBox(height: 10),
                              _buildInputRow(
                                  "Transport (₹)", transportController),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
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
            DataColumn(label: Text('Description')),
            DataColumn(label: Text('Length (mm)')),
            DataColumn(label: Text('Width (mm)')),
            DataColumn(label: Text('Area (sq.m)')),
            DataColumn(label: Text('Panel')),
            DataColumn(label: Text('Rate')),
            DataColumn(label: Text('Laying')),
            DataColumn(label: Text('Labour')),
            DataColumn(label: Text('Amount')),
            DataColumn(label: Text('Actions')),
          ],
          rows: List.generate(_estimateRows.length, (index) {
            final row = _estimateRows[index];
            return DataRow(cells: [
              DataCell(Text('${index + 1}')),
              DataCell(Text(row.description)),
              _buildEditableExpressionCell(
                  row.lengthController, row.lengthInput ?? '', index, true),
              _buildEditableExpressionCell(
                  row.widthController, row.widthInput ?? '', index, false),
              DataCell(Text(row.area.toStringAsFixed(2))),
              DataCell(Text('${row.panel}')),
              _buildEditableDataCell(row.rateController, index, false),
              _buildEditableDataCell(row.layingController, index, false),
              _buildEditableDataCell(row.labourController, index, false),
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
              onChanged: (_) {
                _calculateEstimate(index);
                _saveDraftLocally(); // 🧠 Save draft
              },
              onSubmitted: (value) {
                _onFieldSubmitted(index, value, isLength: isLength);
                _saveDraftLocally();
              },
              decoration: const InputDecoration(
                  hintText: 'eg."=100+20"',
                  hintStyle:
                      TextStyle(fontSize: 12, color: Colors.grey), // hintStyle
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
          _saveDraftLocally(); //  Call this inside a block
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
        row.widthInput = value;
        row.widthController.text = evaluateExpression(value).toString();
      }
      _calculateEstimate(rowIndex);
      _calculateGrandTotal();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.isEditMode ? 'Edit Estimate' : 'Weinscoating Estimate'),
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
          IconButton(
            onPressed: () {
              setState(() {
                _showHikeField = !_showHikeField;
              });
            },
            icon: Icon(
              _showHikeField ? Icons.expand_less : Icons.expand_more,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
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
              SidebarController.of(context)
                  ?.openPage(const WeinscoatingEstimateListPage());
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                                _buildCustomerInfo(),
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
                                    width: 400, child: _buildCustomerInfo()),
                                Container(
                                  width: 2,
                                  height: 200,
                                  color: Colors.grey.shade300,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                ),
                                Expanded(child: _buildSummaryCard()),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Estimate Table
              _buildEstimateTable(),

              const SizedBox(height: 20),

              // Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: _addRow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('Clear All'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveEstimateToDatabase() async {
    try {
      const String baseUrl = "http://127.0.0.1:4000/api";
      const String url =
          "http://127.0.0.1:4000/api/weinscoating/save-estimate"; // Updated API
      double latestVersion = 0.0;
      String newVersion = '';

      if (_estimateRows.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No estimate rows to save.')),
        );
        return;
      }

      // Step 1: Retrieve userId from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? userId = prefs.getInt('userId'); // Retrieve as integer directly

      if (userId == null) {
        print('❌ Error: UserId is null');
        throw Exception("User is not authenticated. Cannot save estimate.");
      }

      print("UserId being sent to backend: $userId");

      // Step 2: Retrieve the token from SharedPreferences
      String? token = prefs.getString('token'); // Retrieve the token
      if (token == null) {
        print('❌ Error: Token is missing');
        throw Exception("Token is missing");
      }
      // Step 1: Fetch latest version for the customer
      final latestVersionResponse = await http.get(
          Uri.parse("$baseUrl/weinscoating/latest/${widget.customerId}"),
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
        int minor = versionParts.length > 1
            ? int.parse(versionParts[1])
            : 0; // Extract minor version

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

      // Step 3: Prepare the request body
      final Map<String, dynamic> requestBody = {
        "customerId": widget.customerId,
        "customerName": widget.customerInfo?['name'] ?? '',
        "transportCharges": double.tryParse(transportController.text) ?? 0.0,
        "gst": _gstAmount,
        "totalAmount": _grandTotal,
        "estimateType": "wainscoting",
        "version": newVersion,
        "userId": userId, // Include userId in the request body
        "status": 'InProgress',
        "stage": computedStage,
        "estimateRows": _estimateRows
            .map((row) => {
                  "description": row.description,
                  "length": double.tryParse(row.lengthInput ?? '0') ?? 0.0,
                  "width": double.tryParse(row.widthInput ?? '0') ?? 0.0,
                  "area": row.area,
                  "panel": row.panel,
                  "rate": double.tryParse(row.rateController.text) ?? 0.0,
                  "laying": double.tryParse(row.layingController.text) ?? 0.0,
                  "labour": double.tryParse(row.labourController.text) ?? 0.0,
                  "amount": row.amount,
                })
            .toList(),
      };

      // Step 4: Make the request to save the estimate
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization":
              "Bearer $token", // Send the token in the Authorization header
        },
        body: jsonEncode(requestBody),
      );

      // Step 5: Debugging: Log the raw response
      print("Raw response body: ${response.body}");
      await Provider.of<NotificationProvider>(context, listen: false)
          .refreshNotifications();
      // Step 6: Handle the response
      if (response.statusCode == 201) {
        // ✅ Expecting 201 (Created)
        final responseData = jsonDecode(response.body);

        if (responseData['id'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    '✅ Estimate saved successfully (ID: ${responseData['id']})')),
          );
        } else {
          throw Exception("⚠️ Server did not return an estimate ID.");
        }
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['error'] ?? "⚠️ Unknown error occurred.");
      }
    } catch (e) {
      print('🔥 Error saving estimate: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error saving estimate: $e')),
      );
    }
  }
}
