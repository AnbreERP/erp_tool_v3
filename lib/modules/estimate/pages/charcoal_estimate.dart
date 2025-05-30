import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../database/c_database_helper.dart';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../../modules/estimate/pages/CharcoalEstimatePage.dart';
import '../../../services/customer_database_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../widgets/sidebar_menu.dart';
import '../../providers/notification_provider.dart';

class EstimateCRow {
  String description;
  final TextEditingController lengthController = TextEditingController();
  final TextEditingController widthController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController labourController = TextEditingController();
  final TextEditingController layingController = TextEditingController();
  double area = 0;
  double panel = 0;
  double amount = 0;
  String? status;
  String? stage;

  EstimateCRow({required this.description, this.stage, this.status});
}

class CharcoalEstimate extends StatefulWidget {
  final int customerId;
  final int? estimateId;
  final Map<String, dynamic>? customerInfo;
  final String customerName; // Ensure these are passed correctly
  final String customerEmail;
  final String customerPhone;
  final Map<String, dynamic> estimateData;
  const CharcoalEstimate({
    super.key,
    this.customerInfo,
    required this.customerId,
    this.estimateId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.estimateData,
  });

  @override
  _CharcoalEstimateState createState() => _CharcoalEstimateState();
}

class _CharcoalEstimateState extends State<CharcoalEstimate> {
  static const String baseUrl = "http://127.0.0.1:4000/api/charcoal";
  List<Map<String, dynamic>> _customers = [];
  final List<EstimateCRow> _estimateRows = [
    EstimateCRow(description: 'Charcoal Panel')
  ];

  @override
  void initState() {
    super.initState();
    _loadCustomers(); // Load customers on initialization
    _fetchCustomers();
    _checkAndLoadDraft();
    if (widget.estimateData.isNotEmpty) {
      _loadEstimateFromData(widget.estimateData);
    } else if (widget.estimateId != null) {
      _loadEstimateData(widget.estimateId!);
    }
  }

  //auto save

