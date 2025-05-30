import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../widgets/sidebar_menu.dart';
import '../../providers/notification_provider.dart';
import 'Flooring_Estimate_Summary_Page.dart';
import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FlooringEstimateRow {
  String description = 'Hall';
  String lengthInput = '';
  String widthInput = '';
  double area = 0.0;
  double perBox = 0.0;
  double totalRequired = 0.0;
  double boxes = 0.0;
  double areaRequired = 0.0;
  double ratePerSqft = 0.0;
  double totalAmount = 0.0;

  TextEditingController lengthController = TextEditingController();
  TextEditingController widthController = TextEditingController();
  TextEditingController perBoxController = TextEditingController();
  TextEditingController rateController = TextEditingController();
}

class EstimateSummary {
  String estimateName;
  double installationCost;
  double foam;
  double transport;
  double totalAmount;
  double subtotal;
  double gst;
  double grandTotal;
  String? status;
  String? stage;

  // Controllers for installation, foam, and transport
  TextEditingController installController = TextEditingController();
  TextEditingController foamController = TextEditingController();
  TextEditingController transportController = TextEditingController();

  EstimateSummary(
      {required this.estimateName,
      this.installationCost = 0.0,
      this.foam = 0.0,
      this.transport = 0.0,
      this.totalAmount = 0.0,
      this.subtotal = 0.0,
      this.gst = 0.0,
      this.grandTotal = 0.0,
      this.status,
      this.stage});

  void calculateGrandTotal() {
    subtotal = installationCost + foam + transport + totalAmount;
    gst = subtotal * 0.18;
    grandTotal = subtotal + gst;
  }
}

class FlooringEstimate extends StatefulWidget {
  final int customerId;
  final int? estimateId;
  final Map<String, dynamic>? customerInfo;
  final String customerName; // Ensure these are passed correctly
  final String customerEmail;
  final String customerPhone;
  final Map<String, dynamic>? estimateData;

  const FlooringEstimate({
    super.key,
    required this.customerId,
    this.estimateId,
    this.customerInfo,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    this.estimateData,
  });

  @override
  _FlooringEstimateState createState() => _FlooringEstimateState();
}

class _FlooringEstimateState extends State<FlooringEstimate> {
  final List<FlooringEstimateRow> _spcRows = [FlooringEstimateRow()];
  final List<FlooringEstimateRow> _woodenRows = [FlooringEstimateRow()];
  final List<FlooringEstimateRow> _charcoalRows = [FlooringEstimateRow()];
  final List<FlooringEstimateRow> _vinylRows = [FlooringEstimateRow()];

  String _selectedEstimateType = 'SPC'; // Default to SPC
  double grandTotal = 0;
  double gstAmount = 0;
  double grandAmount = 0;
  double installationCost = 0;
  double foam = 0;
  double transport = 0;
  double totalAmount = 0;
  double subtotal = 0;

  // Separate totals for each type
  double spcTotal = 0;
  double woodenTotal = 0;
  double charcoalTotal = 0;
  double vinylTotal = 0;

  TextEditingController installController = TextEditingController();
  TextEditingController foamController = TextEditingController();
  TextEditingController transportController = TextEditingController();

  bool _showHikeField = false;

  @override
  void initState() {
    super.initState();
    if (widget.estimateData != null &&
        widget.estimateData!['summary'] != null) {
      _loadExistingEstimate(widget.estimateData!);
    } else {
      _checkAndLoadDraft(); // Load saved draft only for new estimate
    }
    _calculateGrandTotal();
  }

  //auto save
  Future<void> _saveDraftLocally() async {
    final prefs = await SharedPreferences.getInstance();

    final draftRows = _getSelectedEstimateRows()
        .map((row) => {
              'description': row.description,
              'length': row.lengthController.text,
              'width': row.widthController.text,
              'rate': row.rateController.text,
            })
        .toList();

    final currentSummary = estimateSummaries.firstWhere(
      (summary) => summary.estimateName == _selectedEstimateType,
      orElse: () => EstimateSummary(estimateName: _selectedEstimateType),
    );

    final draftData = {
      'estimateType': _selectedEstimateType,
      'rows': draftRows,
      'install': currentSummary.installController.text,
      'foam': currentSummary.foamController.text,
      'transport': currentSummary.transportController.text,
    };

    await prefs.setString('flooring_draft', jsonEncode(draftData));
    debugPrint("📝 Flooring draft saved.");
  }

