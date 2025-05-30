import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../widgets/sidebar_menu.dart';
import '../../providers/notification_provider.dart';
import 'mosquitoNetEstimateDetail.dart';
import 'package:http/http.dart' as http;

class EstimateRow {
  String selectedRoom = '';
  String selectedWindowType = '';
  String selectedModel = '';
  String lengthInput = '';
  String heightInput = '';
  double area = 0;
  double rate = 0;
  double amount = 0;
  TextEditingController additionalInfoController = TextEditingController();
  TextEditingController lengthController = TextEditingController();
  TextEditingController heightController = TextEditingController();
  TextEditingController rateController = TextEditingController();
  final TextEditingController gstController = TextEditingController();
  TextEditingController hikeController =
      TextEditingController(text: '20'); // Default to 20%
}

class MosquitoNetEstimate extends StatefulWidget {
  final int customerId;
  final int? estimateId;
  final Map<String, dynamic>? customerInfo;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  String? status;
  String? stage;
  final Map<String, dynamic> estimateData; // Add this to the field
  final Map<String, dynamic>? existingEstimateData;

  MosquitoNetEstimate(
      {super.key,
      required this.customerId,
      this.estimateId,
      this.customerInfo,
      this.status,
      this.stage,
      required this.customerName,
      required this.customerEmail,
      required this.customerPhone,
      required this.estimateData, // Make sure this matches the constructor
      this.existingEstimateData});

  @override
  _MosquitoNetEstimateState createState() => _MosquitoNetEstimateState();
}

class _MosquitoNetEstimateState extends State<MosquitoNetEstimate> {
  final List<EstimateRow> _estimateRows = [];
  TextEditingController hikeController = TextEditingController();
  double hikePercentage = 0;
  double grandTotal = 0;
  double gstAmount = 0;
  double grandAmount = 0;
  bool isNewEstimate = false;
  bool _showHikeField = false;