  // Auto-save and draft management for Charcoal Estimate

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
              'area': row.area,
              'panel': row.panel,
              'amount': row.amount,
            })
        .toList();

    final draftData = {
      'rows': draftRows,
      'hike': hikeController.text,
      'loading': loadingController.text,
      'transport': transportController.text,
      'discount': discountController.text,
    };

    await prefs.setString('charcoal_draft', jsonEncode(draftData));
    debugPrint("📝 Draft saved locally (charcoal_draft)");
  }

  Future<void> _checkAndLoadDraft() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('charcoal_draft');
    debugPrint("📦 Loaded draft JSON: $raw");

    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        _showRestoreDialog(decoded);
      }
    }
  }

  void _showRestoreDialog(Map<String, dynamic> draftData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Restore Draft?"),
        content:
            const Text("A saved draft was found. Do you want to restore it?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              debugPrint("❌ User declined draft restore");
            },
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _loadDraftEstimate(draftData);
            },
            child: const Text("Yes, Restore"),
          ),
        ],
      ),
    );
  }

  void _loadDraftEstimate(Map<String, dynamic> draftData) {
    setState(() {
      _estimateRows.clear();
      hikeController.text = draftData['hike'] ?? '';
      loadingController.text = draftData['loading'] ?? '';
      transportController.text = draftData['transport'] ?? '';
      discountController.text = draftData['discount'] ?? '';

      for (var row in draftData['rows']) {
        final estimateRow = EstimateCRow(description: row['description'] ?? '');
        estimateRow.lengthController.text = row['length'] ?? '';
        estimateRow.widthController.text = row['width'] ?? '';
        estimateRow.rateController.text = row['rate'] ?? '';
        estimateRow.labourController.text = row['labour'] ?? '';
        estimateRow.layingController.text = row['laying'] ?? '';
        estimateRow.area = (row['area'] as num?)?.toDouble() ?? 0.0;
        estimateRow.panel = (row['panel'] as num?)?.toDouble() ?? 0.0;
        estimateRow.amount = (row['amount'] as num?)?.toDouble() ?? 0.0;
        _estimateRows.add(estimateRow);
      }

      _calculateGrandTotal();
    });
  }

  Future<void> clearDraftLocally() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('charcoal_draft');
    debugPrint("🗑️ Draft cleared from SharedPreferences.");
  }

  //end

  void _loadEstimateFromData(Map<String, dynamic> estimateData) {
    final estimate = estimateData['estimate'];
    final rows = estimateData['rows'];

    setState(() {
      _estimateRows.clear();

      for (var row in rows) {
        _estimateRows.add(
          EstimateCRow(description: row['description'] ?? '')
            ..lengthController.text = row['length'].toString()
            ..widthController.text = row['height'].toString()
            ..rateController.text = row['rate'].toString()
            ..layingController.text = row['laying'].toString()
            ..area = (row['area'] as num?)?.toDouble() ?? 0.0
            ..amount = (row['amount'] as num?)?.toDouble() ?? 0.0,
        );
      }

      hikeController.text = estimate['hike']?.toString() ?? '0';
      _grandTotal = (estimate['totalAmount'] as num?)?.toDouble() ?? 0.0;
      _gstamount = (estimate['gst'] as num?)?.toDouble() ?? 0.0;
    });
  }

  Future<void> _loadEstimateData(int estimateId) async {
    try {
      final estimate = await CDatabaseHelper.fetchEstimateById(estimateId);

      setState(() {
        _estimateRows.clear();

        for (var row in estimate['rows']) {
          _estimateRows.add(
            EstimateCRow(
              description: row['description'] ?? '',
            )
              ..lengthController.text = row['length']?.toString() ?? '0'
              ..widthController.text = row['height']?.toString() ?? '0'
              ..rateController.text = row['rate']?.toString() ?? '0'
              ..layingController.text = row['laying']?.toString() ?? '0'
              ..area = (row['area'] as num?)?.toDouble() ?? 0.0
              ..amount = (row['amount'] as num?)?.toDouble() ?? 0.0,
          );
        }

        hikeController.text = estimate['hike']?.toString() ?? '0';
        _grandTotal = (estimate['totalAmount'] as num?)?.toDouble() ?? 0.0;
        _gstamount = (estimate['gst'] as num?)?.toDouble() ?? 0.0;
      });
    } catch (e) {
      debugPrint("Error loading estimate data: $e");
    }
  }

  void _fetchCustomers() async {
    setState(() {});
  }

  Future<void> _loadCustomers() async {
    try {
      // Fetch customer data
      final response = await CustomerDatabaseService().fetchCustomers();

      // Ensure the response contains a list
      if (response.containsKey('customers') && response['customers'] is List) {
        setState(() {
          _customers = List<Map<String, dynamic>>.from(response['customers']);
        });
      } else {
        throw Exception("Invalid response format: Missing 'customers' list");
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load customers: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  double _gstamount = 0.0;
  double _grandTotal = 0.0;

  final TextEditingController loadingController = TextEditingController();
  final TextEditingController transportController = TextEditingController();
  final TextEditingController gstController = TextEditingController();
  final TextEditingController hikeController = TextEditingController();
  final TextEditingController discountController = TextEditingController();
  bool _showHikeField = true;

  static const double _gstPercentage = 18;

  void _calculateEstimate(int rowIndex) {
    double length =
        double.tryParse(_estimateRows[rowIndex].lengthController.text) ?? 0;
    double width =
        double.tryParse(_estimateRows[rowIndex].widthController.text) ?? 0;
    double rate =
        double.tryParse(_estimateRows[rowIndex].rateController.text) ?? 0;
    double labour =
        double.tryParse(_estimateRows[rowIndex].labourController.text) ?? 0;
    double laying =
        double.tryParse(_estimateRows[rowIndex].layingController.text) ?? 0;
    double hikePercentage = double.tryParse(hikeController.text) ?? 0;

    double area = ((length / 304.8) * (width / 304.8))
        .ceilToDouble(); // Assuming input is in millimeters, converting to feet
    double panel =
        (area / (8 * 0.5)).ceilToDouble(); // Assuming 1 panel covers 4 sq.m.

    if (rate <= 4500) {
      rate = 4500;
    }
    if (hikePercentage <= 20) {
      hikePercentage = 20;
    }
    if (laying <= 500) {
      laying = 500;
    }

    double amount = (panel * (rate + labour));
    amount = ((amount / (1 - hikePercentage / 100)) +
            (laying / (1 - hikePercentage / 100)))
        .ceilToDouble();

    if (hikePercentage < 20) {
      hikePercentage = 20;
    }

    setState(() {
      _estimateRows[rowIndex].area = area;
      _estimateRows[rowIndex].panel = panel;
      _estimateRows[rowIndex].amount = amount;

      _calculateGrandTotal();
      _saveDraftLocally();
    });
  }

  void _calculateGrandTotal() {
    double loading = double.tryParse(loadingController.text) ?? 0;
    double transport = double.tryParse(transportController.text) ?? 0;
    double hikePercentage = double.tryParse(hikeController.text) ?? 0;

    if (hikePercentage < 20) {
      hikePercentage = 20;
    }
    loading = loading / (1 - hikePercentage / 100);
    transport = transport / (1 - hikePercentage / 100);

    double totalAmount = _estimateRows.fold(0, (sum, row) => sum + row.amount);
    double gstamount =
        (totalAmount + loading + transport) * _gstPercentage / 100;

    setState(() {
      _gstamount = gstamount.ceilToDouble();
      _grandTotal =
          (totalAmount + loading + transport + gstamount).ceilToDouble();
      _saveDraftLocally();
    });
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
      loadingController.clear();
      transportController.clear();
      _gstamount = 0;
      _grandTotal = 0;
    });
  }

  void _addRow() {
    setState(() {
      _estimateRows.add(EstimateCRow(description: 'Charcoal Panel'));
    });
  }

  void _deleteRow(int index) {
    setState(() {
      if (_estimateRows.length > 1) {
        _estimateRows.removeAt(index);
      }
    });
  }

  Widget _buildEstimateTable() {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 32.0,
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
            return DataRow(cells: _buildDataCells(index));
          }),
        ),
      ),
    );
  }

  List<DataCell> _buildDataCells(int index) {
    return [
      DataCell(Text((index + 1).toString())),
      DataCell(Text(_estimateRows[index].description)),
      _buildTextFieldCell(
          _estimateRows[index].lengthController, 'Length (mm)', index),
      _buildTextFieldCell(
          _estimateRows[index].widthController, 'Width (mm)', index),
      DataCell(Text(_estimateRows[index].area.toStringAsFixed(2))),
      DataCell(Text(_estimateRows[index].panel.toStringAsFixed(0))),
      _buildTextFieldCell(_estimateRows[index].rateController, 'Rate', index),
      _buildTextFieldCell(
          _estimateRows[index].layingController, 'laying', index),
      _buildTextFieldCell(
          _estimateRows[index].labourController, 'Labour', index),
      DataCell(Text(_estimateRows[index].amount.toStringAsFixed(2))),
      DataCell(
        IconButton(
          onPressed: () => _deleteRow(index),
          icon: const Icon(Icons.delete, color: Colors.red),
        ),
      ),
    ];
  }

  DataCell _buildTextFieldCell(
      TextEditingController controller, String label, int index) {
    return DataCell(
      TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: label,
            hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          keyboardType: TextInputType.number,
          onChanged: (_) {
            _calculateEstimate(index);
            _saveDraftLocally();
          }),
    );
  }

  Widget _buildSummarySection() {
    return SizedBox(
      width: 250, // Decreased width of the summary card
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                value: _showHikeField,
                onChanged: (value) {
                  setState(() {
                    _showHikeField = value;
                  });
                  _saveDraftLocally();
                },
              ),
              if (_showHikeField) ...[
                _buildTextField('Hike %', hikeController, TextInputType.number),
                _buildTextField(
                    'Loading Charges', loadingController, TextInputType.number),
                _buildTextField('Transport Charges', transportController,
                    TextInputType.number),
              ],
              _buildGrandTotalSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      TextInputType keyboardType) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 16),
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) {
          _calculateGrandTotal();
          _saveDraftLocally();
        },
      ),
    );
  }

  Widget _buildGrandTotalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              const Text(
                'GST (18%):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '₹ ${_gstamount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Row(
          children: [
            const Text(
              'Grand Total:',
              style: TextStyle(
                  fontSize: 15,
                  color: Colors.green,
                  fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              '₹ ${_grandTotal.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 15,
                  color: Colors.green,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Charcoal Panel Estimation"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Clear Draft',
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('flooring_draft');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Draft cleared.")),
              );
            },
          ),
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
            onPressed: _saveCharcoalEstimateToDatabase,
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
                const CharcoalEstimateListPage(),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🧾 Customer + Summary section in one Card
              Card(
                color: Colors.white,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      bool isMobile = constraints.maxWidth < 600;

                      if (isMobile) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCustomerInfo(),
                            const SizedBox(height: 16),
                            Divider(color: Colors.grey.shade300, thickness: 1),
                            const SizedBox(height: 16),
                            _buildSummaryCard(),
                          ],
                        );
                      } else {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 400, child: _buildCustomerInfo()),
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
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 🔢 Estimate Table
              _buildEstimateTable(),

              const SizedBox(height: 20),

              // ➕ Add / Clear Buttons
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

  Widget _buildSummaryCard() {
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
                          "GST (18%)", "₹${_gstamount.toStringAsFixed(2)}"),
                      const SizedBox(height: 10),
                      _buildSummaryRow(
                        "Grand Total",
                        "₹${_grandTotal.toStringAsFixed(2)}",
                        isBold: true,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 16),
                      if (_showHikeField) ...[
                        _buildInputRow("Hike %", hikeController),
                        const SizedBox(height: 10),
                        _buildInputRow("Loading Charges", loadingController),
                        const SizedBox(height: 10),
                        _buildInputRow(
                            "Transport Charges", transportController),
                      ],
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT COLUMN — Totals
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSummaryRow("GST (18%)",
                                "₹${_gstamount.toStringAsFixed(2)}"),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_showHikeField) ...[
                              _buildInputRow("Hike %", hikeController),
                              const SizedBox(height: 10),
                              _buildInputRow(
                                  "Loading Charges", loadingController),
                              const SizedBox(height: 10),
                              _buildInputRow(
                                  "Transport Charges", transportController),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
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

  Future<void> _saveCharcoalEstimateToDatabase() async {
    try {
      double latestVersion = 0.0;
      String newVersion = '';

      // Retrieve userId from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? userId = prefs.getInt('userId'); // Retrieve userId
      String? token = prefs.getString('token'); // Retrieve token

      if (userId == null) {
        print('❌ Error: UserId is null');
        throw Exception("User is not authenticated. Cannot save estimate.");
      }

      if (token == null) {
        print('❌ Error: Token is missing');
        throw Exception("Token is missing. Please log in.");
      }

      // Fetch latest version for the customer
      final latestVersionResponse = await http.get(
          Uri.parse("$baseUrl/latest/${widget.customerId}"),
          headers: {'Authorization': 'Bearer $token'});

      if (latestVersionResponse.statusCode == 200) {
        var data = jsonDecode(latestVersionResponse.body);
        latestVersion = double.tryParse(data['version'].toString()) ?? 0.0;
      } else {
        throw Exception(
            "Failed to fetch the latest version. Server responded with ${latestVersionResponse.statusCode}");
      }

      print(
          "Fetched latest version for customer ${widget.customerId}: $latestVersion");

      // Step 2: Calculate the new version number
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

        newVersion = "$major.$minor"; // Construct the new version string

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

      // Proceed with the rest of the data preparation...
      List<Map<String, dynamic>> estimateRows = _estimateRows
          .map((row) => {
                'description': row.description,
                'length': double.tryParse(row.lengthController.text) ?? 0.0,
                'height': double.tryParse(row.widthController.text) ?? 0.0,
                'rate': double.tryParse(row.rateController.text) ?? 0.0,
                'laying': double.tryParse(row.layingController.text) ?? 0.0,
                'area': row.area.toDouble(),
                'amount': row.amount.toDouble(),
              })
          .toList();

      Map<String, dynamic> estimateData = {
        'customerId': widget.customerId,
        'hike': double.tryParse(hikeController.text) ?? 0.0,
        'totalAmount': _grandTotal.toDouble(),
        'gst': double.tryParse(gstController.text) ?? 0.0,
        'discount': double.tryParse(discountController.text) ?? 0.0,
        'version': newVersion, // You can change this as needed
        'estimateType': 'charcoal',
        'timestamp': DateTime.now().toIso8601String(),
        'userId': userId, // Add userId here
        'status': 'InProgress',
        'stage': computedStage,
        'rows': estimateRows, // Rows data for the estimate
      };
      await Provider.of<NotificationProvider>(context, listen: false)
          .refreshNotifications();
      // Sending estimate data to the API
      final response = await http.post(
        Uri.parse("$baseUrl/charcoal-estimates"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(estimateData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        int newEstimateId = responseData['estimateId'];

        print("✅ Estimate and rows saved successfully with ID: $newEstimateId");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Estimate saved successfully')),
        );
      } else {
        throw Exception("Failed to save estimate: ${response.statusCode}");
      }
    } catch (e) {
      print('❌ Error saving estimate: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving estimate: $e")),
      );
    }
  }

  void _generatePDF(List<Map<String, dynamic>> estimateData) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Wallpaper Estimation',
                  style: const pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 16),
              pw.Table.fromTextArray(context: context, data: <List<String>>[
                <String>[
                  'Description',
                  'Length',
                  'Height',
                  'Rate',
                  'Laying',
                  'Amount',
                ],
                ...estimateData.map((row) => [
                      row['description'],
                      row['length'].toString(),
                      row['height'].toString(),
                      row['rate'].toString(),
                      row['laying'].toString(),
                      row['amount'].toString(),
                    ])
              ]),
              pw.SizedBox(height: 24),
              pw.Text('Grand Total: ₹$_grandTotal',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
            ],
          );
        },
      ),
    );

    // Save PDF to device
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/estimate.pdf");
    await file.writeAsBytes(await pdf.save());

    // Optionally open the PDF file using the open_file package
    OpenFile.open(file.path);
  }

  void _onSaveAndGeneratePDF() async {
    // Save the current estimation data to the database
    for (int i = 0; i < _estimateRows.length; i++) {
      _saveCharcoalEstimateToDatabase;
    }

    try {
      List<Map<String, dynamic>> estimateData =
          await CDatabaseHelper.fetchAllCharcoalEstimates(); // ✅ Fetch from API

      // Generate PDF with the data
      _generatePDF(estimateData);
    } catch (e) {
      debugPrint("Error loading charcoal estimates: $e");
    }
  }
}