  Future<void> _checkAndLoadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('flooring_draft');

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
      builder: (_) => AlertDialog(
        title: const Text("Restore Draft?"),
        content:
            const Text("A saved draft was found. Do you want to restore it?"),
        actions: [
          TextButton(
            child: const Text("No"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Restore"),
            onPressed: () {
              Navigator.pop(context);
              _loadDraftEstimate(draftData);
            },
          ),
        ],
      ),
    );
  }

  void _loadDraftEstimate(Map<String, dynamic> draftData) {
    final type = draftData['estimateType'] ?? 'SPC';
    _selectedEstimateType = type;

    final rows = draftData['rows'] as List;
    final targetRows = _getSelectedEstimateRows();
    targetRows.clear();

    for (var rowData in rows) {
      final row = FlooringEstimateRow()
        ..description = rowData['description'] ?? 'Hall'
        ..lengthInput = rowData['length'] ?? ''
        ..widthInput = rowData['width'] ?? ''
        ..ratePerSqft = double.tryParse(rowData['rate'] ?? '') ?? 165;

      row.lengthController.text = row.lengthInput;
      row.widthController.text = row.widthInput;
      row.rateController.text = row.ratePerSqft.toString();

      targetRows.add(row);
    }

    final summary = estimateSummaries.firstWhere(
      (s) => s.estimateName == type,
      orElse: () => EstimateSummary(estimateName: type),
    );

    summary.installController.text = draftData['install'] ?? '0';
    summary.foamController.text = draftData['foam'] ?? '0';
    summary.transportController.text = draftData['transport'] ?? '0';

    setState(() {
      _calculateGrandTotal();
    });
  }

  Future<void> clearDraftLocally() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('quartz_draft');
    debugPrint("🗑️ Quartz draft cleared.");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quartz draft cleared.')),
    );
  }

  //end

  void _addNewRow() {
    setState(() {
      switch (_selectedEstimateType) {
        case 'SPC':
          _spcRows.add(FlooringEstimateRow());
          break;
        case 'WOODEN':
          _woodenRows.add(FlooringEstimateRow());
          break;
        case 'CHARCOAL':
          _charcoalRows.add(FlooringEstimateRow());
          break;
        case 'VINYL':
          _vinylRows.add(FlooringEstimateRow());
          break;
      }
    });
  }

  void _deleteRow(int index) {
    setState(() {
      final rows = _getSelectedEstimateRows();
      if (rows.length > 1) {
        // Ensure at least one row remains
        rows.removeAt(index);
      }
      _calculateGrandTotal();
    });
  }

  void _calculateEstimate(int index) {
    final rows = _getSelectedEstimateRows();

    if (index < 0 || index >= rows.length) {
      print('Error: Invalid index $index');
      return;
    }

    final row = rows[index];

    // Set default perBox values based on the selected estimate type
    switch (_selectedEstimateType) {
      case 'SPC':
        row.perBox = row.description == 'Skirting Profile' ||
                row.description == 'Reducer'
            ? 8.0
            : 17.75;
        break;
      case 'WOODEN':
        row.perBox = 20.66;
        break;
      case 'CHARCOAL':
        row.perBox = 18.59;
        break;
      case 'VINYL':
        row.perBox = 48.00;
        break;
    }

    double length = evaluateExpression(row.lengthInput);
    double width = evaluateExpression(row.widthInput);
    double area = (length / 304.8) * (width / 304.8);
    double rate = double.tryParse(row.rateController.text) ?? 165;
    double ratePerSqft = rate;

    setState(() {
      if (row.description == 'Skirting Profile' ||
          row.description == 'Reducer') {
        row.widthInput = '-';
        area = length;
        row.area = (area).ceilToDouble();
        ratePerSqft = (rate < 600) ? 600 : rate;
        row.ratePerSqft = ratePerSqft;
      } else {
        area = (length / 304.8) * (width / 304.8);
        row.area = (area * 1.1).ceilToDouble();
        ratePerSqft = (rate < 165) ? 165 : rate;
        row.ratePerSqft = ratePerSqft;
        row.areaRequired = (row.boxes * row.perBox);
      }

      row.totalRequired = (row.area / row.perBox);
      row.boxes = row.totalRequired.ceilToDouble();

      if (row.description == 'Skirting Profile' ||
          row.description == 'Reducer') {
        row.totalAmount = (row.boxes * ratePerSqft);
      } else {
        row.totalAmount = (row.areaRequired * ratePerSqft);
      }
    });

    // Recalculate the grand total
    _calculateGrandTotal();
  }

  void _calculateGrandTotal() {
    // Get the current estimate type
    EstimateSummary currentSummary = estimateSummaries.firstWhere(
      (summary) => summary.estimateName == _selectedEstimateType,
      orElse: () => EstimateSummary(estimateName: _selectedEstimateType),
    );

    // Get the selected estimate rows
    List<FlooringEstimateRow> selectedRows = _getSelectedEstimateRows();

    // Calculate the total area for the selected estimate type
    double totalArea = selectedRows.fold(0.0, (sum, row) => sum + row.area);

    // Get the installation rate, foam, and transport from the current summary
    double installRate =
        double.tryParse(currentSummary.installController.text) ?? 0;
    double foam = double.tryParse(currentSummary.foamController.text) ?? 0;
    double transport =
        double.tryParse(currentSummary.transportController.text) ?? 0;

    // Calculate installation cost: total area * installation rate
    double installationCost = totalArea * installRate;

    // Calculate the total amount for the selected estimate type
    double totalAmount = _calculateTypeTotal(selectedRows);

    // Calculate subtotal: installation cost + foam + transport + total amount
    double subtotal = installationCost + foam + transport + totalAmount;

    // Calculate GST: subtotal * 0.18
    double gst = subtotal * 0.18;

    // Calculate grand total: subtotal + GST
    double grandTotal = subtotal + gst;

    setState(() {
      // Update the current summary values
      currentSummary.installationCost = installationCost;
      currentSummary.foam = foam;
      currentSummary.transport = transport;
      currentSummary.totalAmount = totalAmount.ceilToDouble();
      currentSummary.subtotal = subtotal;
      currentSummary.gst = gst;
      currentSummary.grandTotal = grandTotal;
    });
  }

  double _calculateTypeTotal(List<FlooringEstimateRow> rows) {
    double total = 0;
    for (var row in rows) {
      // Sum of total amount, install, foam, and transport for each row
      total += row.totalAmount.ceilToDouble();
    }
    return total;
  }

  List<FlooringEstimateRow> _getSelectedEstimateRows() {
    switch (_selectedEstimateType) {
      case 'SPC':
        return _spcRows;
      case 'WOODEN':
        return _woodenRows;
      case 'CHARCOAL':
        return _charcoalRows;
      case 'VINYL':
        return _vinylRows;
      default:
        return [];
    }
  }

  List<EstimateSummary> estimateSummaries = [
    EstimateSummary(estimateName: 'SPC'),
    EstimateSummary(estimateName: 'WOODEN'),
    EstimateSummary(estimateName: 'CHARCOAL'),
    EstimateSummary(estimateName: 'VINYL'),
  ];

  final List<String> _descriptionOptions = [
    'Hall',
    'Foyer',
    'Passage',
    'Bath Passage',
    'Bedroom 1',
    'Bedroom 2',
    'Bedroom 3',
    'Skirting Profile',
    'Reducer',
  ];

  void _saveEstimateToDatabase() async {
    try {
      const String baseUrl = "http://127.0.0.1:4000/api";
      String newVersion = "1.1"; // Default for new estimates

      // Step 1: Fetch the latest version if it's a new estimate
      if (widget.estimateId == null) {
        final latestVersionResponse =
            await http.get(Uri.parse("$baseUrl/latest/${widget.customerId}"));
        double latestVersion = 0.0;

        if (latestVersionResponse.statusCode == 200) {
          var data = jsonDecode(latestVersionResponse.body);
          latestVersion = double.tryParse(data['version'].toString()) ?? 0.0;
        }

        // Step 2: Calculate the new version
        newVersion =
            latestVersion == 0.0 ? "1.1" : _calculateNextVersion(latestVersion);
      } else {
        // If editing an existing estimate, increment based on the old version
        var oldVersion =
            widget.estimateData?['summary']?['version']?.toString() ?? "0.0";
        double parsedVersion = double.tryParse(oldVersion) ?? 0.0;
        newVersion = _calculateNextVersion(parsedVersion);
      }

      // Get current summary based on selected estimate type
      EstimateSummary currentSummary = estimateSummaries.firstWhere(
        (summary) => summary.estimateName == _selectedEstimateType,
        orElse: () => EstimateSummary(
          estimateName: 'Unknown',
          installationCost: 0.0,
          foam: 0.0,
          transport: 0.0,
          gst: 0.0,
          grandTotal: 0.0,
        ),
      );

      // Step 3: Get userId from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? userId = prefs.getInt('userId'); // Retrieve as integer directly

      if (userId == null) {
        print('❌ Error: UserId is null');
        throw Exception("User is not authenticated. Cannot save estimate.");
      }

      // Step 4: Retrieve the token from SharedPreferences
      String? token = prefs.getString('token'); // Retrieve token

      if (token == null) {
        print('❌ Error: Token is missing');
        throw Exception("Token is missing");
      }
      String getStageFromVersion(String version) {
        int major = int.tryParse(version.split('.').first) ?? 1;
        if (major == 1) return 'Sales';
        if (major == 2) return 'Pre-Designer';
        if (major == 3) return 'Designer';
        return 'Sales';
      }

      String computedStage = getStageFromVersion(newVersion);
      // Prepare the estimate data
      Map<String, dynamic> estimateData = {
        'customerId': widget.customerId,
        'user_id': userId,
        'customer_name': widget.customerInfo!['name'],
        'installation_cost': currentSummary.installationCost,
        'foam': currentSummary.foam,
        'transport_charges': currentSummary.transport,
        'gst': currentSummary.gst,
        'totalAmount': currentSummary.grandTotal,
        'version': newVersion,
        'timestamp': DateTime.now().toIso8601String(),
        'flooringType': _selectedEstimateType,
        'estimateType': 'flooring',
        'status': 'InProgress',
        'stage': computedStage,
        'rows': _getSelectedEstimateRows()
            .map((row) => {
                  'description': row.description,
                  'length': double.tryParse(row.lengthController.text) ?? 0.0,
                  'width': double.tryParse(row.widthController.text) ?? 0.0,
                  'area': row.area,
                  'perBox': row.perBox,
                  'totalRequired': row.totalRequired,
                  'boxes': row.boxes,
                  'areaRequired': row.areaRequired,
                  'ratePerSqft': row.ratePerSqft,
                  'totalAmount': row.totalAmount,
                })
            .toList(),
      };

      // Send the POST request to save the estimate
      final response = await http.post(
        Uri.parse("$baseUrl/flooring-estimates"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // Including the token
        },
        body: jsonEncode(estimateData),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Estimate saved with version $newVersion')),
        );

        var savedData = jsonDecode(response.body);
        int newEstimateId = savedData['id'];

        SidebarController.of(context)
            ?.openPage(FlooringEstimateSummaryPage(customerId: newEstimateId));
        await Provider.of<NotificationProvider>(context, listen: false)
            .refreshNotifications();
      } else {
        var errorData = jsonDecode(response.body);
        throw Exception(
            "Failed to save estimate. Error: ${errorData['error']}");
      }
    } catch (e) {
      print('🔥 Error saving estimate: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error saving estimate: $e')),
      );
    }
  }

