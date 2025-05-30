import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../database/q_database_helper.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../modules/estimate/pages/QuartzSlabEstimateListPage.dart';
import '../../../services/customer_database_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../widgets/sidebar_menu.dart';
import '../../providers/notification_provider.dart';

class EstimateQRow {
  String description;
  String? status;
  String? stage;
  final TextEditingController lengthController = TextEditingController();
  final TextEditingController widthController = TextEditingController();
  final TextEditingController rateController;
  final TextEditingController labourController;

  double area = 0;
  double amount = 0;
  double panelRft = 0;
  bool isSelected = true;

  EstimateQRow({required this.description, this.status, this.stage})
      : labourController =
            TextEditingController(text: _getLabourDefaultValue(description)),
        rateController =
            TextEditingController(text: _getRateDefaultValue(description)) {
    if (description == 'Hob Cutout' ||
        description == 'Sink Cutout' ||
        description == 'Tap Holes / Gas Holes') {
      area = 1.0;
    }
  }

  static String _getLabourDefaultValue(String description) {
    switch (description) {
      case 'Quartz Stone (9\'X5\')':
        return '-';
      case 'Quartz Laying':
        return '160';
      case 'Double Moulding (40mm)/Rft':
        return '150';
      case 'Magaram (45^deg Cutting)/Rft':
        return '150';
      case 'Water Grooving/Rft':
        return '20';
      case 'Edge Polish/Rft':
        return '60';
      case 'Hob Cutout':
        return '900';
      case 'Sink Cutout':
        return '1300';
      case 'Tap Holes/Gas Holes':
        return '300';
      default:
        return '';
    }
  }

  static String _getRateDefaultValue(String description) {
    switch (description) {
      case 'Quartz Stone (9\'X5\')':
        return ' ';
      case 'Quartz Laying':
        return ' ';
      case 'Double Moulding (40mm)/Rft':
        return '-';
      case 'Magaram (45^deg Cutting)/Rft':
        return '-';
      case 'Water Grooving/Rft':
        return '-';
      default:
        return ' ';
    }
  }
}

class QuartzSlabPage extends StatefulWidget {
  final int customerId;
  final int? estimateId;
  final Map<String, dynamic>? customerInfo;
  final String customerName; // Ensure these are passed correctly
  final String customerEmail;
  final String customerPhone;
  final Map<String, dynamic> estimateData;

  const QuartzSlabPage({
    super.key,
    required this.customerId,
    this.estimateId,
    this.customerInfo,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.estimateData,
  });

  @override
  _QuartzSlabPageState createState() => _QuartzSlabPageState();
}

class _QuartzSlabPageState extends State<QuartzSlabPage> {
  final List<EstimateQRow> _estimateRows = [
    EstimateQRow(description: 'Quartz Stone (9\'X5\')'),
    EstimateQRow(description: 'Quartz Laying'),
    EstimateQRow(description: 'Double Moulding (40mm)/Rft'),
    EstimateQRow(description: 'Magaram (45^deg Cutting)/Rft'),
    EstimateQRow(description: 'Water Grooving/Rft'),
    EstimateQRow(description: 'Edge Polish/Rft'),
    EstimateQRow(description: 'Hob Cutout'),
    EstimateQRow(description: 'Sink Cutout'),
    EstimateQRow(description: 'Tap Holes/Gas Holes')
  ];

  double _gstAmount = 0.0;
  double _grandTotal = 0.0;

  final TextEditingController loadingController = TextEditingController();
  final TextEditingController transportController = TextEditingController();
  final TextEditingController gstController = TextEditingController();
  final TextEditingController hikeController = TextEditingController();

  static const double _gstPercentage = 18;
  bool _showHikeField = true;

  List<String> group1Options = [
    'Double Moulding (40mm)/Rft',
    'Magaram (45^deg Cutting)/Rft',
    'Water Grooving/Rft',
    'Edge Polish/Rft'
  ];

  List<String> group2Options = [
    'Hob Cutout',
    'Sink Cutout',
    'Tap Holes/Gas Holes'
  ];
  List<Map<String, dynamic>> _customers = []; // List to store customers
// Store selected customer ID

  @override
  void initState() {
    super.initState();
    _loadCustomers(); // Load customers on initialization
    _fetchCustomers();
    _checkAndLoadDraft();
    if (widget.estimateId != null) {
      _loadEstimateData(widget.estimateId!);
    }
    if (widget.estimateData.isNotEmpty) {
      _loadEstimateFromData(widget.estimateData);
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
              'area': row.area,
              'panelRft': row.panelRft,
              'amount': row.amount,
              'isSelected': row.isSelected,
            })
        .toList();