  @override
  void initState() {
    super.initState();

    isNewEstimate = widget.existingEstimateData == null;

    if (!isNewEstimate) {
      final data = widget.existingEstimateData!;

      hikeController.text = data['hike']?.toString() ?? '';

      _estimateRows.clear();

      if (data['rows'] != null) {
        for (var row in data['rows']) {
          final estimateRow = EstimateRow();
          estimateRow.selectedRoom = row['room'] ?? '';
          estimateRow.selectedWindowType = row['window'] ?? '';
          estimateRow.additionalInfoController.text =
              row['additional_Info'] ?? '';
          estimateRow.selectedModel = row['model'] ?? '';
          estimateRow.lengthController.text = row['length'].toString();
          estimateRow.lengthInput = row['length'].toString();
          estimateRow.heightController.text = row['height'].toString();
          estimateRow.heightInput = row['height'].toString();
          estimateRow.area = double.tryParse(row['area'].toString()) ?? 0.0;
          estimateRow.rateController.text = row['rate'].toString();
          estimateRow.amount = double.tryParse(row['amount'].toString()) ?? 0.0;
          _estimateRows.add(estimateRow);
        }
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (int i = 0; i < _estimateRows.length; i++) {
          _calculateEstimate(i);
        }
        _calculateGrandTotal();
      });
    } else {
      _addNewRow();
      _checkAndLoadDraft();
    }
  }

  //auto save
  Future<void> _saveDraftLocally() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final draftRows = _estimateRows
        .map((row) => {
              'room': row.selectedRoom,
              'window': row.selectedWindowType,
              'additional_info': row.additionalInfoController.text,
              'model': row.selectedModel,
              'length': row.lengthController.text,
              'height': row.heightController.text,
              'rate': row.rateController.text,
              'area': row.area,
              'amount': row.amount,
            })
        .toList();

    final draftData = {
      'rows': draftRows,
      'hike': hikeController.text,
    };

    await prefs.setString('mosquito_draft', jsonEncode(draftData));
    debugPrint("✅ Mosquito Net draft saved locally");
  }

  Future<void> _checkAndLoadDraft() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('mosquito_draft');
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

      for (var row in draftData['rows']) {
        final estimateRow = EstimateRow();
        estimateRow.selectedRoom = row['room'] ?? '';
        estimateRow.selectedWindowType = row['window'] ?? '';
        estimateRow.additionalInfoController.text =
            row['additional_info'] ?? '';
        estimateRow.selectedModel = row['model'] ?? '';
        estimateRow.lengthController.text = row['length'] ?? '';
        estimateRow.lengthInput = row['length'] ?? '';
        estimateRow.heightController.text = row['height'] ?? '';
        estimateRow.heightInput = row['height'] ?? '';
        estimateRow.rateController.text = row['rate'] ?? '';
        estimateRow.area = row['area'] ?? 0.0;
        estimateRow.amount = row['amount'] ?? 0.0;

        _estimateRows.add(estimateRow);
      }

      for (int i = 0; i < _estimateRows.length; i++) {
        _calculateEstimate(i);
      }

      _calculateGrandTotal();
    });
  }

  Future<void> clearDraftLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('mosquito_draft');
    debugPrint("🗑️ Mosquito Net draft cleared.");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Draft cleared successfully')),
    );
  }

  //end

  void _addNewRow() {
    setState(() {
      final newRow = EstimateRow();
      newRow.lengthController.text = '';
      newRow.heightController.text = '';
      newRow.rateController.text = '';
      newRow.additionalInfoController.text = '';
      _estimateRows.add(EstimateRow());
    });
  }

  void _deleteRow(int index) {
    setState(() {
      _estimateRows.removeAt(index);
      _calculateGrandTotal();
    });
  }

  void _clearData() {
    setState(() {
      for (var row in _estimateRows) {
        row.lengthController.clear();
        row.heightController.clear();
        row.rateController.clear();
        row.area = 0;
        row.amount = 0;
      }
      gstAmount = 0;
      grandAmount = 0;
    });
  }

  @override
  void dispose() {
    hikeController.dispose();
    for (var row in _estimateRows) {
      row.lengthController.dispose();
      row.heightController.dispose();
      row.rateController.dispose();
      row.additionalInfoController.dispose();
      row.hikeController.dispose();
      row.gstController.dispose();
    }
    super.dispose();
  }

  void _onHikeChange(String value) {
    double newHike = double.tryParse(value) ?? 0;
    setState(() {
      hikePercentage = newHike < 20 ? 20 : newHike;
    });

    for (int i = 0; i < _estimateRows.length; i++) {
      _calculateEstimate(i);
    }

    _calculateGrandTotal();
  }

  void _calculateEstimate(int index) {
    final row = _estimateRows[index];
    final length = evaluateExpression(row.lengthInput);
    final height = evaluateExpression(row.heightInput);

    if (length == 0 || height == 0) {
      _saveDraftLocally(); // ✅ Still save partial data
      return;
    }

    final area = (length / 304.8) * (height / 304.8);
    double hikeFactor = 1 - ((hikePercentage > 0 ? hikePercentage : 20) / 100);
    double rate = double.tryParse(row.rateController.text) ?? 0.0;

    setState(() {
      row.area = area.ceilToDouble();

      double minRate = switch (row.selectedModel) {
        'Wooden Window' => 125,
        'UPVC Window' => 200,
        'Sliding Model' || 'Pleated model' => 275,
        _ => 0,
      };

      double userRate = double.tryParse(row.rateController.text) ?? 0;
      if (userRate < minRate) {
        userRate = minRate;
        row.rateController.text = minRate.toStringAsFixed(0);
      }
      row.amount = (row.area * rate) / hikeFactor;
      _saveDraftLocally();
    });
  }

  void _calculateGrandTotal() {
    double total = 0;

    for (var row in _estimateRows) {
      total += row.amount;
    }

    if (total == 0) return;

    double gst = total * 0.18;
    double grandAmount = total + gst;

    setState(() {
      grandTotal = total;
      gstAmount = gst;
      this.grandAmount = grandAmount;
    });
  }

  Future<void> _saveEstimateToDatabase() async {
    try {
      const String baseUrl = "http://127.0.0.1:4000/api/mosquito";
      // Step 1: Fetch latest version for customer
      double latestVersion = 0.0;
      String newVersion = '';
      // Retrieve token from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        throw Exception("Token is missing.");
      }
      final latestVersionResponse = await http
          .get(Uri.parse("$baseUrl/latest/${widget.customerId}"), headers: {
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

        // Correct the new version without adding an additional `+1`
        newVersion = "$major.$minor"; // Correct minor version increment

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

      Map<String, dynamic> estimateData = {
        'customerId': widget.customerId,
        'hike': double.tryParse(hikeController.text) ?? 0.0,
        'gst': gstAmount,
        'totalAmount': grandAmount,
        'timestamp': DateTime.now().toIso8601String(),
        'version': newVersion,
        'estimateType': 'mosquitonet',
        'status': 'InProgress',
        'stage': computedStage,
      };

      // Post request to create a new estimate with userId
      final response = await http.post(
        Uri.parse("$baseUrl/mosquitoNet-estimates"),
        headers: {
          'Authorization': 'Bearer $token',
          "Content-Type": "application/json",
        },
        body: jsonEncode(estimateData),
      );

      if (response.statusCode != 201) {
        var errorData = jsonDecode(response.body);
        throw Exception(
            "Failed to save estimate. Error: ${errorData['error']}");
      }

      int estimateId = jsonDecode(response.body)['id'] ?? 0;

      List<Map<String, dynamic>> estimateRows = _estimateRows
          .map((row) => {
                'estimateId': estimateId,
                'room': row.selectedRoom,
                'window': row.selectedWindowType,
                'additional_Info': row.additionalInfoController.text,
                'model': row.selectedModel,
                'length': double.tryParse(row.lengthController.text) ?? 0.0,
                'height': double.tryParse(row.heightController.text) ?? 0.0,
                'area': row.area,
                'rate': double.tryParse(row.rateController.text) ?? 0.0,
                'amount': row.amount,
              })
          .toList();

      final detailsResponse = await http.post(
        Uri.parse("$baseUrl/mosquitoNet-estimate-rows"),
        headers: {
          'Authorization': 'Bearer $token',
          "Content-Type": "application/json",
        },
        body: jsonEncode({'details': estimateRows}),
      );
      await Provider.of<NotificationProvider>(context, listen: false)
          .refreshNotifications();
      if (detailsResponse.statusCode != 201) {
        var detailsError = jsonDecode(detailsResponse.body);
        throw Exception(
            "Failed to save estimate details. Error: ${detailsError['error']}");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('✅ Estimate saved successfully with version $newVersion')),
      );
    } catch (e) {
      print('🔥 Error saving estimate: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error saving estimate: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mosquito Net Estimate'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
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
                  ?.openPage(const mosquitoNetEstimatesPage());
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
                    onPressed: _addNewRow,
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
                          "GST (18%)", "₹${gstAmount.toStringAsFixed(2)}"),
                      const SizedBox(height: 10),
                      _buildSummaryRow(
                        "Grand Total",
                        "₹${grandTotal.toStringAsFixed(2)}",
                        isBold: true,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 16),
                      if (_showHikeField) ...[
                        _buildInputRow("Hike (%)", hikeController),
                      ],
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSummaryRow("GST (18%)",
                                "₹${gstAmount.toStringAsFixed(2)}"),
                            const SizedBox(height: 10),
                            _buildSummaryRow(
                              "Grand Total",
                              "₹${grandTotal.toStringAsFixed(2)}",
                              isBold: true,
                              color: Colors.green,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 30),
                      Expanded(
                        child: Visibility(
                          visible: _showHikeField,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputRow("Hike (%)", hikeController),
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
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEstimateTable() {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 24.0,
          headingRowHeight: 50,
          dataRowHeight: 60,
          columns: const [
            DataColumn(label: Text('Sr.no.')),
            DataColumn(label: Text('Room')),
            DataColumn(label: Text('Type of Window')),
            DataColumn(label: Text('Additional Information')),
            DataColumn(label: Text('Model')),
            DataColumn(label: Text('Length')),
            DataColumn(label: Text('Height')),
            DataColumn(label: Text('Area')),
            DataColumn(label: Text('Rate')),
            DataColumn(label: Text('Amount')),
            DataColumn(label: Text('Action'))
          ],
          rows: _estimateRows.map((row) {
            final index = _estimateRows.indexOf(row);
            return DataRow(cells: [
              DataCell(Text((index + 1).toString())),
              _buildRoomDropdown(row),
              _buildWindowTypeDropdown(row),
              DataCell(TextField(controller: row.additionalInfoController)),
              _buildModelDropdown(row),
              _buildEditableExpressionCell(
                  row.lengthController, row.lengthInput, index, true),
              _buildEditableExpressionCell(
                  row.heightController, row.heightInput, index, false),
              DataCell(Text(row.area.toStringAsFixed(2))),
              _buildEditableDataCell(row.rateController, index, false),
              DataCell(Text(row.amount.toStringAsFixed(2))),
              DataCell(
                IconButton(
                  onPressed: () => _deleteRow(index),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              )
            ]);
          }).toList(),
        ),
      ),
    );
  }

  _buildRoomDropdown(EstimateRow row) {
    return DataCell(
      DropdownButton<String>(
        value: _validateDropdownValue(row.selectedRoom,
            ['Living Room', 'Bedroom', 'Kitchen', 'Bathroom'], 'Living Room'),
        items: ['Living Room', 'Bedroom', 'Kitchen', 'Bathroom']
            .map((value) => DropdownMenuItem(value: value, child: Text(value)))
            .toList(),
        onChanged: (newValue) {
          setState(() {
            row.selectedRoom = newValue!;
            _saveDraftLocally();
          });
        },
      ),
    );
  }

  _buildWindowTypeDropdown(EstimateRow row) {
    return DataCell(
      DropdownButton<String>(
        value: _validateDropdownValue(
            row.selectedWindowType,
            [
              'Window 1',
              'Window 2',
              'Balcony',
              'Bay Window 1',
              'Bay Window 2',
              'Door'
            ],
            'Window 1'),
        items: [
          'Window 1',
          'Window 2',
          'Balcony',
          'Bay Window 1',
          'Bay Window 2',
          'Door'
        ]
            .map((value) => DropdownMenuItem(value: value, child: Text(value)))
            .toList(),
        onChanged: (newValue) {
          setState(() {
            row.selectedWindowType = newValue!;
            _saveDraftLocally();
          });
        },
      ),
    );
  }

  _buildModelDropdown(EstimateRow row) {
    return DataCell(
      DropdownButton<String>(
        value: _validateDropdownValue(
            row.selectedModel,
            ['Wooden Window', 'UPVC Window', 'Sliding Model', 'Pleated model'],
            'Wooden Window'),
        items: [
          'Wooden Window',
          'UPVC Window',
          'Sliding Model',
          'Pleated model'
        ]
            .map((value) => DropdownMenuItem(value: value, child: Text(value)))
            .toList(),
        onChanged: (newValue) {
          setState(() {
            row.selectedModel = newValue!;
            _saveDraftLocally();
          });
        },
      ),
    );
  }

  String _validateDropdownValue(
      String? currentValue, List<String> validOptions, String defaultValue) {
    return (currentValue != null && validOptions.contains(currentValue))
        ? currentValue
        : defaultValue;
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
                _saveDraftLocally();
              },
              onSubmitted: (value) {
                _onFieldSubmitted(index, value, isLength: isLength);
                _saveDraftLocally();
              },
              decoration: const InputDecoration(
                hintText: 'eg."=100+20"',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                contentPadding: EdgeInsets.symmetric(vertical: 8.0),
              ),
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
        onSubmitted: (_) {
          _calculateEstimate(index);
          _saveDraftLocally();
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