// Function to calculate the next version number based on the current version
  String _calculateNextVersion(double currentVersion) {
    int major = currentVersion.floor();
    int minor = ((currentVersion - major) * 10).floor();

    // If minor version is 9, reset minor and increment major
    if (minor >= 9) {
      major += 1;
      minor = 0;
    } else {
      minor += 1; // Otherwise, just increment minor version
    }

    return "$major.$minor";
  }

  void _loadExistingEstimate(Map<String, dynamic> estimateData) {
    final summary = estimateData['summary'];
    final rows = estimateData['rows'] ?? [];

    _selectedEstimateType = summary['flooringType'] ?? 'SPC';

    EstimateSummary currentSummary = estimateSummaries.firstWhere(
      (summary) => summary.estimateName == _selectedEstimateType,
    );

    currentSummary.installationCost =
        double.tryParse(summary['installation_cost'].toString()) ?? 0.0;
    currentSummary.foam = double.tryParse(summary['foam'].toString()) ?? 0.0;
    currentSummary.transport =
        double.tryParse(summary['transport_charges'].toString()) ?? 0.0;
    currentSummary.gst = double.tryParse(summary['gst'].toString()) ?? 0.0;
    currentSummary.grandTotal =
        double.tryParse(summary['totalAmount'].toString()) ?? 0.0;

    currentSummary.installController.text =
        currentSummary.installationCost.toString();
    currentSummary.foamController.text = currentSummary.foam.toString();
    currentSummary.transportController.text =
        currentSummary.transport.toString();

    List<FlooringEstimateRow> targetRows = _getSelectedEstimateRows();
    targetRows.clear();

    for (var rowData in rows) {
      var row = FlooringEstimateRow()
        ..description = rowData['description'] ?? ''
        ..lengthInput = rowData['length'].toString()
        ..widthInput = rowData['width'].toString()
        ..area = double.tryParse(rowData['area'].toString()) ?? 0.0
        ..perBox = double.tryParse(rowData['perBox'].toString()) ?? 0.0
        ..totalRequired =
            double.tryParse(rowData['totalRequired'].toString()) ?? 0.0
        ..boxes = double.tryParse(rowData['boxes'].toString()) ?? 0.0
        ..areaRequired =
            double.tryParse(rowData['areaRequired'].toString()) ?? 0.0
        ..ratePerSqft =
            double.tryParse(rowData['ratePerSqft'].toString()) ?? 0.0
        ..totalAmount =
            double.tryParse(rowData['totalAmount'].toString()) ?? 0.0;

      row.lengthController.text = row.lengthInput;
      row.widthController.text = row.widthInput;
      row.rateController.text = row.ratePerSqft.toString();

      targetRows.add(row);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flooring Estimate'),
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
              SidebarController.of(context)?.openPage(
                FlooringEstimateSummaryPage(customerId: widget.customerId),
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
              // 🧠 Responsive Top Section
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
                            Divider(color: Colors.grey.shade300),
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
                              child: _buildCustomerInfo(),
                            ),
                            Container(
                              width: 2,
                              height: 200,
                              color: Colors.grey.shade300,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            Expanded(
                              flex: 3,
                              child: _buildSummaryCard(),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Flooring Type Buttons
              Card(
                elevation: 1,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 20,
                    children: [
                      _buildStyledButton('SPC'),
                      _buildStyledButton('WOODEN'),
                      _buildStyledButton('CHARCOAL'),
                      _buildStyledButton('VINYL'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              _buildEstimateTable(),
              const SizedBox(height: 20),

              // Buttons
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

// Method to build and stylize buttons
  Widget _buildStyledButton(String flooringType) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          backgroundColor: _selectedEstimateType == flooringType
              ? Colors.blueAccent
              : Colors.white,
          foregroundColor: _selectedEstimateType == flooringType
              ? Colors.white
              : Colors.blueAccent,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: () {
          setState(() {
            _selectedEstimateType = flooringType;
          });
        },
        child: Text(flooringType),
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
    EstimateSummary currentSummary = estimateSummaries.firstWhere(
      (summary) => summary.estimateName == _selectedEstimateType,
      orElse: () => EstimateSummary(estimateName: _selectedEstimateType),
    );

    currentSummary.totalAmount =
        _calculateTypeTotal(_getSelectedEstimateRows());

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
                ? _buildMobileSummaryColumn(currentSummary)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Summary for Selected Flooring Type:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildSummaryTable(currentSummary),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryTable(EstimateSummary currentSummary) {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: FlexColumnWidth(1.4), // Estimate name
        1: FlexColumnWidth(1.2), // Installation
        2: FlexColumnWidth(1), // Foam Sheet
        3: FlexColumnWidth(1.2), // Transport
        4: FlexColumnWidth(1), // Total Amount
        5: FlexColumnWidth(1), // GST
        6: FlexColumnWidth(1), // Grand Total
      },
      children: [
        _buildTableHeaderRow(),
        _buildSummaryRow(currentSummary),
      ],
    );
  }

  Widget _buildMobileSummaryColumn(EstimateSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary - $_selectedEstimateType',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildLabeledTextField("Installation", summary.installController,
            (value) {
          summary.installationCost = double.tryParse(value) ?? 0.0;
          _calculateGrandTotal();
        }),
        const SizedBox(height: 10),
        _buildLabeledTextField("Foam Sheet", summary.foamController, (value) {
          summary.foam = double.tryParse(value) ?? 0.0;
          _calculateGrandTotal();
        }),
        const SizedBox(height: 10),
        _buildLabeledTextField("Transport", summary.transportController,
            (value) {
          summary.transport = double.tryParse(value) ?? 0.0;
          _calculateGrandTotal();
        }),
        const SizedBox(height: 10),
        _buildReadOnlyRow("Total Amount", summary.totalAmount),
        const SizedBox(height: 8),
        _buildReadOnlyRow("Sub Total", summary.subtotal),
        const SizedBox(height: 8),
        _buildReadOnlyRow("GST (18%)", summary.gst),
        const SizedBox(height: 8),
        _buildReadOnlyRow("Grand Total", summary.grandTotal,
            isBold: true, color: Colors.green),
      ],
    );
  }

  TableRow _buildTableHeaderRow() {
    return TableRow(
      decoration:
          BoxDecoration(color: Colors.grey[200]), // Header background color
      children: const [
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Estimate',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Installation',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Foam Sheet',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Transport',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Total Amount',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Sub Total',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'GST (18%)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Grand Total',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildLabeledTextField(String label, TextEditingController controller,
      Function(String) onChanged) {
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
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyRow(String label, double value,
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
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '₹${value.toStringAsFixed(2)}',
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

  TableRow _buildSummaryRow(EstimateSummary summary) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            summary.estimateName,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: TextField(
            controller: summary.installController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(border: InputBorder.none),
            textAlign: TextAlign.right,
            onChanged: (value) {
              setState(() {
                summary.installationCost = double.tryParse(value) ?? 0.0;
                _calculateGrandTotal(); // Recalculate grand total
                _saveDraftLocally();
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: TextField(
            controller: summary.foamController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(border: InputBorder.none),
            textAlign: TextAlign.right,
            onChanged: (value) {
              setState(() {
                summary.foam = double.tryParse(value) ?? 0.0;
                _calculateGrandTotal(); // Recalculate grand total
                _saveDraftLocally();
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: TextField(
            controller: summary.transportController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.right,
            decoration: const InputDecoration(border: InputBorder.none),
            onChanged: (value) {
              setState(() {
                summary.transport = double.tryParse(value) ?? 0.0;
                _calculateGrandTotal(); // Recalculate grand total
                _saveDraftLocally();
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            '₹${summary.totalAmount.ceilToDouble().toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.right,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            '₹${summary.subtotal.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.right,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            '₹${summary.gst.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.right,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            '₹${summary.grandTotal.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildEstimateTable() {
    return Card(
      elevation: 3,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 24.0,
          headingRowHeight: 50,
          dataRowHeight: 60,
          columns: const [
            DataColumn(label: Text('Sl.No.')),
            DataColumn(label: Text('Description')),
            DataColumn(label: Text('Length')),
            DataColumn(
                label:
                    Text('Width')), // This column will be conditionally hidden
            DataColumn(label: Text('Area')),
            DataColumn(label: Text('Per Box')),
            DataColumn(label: Text('Total Required')),
            DataColumn(label: Text('Boxes')),
            DataColumn(label: Text('Area Required')),
            DataColumn(label: Text('Rate/Sq.ft')),
            DataColumn(label: Text('Total Amount')),
            DataColumn(label: Text('Action')),
          ],
          rows: _getSelectedEstimateRows().map((row) {
            final index = _getSelectedEstimateRows().indexOf(row);
            return DataRow(cells: [
              DataCell(Text((index + 1).toString())),
              // Description Dropdown
              DataCell(DropdownButton<String>(
                value: row.description.isEmpty ? 'Hall' : row.description,
                items: _descriptionOptions.map((String option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    row.description = newValue!;
                    _calculateEstimate(
                        index); // Recalculate estimate when description changes
                    _saveDraftLocally();
                  });
                },
              )),
              _buildEditableExpressionCell(
                  row.lengthController, row.lengthInput, index, true),
              if (row.description == 'Skirting Profile' ||
                  row.description == 'Reducer')
                const DataCell(Text(
                  '< enter\nin RFT',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ))
              else
                _buildEditableExpressionCell(
                    row.widthController, row.widthInput, index, false),
              DataCell(Text(row.area.toStringAsFixed(2))),
              // Per Box, Total Required, etc.
              DataCell(Text(row.perBox.toStringAsFixed(2))),
              DataCell(Text(row.totalRequired.toStringAsFixed(2))),
              DataCell(Text(row.boxes.toString())),
              DataCell(Text(row.areaRequired.toStringAsFixed(2))),
              _buildDataCell(row.rateController, index, isLength: false),
              DataCell(Text(row.totalAmount.ceilToDouble().toStringAsFixed(2))),
              DataCell(
                IconButton(
                  onPressed: () => _deleteRow(index),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  DataCell _buildDataCell(TextEditingController controller, int index,
      {required bool isLength}) {
    return DataCell(
      TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(border: UnderlineInputBorder()),
          onChanged: (_) {
            _calculateEstimate(index);
            _saveDraftLocally();
          }),
    );
  }

  DataCell _buildEditableExpressionCell(TextEditingController controller,
      String expression, int index, bool isLength) {
    if (index < 0 || index >= _getSelectedEstimateRows().length) {
      print('Error: Invalid index $index');
      return const DataCell(
          SizedBox.shrink()); // Return empty DataCell on invalid index
    }

    return DataCell(
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              onChanged: (_) {
                // Only calculate the estimate if the index is valid
                if (index >= 0 && index < _getSelectedEstimateRows().length) {
                  _calculateEstimate(index);
                  _saveDraftLocally();
                }
              },
              onSubmitted: (value) {
                // Ensure the index is valid before submission
                if (index >= 0 && index < _getSelectedEstimateRows().length) {
                  _onFieldSubmitted(index, value, isLength: isLength);
                } else {
                  print('Error: Invalid index $index');
                }
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
              // Ensure the index is valid before opening dialog
              if (index >= 0 && index < _getSelectedEstimateRows().length) {
                _editExpressionDialog(index, expression, isLength);
              } else {
                print('Error: Invalid index $index');
              }
            },
          ),
        ],
      ),
    );
  }

  void _editExpressionDialog(int index, String expression, bool isLength) {
    if (index < 0 || index >= _getSelectedEstimateRows().length) {
      print('Error: Invalid index $index');
      return;
    }

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
                if (index >= 0 && index < _getSelectedEstimateRows().length) {
                  _onFieldSubmitted(index, controller.text, isLength: isLength);
                  Navigator.of(context).pop();
                } else {
                  print('Error: Invalid index $index');
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _onFieldSubmitted(int rowIndex, String value, {required bool isLength}) {
    // Ensure rowIndex is valid before accessing list
    if (rowIndex < 0 || rowIndex >= _getSelectedEstimateRows().length) {
      print('Error: Invalid rowIndex $rowIndex');
      return;
    }

    setState(() {
      final row = _getSelectedEstimateRows()[rowIndex];
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
}