    final draftData = {
      'rows': draftRows,
      'loading': loadingController.text,
      'transport': transportController.text,
      'hike': hikeController.text,
    };

    await prefs.setString('quartz_draft', jsonEncode(draftData));
    debugPrint("📝 Quartz draft saved locally");
  }

  Future<void> _checkAndLoadDraft() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('quartz_draft');
    debugPrint("📦 Loaded quartz draft JSON: $raw");

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
            onPressed: () => Navigator.of(context).pop(),
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
      loadingController.text = draftData['loading'] ?? '';
      transportController.text = draftData['transport'] ?? '';
      hikeController.text = draftData['hike'] ?? '';

      for (var row in draftData['rows']) {
        final newRow = EstimateQRow(description: row['description'] ?? '')
          ..lengthController.text = row['length'] ?? ''
          ..widthController.text = row['width'] ?? ''
          ..rateController.text = row['rate'] ?? ''
          ..labourController.text = row['labour'] ?? ''
          ..area = row['area'] ?? 0.0
          ..panelRft = row['panelRft'] ?? 0.0
          ..amount = row['amount'] ?? 0.0
          ..isSelected = row['isSelected'] ?? true;

        _estimateRows.add(newRow);
      }

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

  //

  void _loadEstimateFromData(Map<String, dynamic> estimate) {
    final mainEstimate = estimate['estimate'] ?? {};
    final rows = estimate['rows'] as List<dynamic>? ?? [];

    hikeController.text = mainEstimate['hike']?.toString() ?? '0';
    loadingController.text = mainEstimate['loading']?.toString() ?? '0';
    transportController.text = mainEstimate['transport']?.toString() ?? '0';

    // ✅ Safe parsing even if string or number
    _gstAmount =
        double.tryParse(mainEstimate['gstAmount']?.toString() ?? '0') ?? 0.0;

    _estimateRows.clear();
    for (var row in rows) {
      _estimateRows.add(
        EstimateQRow(
          description: row['description']?.toString() ?? '',
        )
          ..lengthController.text = row['length']?.toString() ?? '0'
          ..widthController.text = row['width']?.toString() ?? '0'
          ..rateController.text = row['rate']?.toString() ?? '0'
          ..labourController.text = row['labour']?.toString() ?? '0'
          ..area = double.tryParse(row['area']?.toString() ?? '0') ?? 0.0
          ..panelRft =
              double.tryParse(row['panelRft']?.toString() ?? '0') ?? 0.0
          ..amount = double.tryParse(row['amount']?.toString() ?? '0') ?? 0.0,
      );
    }

    _calculateGrandTotal();
  }

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
      print('Loading estimate data for estimateId: $estimateId');

      // ✅ Fetch estimate data
      Map<String, dynamic>? estimateData =
          await QDatabaseHelper.getQuartzEstimateById(estimateId);

      // ✅ Extract details
      List<Map<String, dynamic>> estimateDetails =
          List<Map<String, dynamic>>.from(estimateData['rows'] ?? []);

      // ✅ Update state (synchronously)
      setState(() {
        hikeController.text =
            estimateData['estimate']['hike']?.toString() ?? '0';
        loadingController.text =
            estimateData['estimate']['loading']?.toString() ?? '0';
        transportController.text =
            estimateData['estimate']['transport']?.toString() ?? '0';
        _gstAmount =
            (estimateData['estimate']['gstAmount'] as num?)?.toDouble() ?? 0.0;

        for (var i = 0; i < _estimateRows.length; i++) {
          var detail = estimateDetails.firstWhere(
            (row) => row['description'] == _estimateRows[i].description,
            orElse: () => <String, dynamic>{},
          );

          if (detail.isNotEmpty) {
            _estimateRows[i].lengthController.text =
                detail['length']?.toString() ?? '';
            _estimateRows[i].widthController.text =
                detail['width']?.toString() ?? '';
            _estimateRows[i].rateController.text =
                detail['rate']?.toString() ?? '';
            _estimateRows[i].labourController.text =
                detail['labour']?.toString() ?? '';
            _estimateRows[i].area = (detail['area'] as num?)?.toDouble() ?? 0.0;
            _estimateRows[i].panelRft =
                (detail['panelRft'] as num?)?.toDouble() ?? 0.0;
            _estimateRows[i].amount =
                (detail['amount'] as num?)?.toDouble() ?? 0.0;
          }
        }
      });

      _calculateGrandTotal();
    } catch (e) {
      print('Error loading estimate data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading estimate data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  Widget _buildCustomerDropdown() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Name: ${widget.customerInfo?['name']}',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'Email: ${widget.customerInfo?['email']}',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'Phone: ${widget.customerInfo?['phone']}',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  void _calculateEstimate(int rowIndex) {
    if (!_estimateRows[rowIndex].isSelected) return;

    double length =
        double.tryParse(_estimateRows[rowIndex].lengthController.text) ?? 0;
    double width =
        double.tryParse(_estimateRows[rowIndex].widthController.text) ?? 0;
    double rate =
        double.tryParse(_estimateRows[rowIndex].rateController.text) ?? 1;
    double labour =
        double.tryParse(_estimateRows[rowIndex].labourController.text) ?? 1;
    double hikePercentage = double.tryParse(hikeController.text) ?? 0;

    if (length <= 2100) length = 2100;
    if (width <= 750) width = 750;

    double area = 0;
    if (_estimateRows[rowIndex].description == 'Quartz Stone (9\'X5\')') {
      if (width > 0) {
        area = (length / 304.8 * width / 304.8).ceilToDouble();
      }
    } else if (_estimateRows[rowIndex].description == 'Quartz Laying') {
      area = (length / 304.8 * width / 304.8).ceilToDouble();
    } else {
      area = (length / 304.8).ceilToDouble();
    }

    if (_estimateRows[rowIndex].description == 'Hob Cutout' ||
        _estimateRows[rowIndex].description == 'Sink Cutout' ||
        _estimateRows[rowIndex].description == 'Tap Holes/Gas Holes') {
      area = 1.0;
    }

    double panelRft = (area / 49).ceilToDouble();
    if (hikePercentage < 20) hikePercentage = 20;

    double amount = 0;
    if (_estimateRows[rowIndex].description == 'Quartz Stone (9\'X5\')') {
      amount = (area * rate);
    } else {
      rate = 1;
      amount = (area * rate * labour) / (1 - hikePercentage / 100);
    }

    setState(() {
      _estimateRows[rowIndex].area = area;
      _estimateRows[rowIndex].panelRft = panelRft;
      _estimateRows[rowIndex].amount = amount.ceilToDouble();
      _calculateGrandTotal();
    });

    // _insertEstimateToDatabase(rowIndex);
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

    double totalAmount = _estimateRows.fold(0, (sum, row) {
      if (row.isSelected) {
        return sum + row.amount;
      }
      return sum;
    });

    double gstAmount =
        (totalAmount + loading + transport) * _gstPercentage / 100;

    setState(() {
      _gstAmount = gstAmount.ceilToDouble();
      _grandTotal =
          (totalAmount + loading + transport + gstAmount).ceilToDouble();
    });
  }

  void _saveEstimateToDatabase() async {
    try {
      const String baseUrl = "http://127.0.0.1:4000/api"; // AWS Server IP
      double latestVersion = 0.0;
      String newVersion = '';

      // Step 1: Retrieve userId from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? userId = prefs.getInt('userId'); // Retrieve as integer directly
      String? token =
          prefs.getString('token'); // Retrieve token from SharedPreferences

      if (userId == null) {
        print('❌ Error: UserId is null');
        throw Exception("User is not authenticated. Cannot save estimate.");
      }

      if (token == null) {
        print('❌ Error: Token is missing');
        throw Exception("Token is missing. Please log in.");
      }

      print("UserId being sent to backend: $userId");
      print("Token being sent to backend: $token");

      // Step 1: Fetch latest version for the customer
      final latestVersionResponse = await http.get(
        Uri.parse("$baseUrl/latest/${widget.customerId}"),
        headers: {'Authorization': 'Bearer $token'},
      );

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

      // Step 3: Prepare estimate data
      Map<String, dynamic> estimateData = {
        'customerId': widget.customerId,
        'hike': double.tryParse(hikeController.text) ?? 0,
        'loading': double.tryParse(loadingController.text) ?? 0,
        'transport': double.tryParse(transportController.text) ?? 0,
        'totalAmount': _grandTotal.toDouble(), // Ensure totalAmount is a double
        'version': newVersion, // Default version
        'estimateType': 'quartz',
        'userId': userId, // Include userId in the request body
        'status': 'InProgress',
        'stage': computedStage,
        'details': _estimateRows
            .where((row) => row.isSelected)
            .map((row) => {
                  'description': row.description,
                  'length': double.tryParse(row.lengthController.text) ?? 0,
                  'width': double.tryParse(row.widthController.text) ?? 0,
                  'area': row.area,
                  'rate': double.tryParse(row.rateController.text) ?? 1,
                  'labour': double.tryParse(row.labourController.text) ?? 1,
                  'amount': row.amount,
                })
            .toList(), // Ensure details is included in the first request
      };

      print("📤 Sending estimate data: ${jsonEncode(estimateData)}");

      // Step 4: Make the request to save the estimate
      final response = await http.post(
        Uri.parse("$baseUrl/save-estimates"),
        headers: {
          "Content-Type": "application/json",
          "Authorization":
              "Bearer $token", // Add the token in the Authorization header
        },
        body: jsonEncode(estimateData),
      );
      await Provider.of<NotificationProvider>(context, listen: false)
          .refreshNotifications();
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Fix extracting the estimate ID
        int estimateId = jsonDecode(response.body)['estimateId'];
        print("✅ Estimate saved successfully with ID: $estimateId");

        // No need for a second API call to save details

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Estimate saved successfully!')),
        );
      } else {
        throw Exception("Failed to save estimate. Response: ${response.body}");
      }
    } catch (e) {
      print('❌ Error saving estimate: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving estimate: $e')),
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
              pw.Text('Quartz Slab Estimation',
                  style: const pw.TextStyle(fontSize: 20)),
              pw.SizedBox(height: 16),
              pw.Table.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>[
                    'Description',
                    'Length',
                    'Width',
                    'area',
                    'Panel (Rft)',
                    'Amount'
                  ],
                  ...estimateData.map((row) => [
                        row['description'] ?? '-',
                        (row['length'] ?? 0).toString(),
                        (row['width'] ?? 0).toString(),
                        (row['area'] ?? 0).toString(),
                        (row['panelRft'] ?? 0)
                            .toString(), // Make sure this matches your field name
                        (row['amount'] ?? 0).toString(),
                      ])
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Text('Grand Total: ₹$_grandTotal',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
            ],
          );
        },
      ),
    );
  }

  void _onSaveAndGeneratePDF() async {
    try {
      // Fetch saved data from the MySQL database through the API
      final response = await http
          .get(Uri.parse("http://127.0.0.1:4000/api/quartz/quartz-estimates"));

      if (response.statusCode == 200) {
        List<Map<String, dynamic>> estimateData =
            List<Map<String, dynamic>>.from(jsonDecode(response.body));

        // Generate the PDF based on the fetched data
        _generatePDF(estimateData);
      } else {
        throw Exception("Failed to fetch estimates for PDF generation.");
      }
    } catch (e) {
      print('Error generating PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    }
  }

  void _clearData() {
    setState(() {
      for (var row in _estimateRows) {
        row.lengthController.clear();
        row.widthController.clear();
        row.panelRft = 0;
        row.rateController.clear();
        row.labourController.clear();
        row.area = 0;
        row.amount = 0;
        row.isSelected = true;
      }
      loadingController.clear();
      transportController.clear();
      _gstAmount = 0;
      _grandTotal = 0;
    });
    QDatabaseHelper.clearData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quartz Slab Estimation'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
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
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            // Use Column instead of Row
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    'Start New Quartz Slab Estimation',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildCustomerDropdown(), // Customer dropdown at the top
              Row(
                // Keep Row for the table and summary section
                children: [
                  _buildEstimateTable(),
                  const SizedBox(width: 20),
                  _buildSummarySection(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstimateTable() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16.0,
                headingRowHeight: 50,
                dataRowHeight: 60,
                columns: const [
                  DataColumn(label: Text('Select')),
                  DataColumn(label: Text('S.No')),
                  DataColumn(label: Text('Description')),
                  DataColumn(label: Text('Length (mm)')),
                  DataColumn(label: Text('Width (mm)')),
                  DataColumn(label: Text('Area (sq.ft)')),
                  DataColumn(label: Text('Panel/Rft')),
                  DataColumn(label: Text('Rate')),
                  DataColumn(label: Text('Labour')),
                  DataColumn(label: Text('Amount')),
                  DataColumn(label: Text('Action'))
                ],
                rows: List<DataRow>.generate(
                  _estimateRows.length,
                  (index) => DataRow(
                    cells: [
                      DataCell(
                        Checkbox(
                          value: _estimateRows[index].isSelected,
                          onChanged: (value) {
                            setState(() {
                              _estimateRows[index].isSelected = value!;
                              _calculateGrandTotal();
                              _saveDraftLocally();
                            });
                          },
                        ),
                      ),
                      DataCell(Text((index + 1).toString())),
                      DataCell(Text(_estimateRows[index].description)),
                      DataCell(
                        _estimateRows[index].description != 'Hob Cutout' &&
                                _estimateRows[index].description !=
                                    'Sink Cutout' &&
                                _estimateRows[index].description !=
                                    'Tap Holes/Gas Holes'
                            ? TextField(
                                controller:
                                    _estimateRows[index].lengthController,
                                onChanged: (value) {
                                  _calculateEstimate(index);
                                  _saveDraftLocally();
                                },
                                keyboardType: TextInputType.number,
                              )
                            : const Text(''),
                      ),
                      DataCell(
                        _estimateRows[index].description != 'Double Moulding (40mm)/Rft' &&
                                _estimateRows[index].description !=
                                    'Magaram (45^deg Cutting)/Rft' &&
                                _estimateRows[index].description !=
                                    'Magaram (45^deg Cutting)/Rft' &&
                                _estimateRows[index].description !=
                                    'Water Grooving/Rft' &&
                                _estimateRows[index].description !=
                                    'Edge Polish/Rft' &&
                                _estimateRows[index].description !=
                                    'Hob Cutout' &&
                                _estimateRows[index].description !=
                                    'Sink Cutout' &&
                                _estimateRows[index].description !=
                                    'Tap Holes/Gas Holes'
                            ? TextField(
                                controller:
                                    _estimateRows[index].widthController,
                                onChanged: (value) => _calculateEstimate(index),
                                keyboardType: TextInputType.number,
                              )
                            : const Text(''),
                      ),
                      DataCell(Text(_estimateRows[index].area.toString())),
                      DataCell(Text(_estimateRows[index].panelRft.toString())),
                      DataCell(
                        _estimateRows[index].description != 'Quartz Laying' &&
                                _estimateRows[index].description !=
                                    'Double Moulding (40mm)/Rft' &&
                                _estimateRows[index].description !=
                                    'Magaram (45^deg Cutting)/Rft' &&
                                _estimateRows[index].description !=
                                    'Magaram (45^deg Cutting)/Rft' &&
                                _estimateRows[index].description !=
                                    'Water Grooving/Rft' &&
                                _estimateRows[index].description !=
                                    'Edge Polish/Rft' &&
                                _estimateRows[index].description !=
                                    'Hob Cutout' &&
                                _estimateRows[index].description !=
                                    'Sink Cutout' &&
                                _estimateRows[index].description !=
                                    'Tap Holes/Gas Holes'
                            ? TextField(
                                controller: _estimateRows[index].rateController,
                                onChanged: (value) {
                                  _calculateEstimate(index);
                                  _saveDraftLocally();
                                },
                                keyboardType: TextInputType.number,
                              )
                            : const Text(''),
                      ),
                      DataCell(_estimateRows[index].description !=
                              'Quartz Stone (9\'X5\')'
                          ? TextField(
                              controller: _estimateRows[index].labourController,
                              onChanged: (value) {
                                _calculateEstimate(index);
                                _saveDraftLocally();
                              },
                              keyboardType: TextInputType.number,
                            )
                          : const Text('')),
                      DataCell(Text(_estimateRows[index].amount.toString())),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: index > 1 ? () => _removeRow(index) : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return SizedBox(
      width: 310,
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SwitchListTile(
                value: _showHikeField,
                onChanged: (value) {
                  setState(() {
                    _showHikeField = value;
                    _saveDraftLocally();
                  });
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
              const Divider(),
              const SizedBox(height: 30),
              const Text('Add Extra Works: '),
              DropdownButton<String>(
                value: null,
                hint: const Text('Select a group'),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    _addRow(newValue);
                  }
                },
                items: [
                  ...group1Options.map((option) {
                    return DropdownMenuItem<String>(
                        value: option, child: Text(option));
                  }),
                  ...group2Options.map((option) {
                    return DropdownMenuItem<String>(
                        value: option, child: Text(option));
                  }),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveEstimateToDatabase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _onSaveAndGeneratePDF,
                child: const Text('Generate PDF'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  SidebarController.of(context)
                      ?.openPage(const QuartzSlabEstimateListPage());
                },
                child: const Text('View Saved Estimates'),
              ),
              const SizedBox(height: 10),
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
                '₹ ${_gstAmount.toStringAsFixed(2)}',
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

  void _addRow(String groupValue) {
    setState(() {
      _estimateRows.add(EstimateQRow(description: groupValue));
    });
  }

  void _removeRow(int index) {
    if (index > 1) {
      setState(() {
        _estimateRows.removeAt(index);
        _calculateGrandTotal(); // Recalculate after removal
      });
    }
  }
}
