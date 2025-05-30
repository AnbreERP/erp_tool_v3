import 'package:erp_tool/modules/estimate/pages/Quartz_Slab_Page.dart';
import 'package:erp_tool/modules/estimate/pages/wallpaper.dart';
import 'package:erp_tool/modules/estimate/pages/weinscoating_estimate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../widgets/sidebar_menu.dart';
import 'charcoal_estimate.dart';
import 'electrical_estimate_page.dart';
import 'false_ceiling_estimate_page.dart';
import 'granite_stone_estimate.dart';
import 'new_woodwork_estimate_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../database/customer_estimate_service.dart';

class CustomerEstimatePage extends StatefulWidget {
  final int customerId;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final Map<String, String> customerInfo;

  const CustomerEstimatePage({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.customerInfo,
  });

  @override
  _CustomerEstimatePageState createState() => _CustomerEstimatePageState();
}

class _CustomerEstimatePageState extends State<CustomerEstimatePage> {
  static const String baseUrl = "http://127.0.0.1:4000/api/customer";
  num? selectedVersion;
  String selectedEstimateType = 'All'; // Default selected estimate type
  String selectedStatus = 'InProgress';
  final List<String> statusOptions = ['InProgress', 'Completed'];
  List<Map<String, dynamic>> estimateData =
      []; // Data for selected estimate type
  List<Map<String, dynamic>> filteredData = [];
  Map<num, List<Map<String, dynamic>>> groupedEstimates = {};
  List<Map<String, dynamic>> estimates = [];
  final List<String> defaultEstimateTypes = [
    'Granite',
    'Woodwork',
    'Electrical',
    'Charcoal',
    'Quartz',
    'Wallpaper',
    'Weinscoating',
    'False Ceiling',
    'Grass', // Added missing estimate type
    'Mosquitonet', // Added missing estimate type
  ];

  final Map<String, String> estimateTypeMap = {
    'woodwork_estimate': 'Woodwork',
    'granite_estimates': 'Granite',
    'charcoal_estimates': 'Charcoal',
    'quartz_slab_estimates': 'Quartz',
    'wallpaper_estimate': 'Wallpaper',
    'weinscoating_estimate': 'Weinscoating',
    'fc_estimates': 'False Ceiling',
    'electrical_estimates': 'Electrical',
    'grass_estimates': 'Grass', // Added missing table mapping
    'mosquitonet_estimates': 'Mosquitonet', // Added missing table mapping
  };

  // Fetch customer info from database based on customerId

  @override
  void initState() {
    super.initState();
    // Initially load all estimates data
    _loadEstimateData(selectedEstimateType).then((_) {
      // Call _setDefaultVersion after the data is loaded
      _setDefaultVersion();
    });
  }

  pw.TextStyle globalStyle(pw.Font ttf, double size, {pw.FontWeight? weight}) {
    return pw.TextStyle(
      font: ttf,
      fontFallback: [ttf],
      fontSize: size,
      fontWeight: weight ?? pw.FontWeight.normal,
    );
  }

  Future<void> _fetchEstimateDetails(String estimateType, num version) async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://127.0.0.1:4000/api/customer/estimate-details/${widget.customerId}/$estimateType/$version'),
      );

      if (response.statusCode == 200) {
        List<Map<String, dynamic>> estimatesWithDetails =
            List<Map<String, dynamic>>.from(json.decode(response.body));

        // You can update your state with the data and display it in your UI
      } else {}
    } catch (e) {
      print('Error fetching estimate details: $e');
    }
  }

  void _onVersionSelected(num version) {
    setState(() {
      selectedVersion = version;
    });

    // Fetch the estimate data and its details for the selected version
    _fetchEstimateDetails(selectedEstimateType, selectedVersion!);
  }

  // Ensure correct parsing and grouping without type issues
  Future<void> _loadEstimateData(String estimateType) async {
    var allEstimates = await fetchAllEstimatesForCustomer(widget.customerId);

    if (allEstimates.isEmpty) {
      return;
    }

    var grouped = <double, List<Map<String, dynamic>>>{};
    var seenEstimateKeys = <String>{};

    for (var estimate in allEstimates) {
      String rawVersion = estimate['version'].toString();
      double version = double.tryParse(rawVersion) ?? 0.0;

      int? estimateId = estimate['estimateId'];
      String rawType = estimate['estimateType'] ?? 'Unknown';
      String normalizedType = estimateTypeMap[rawType] ?? rawType;

      estimate['estimateType'] = normalizedType; // Apply corrected type

      if (estimateId == null || normalizedType == 'Unknown') {
        continue;
      }

      String uniqueKey = '$version-$normalizedType-$estimateId';
      if (seenEstimateKeys.contains(uniqueKey)) continue;
      seenEstimateKeys.add(uniqueKey);

      grouped.putIfAbsent(version, () => []);
      grouped[version]!.add(estimate);
    }

    setState(() {
      groupedEstimates = grouped;
    });
  }

  Future<void> _loadEstimates(String version) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/selected-estimate/${widget.customerId}?version=$version'),
      );

      if (response.statusCode == 200) {
        setState(() {
          estimates =
              List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      } else {
        print('❌ Error fetching estimates for version $version');
      }
    } catch (e) {
      print('❌ Error: $e');
    }
  }

// Helper function to handle various version types and return a string

// Helper function to parse version to a comparable number (double or int)

  final NumberFormat currencyFormatter = NumberFormat('#,##0.00', 'en_IN');

  void _editEstimate(int estimateId) async {
    print('🛠 Editing estimate with ID: $estimateId');

    // Step 1: Find estimate object
    Map<String, dynamic>? estimateToEdit = groupedEstimates.values
        .expand((list) => list)
        .firstWhere((e) => e['estimateId'] == estimateId, orElse: () => {});

    if (estimateToEdit.isEmpty) {
      print('❌ Estimate not found for ID: $estimateId');
      return;
    }

    final estimateType = estimateToEdit['estimateType'] ?? 'Unknown';
    print('📌 Estimate Type: $estimateType');

    int customerId = estimateToEdit['customerId'] ?? widget.customerId;
    String customerName = estimateToEdit['customerName'] ?? widget.customerName;
    String customerEmail =
        estimateToEdit['customerEmail'] ?? widget.customerEmail;
    String customerPhone =
        estimateToEdit['customerPhone'] ?? widget.customerPhone;

    // Step 2: Try to fetch customer info from API if missing
    if (customerName == 'N/A' || customerEmail == 'N/A') {
      try {
        print('🌐 Fetching full customer info for ID: $customerId...');
        final response = await http.get(Uri.parse(
            "http://127.0.0.1:4000/api/customer/customers/$customerId"));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          customerName = data['customerName'] ?? customerName;
          customerEmail = data['email'] ?? customerEmail;
          customerPhone = data['phone'] ?? customerPhone;
        } else {
          print("⚠️ Failed to fetch customer info from API.");
        }
      } catch (e) {
        print("❌ Error fetching customer info: $e");
      }
    }

    // Step 3: Route based on estimate type
    Widget? targetPage;
    switch (estimateType) {
      case 'Woodwork':
        targetPage = NewWoodworkEstimatePage(
          estimateId: estimateId,
          customerId: customerId,
          customerName: customerName,
          customerEmail: customerEmail,
          customerPhone: customerPhone,
          estimateData: estimateToEdit,
        );
        break;
      case 'Electrical':
        targetPage = ElectricalEstimatePage(
          estimateId: estimateId,
          customerId: customerId,
          customerName: customerName,
          customerEmail: customerEmail,
          customerPhone: customerPhone,
          estimateData: estimateToEdit,
        );
        break;
      case 'False Ceiling':
        targetPage = FalseCeilingEstimatePage(
          estimateId: estimateId,
          customerId: customerId,
          customerName: customerName,
          customerEmail: customerEmail,
          customerPhone: customerPhone,
          estimateData: estimateToEdit,
        );
        break;
      case 'Charcoal':
        targetPage = CharcoalEstimate(
          estimateId: estimateId,
          customerId: customerId,
          customerName: customerName,
          customerEmail: customerEmail,
          customerPhone: customerPhone,
          estimateData: estimateToEdit,
        );
        break;
      case 'Quartz':
        targetPage = QuartzSlabPage(
          estimateId: estimateId,
          customerId: customerId,
          customerName: customerName,
          customerEmail: customerEmail,
          customerPhone: customerPhone,
          estimateData: estimateToEdit,
        );
        break;
      case 'Granite':
        targetPage = GraniteStoneEstimate(
          estimateId: estimateId,
          customerId: customerId,
          customerName: customerName,
          customerEmail: customerEmail,
          customerPhone: customerPhone,
          estimateData: estimateToEdit,
        );
        break;
      case 'Wallpaper':
        targetPage = Wallpaper(
          estimateId: estimateId,
          customerId: customerId,
          customerName: customerName,
          customerEmail: customerEmail,
          customerPhone: customerPhone,
          estimateData: estimateToEdit,
        );
        break;
      case 'Weinscoating':
        targetPage = WeinscoatingEstimatePage(
          estimateId: estimateId,
          customerId: customerId,
          customerName: customerName,
          customerEmail: customerEmail,
          customerPhone: customerPhone,
          estimateData: estimateToEdit,
        );
        break;
      default:
        print('⚠️ Unsupported estimate type: $estimateType');
        return;
    }

    // Step 4: Navigate
    print('📤 Navigating to $estimateType estimate page...');
    Navigator.push(
      context as BuildContext,
      MaterialPageRoute(builder: (context) => targetPage!),
    );
    }

  void _handleEditEstimate(
      BuildContext context, Map<String, dynamic> estimate) async {
    final estimateId = estimate['estimateId'];
    final customerId = estimate['customerId'];

    // Fetch customer info
    final customerInfo =
        await EstimateService.fetchCustomerInfoById(customerId);

    if (customerInfo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to load customer info")),
      );
      return;
    }

    // Extract fields for convenience
    final customerName = customerInfo['name'] ?? 'N/A';
    final customerEmail = customerInfo['email'] ?? 'N/A';
    final customerPhone = customerInfo['phone'] ?? 'N/A';

    Widget? targetPage;

    switch (estimate['estimateType']) {
      case 'Woodwork':
        targetPage = NewWoodworkEstimatePage(
          estimateId: estimateId,
          customerId: customerId,
          customerName: customerName,
          customerEmail: customerEmail,
          customerPhone: customerPhone,
          estimateData: estimate,
        );
        break;

      case 'Electrical':
        targetPage = ElectricalEstimatePage(
          estimateId: estimateId,
          customerId: customerId,
          customerName: customerName,
          customerEmail: customerEmail,
          customerPhone: customerPhone,
          estimateData: estimate,
        );
        break;

      case 'False Ceiling':
        targetPage = FalseCeilingEstimatePage(
          estimateId: estimateId,
          customerId: customerId,
          customerName: customerName,
          customerEmail: customerEmail,
          customerPhone: customerPhone,
          estimateData: estimate,
        );
        break;

      case 'Charcoal':
        targetPage = CharcoalEstimate(
          estimateId: estimateId,
          customerId: customerId,
          customerName: customerName,
          customerEmail: customerEmail,
          customerPhone: customerPhone,
          estimateData: estimate,
        );
        break;

      case 'Quartz':
        targetPage = QuartzSlabPage(
          estimateId: estimateId,
          customerId: customerId,
          customerName: customerName,
          customerEmail: customerEmail,
          customerPhone: customerPhone,
          estimateData: estimate,
        );
        break;

      case 'Granite':
        targetPage = GraniteStoneEstimate(
          estimateId: estimateId,
          customerId: customerId,
          customerName: customerName,
          customerEmail: customerEmail,
          customerPhone: customerPhone,
          estimateData: estimate,
        );
        break;

      case 'Wallpaper':
        targetPage = Wallpaper(
          estimateId: estimateId,
          customerId: customerId,
          customerName: customerName,
          customerEmail: customerEmail,
          customerPhone: customerPhone,
          estimateData: estimate,
        );
        break;

      case 'Weinscoating':
        targetPage = WeinscoatingEstimatePage(
          estimateId: estimateId,
          customerId: customerId,
          customerName: customerName,
          customerEmail: customerEmail,
          customerPhone: customerPhone,
          estimateData: estimate,
        );
        break;

      default:
        print(" Unknown estimate type: ${estimate['estimateType']}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  " Unsupported estimate type: ${estimate['estimateType']}")),
        );
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => targetPage!),
    );
  }

  Future _createNewEstimate(String type, BuildContext context) {
    // Create the customerInfo map dynamically
    Map<String, String> customerInfo = {
      'name': widget.customerName,
      'email': widget.customerEmail,
      'phone': widget.customerPhone,
    };

    switch (type) {
      case 'Woodwork':
        return Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewWoodworkEstimatePage(
              customerId: widget.customerId,
              customerName: widget.customerName,
              customerEmail: widget.customerEmail,
              customerPhone: widget.customerPhone,
              customerInfo: customerInfo, // Passing customerInfo here
            ),
          ),
        );
      case 'Electrical':
        return Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ElectricalEstimatePage(
              customerId: widget.customerId,
              customerName: widget.customerName,
              customerEmail: widget.customerEmail,
              customerPhone: widget.customerPhone,
              customerInfo: customerInfo, // Passing customerInfo here
            ),
          ),
        );
      case 'False Ceiling':
        return Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FalseCeilingEstimatePage(
              customerId: widget.customerId,
              customerName: widget.customerName,
              customerEmail: widget.customerEmail,
              customerPhone: widget.customerPhone,
              customerInfo: customerInfo, // Passing customerInfo here
            ),
          ),
        );
      case 'Charcoal':
        return Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CharcoalEstimate(
              customerId: widget.customerId,
              customerName: widget.customerName,
              customerEmail: widget.customerEmail,
              customerPhone: widget.customerPhone,
              customerInfo: customerInfo,
              estimateData: const {}, // Passing customerInfo here
            ),
          ),
        );
      case 'Quartz':
        return Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuartzSlabPage(
                customerId: widget.customerId,
                customerName: widget.customerName,
                customerEmail: widget.customerEmail,
                customerPhone: widget.customerPhone,
                customerInfo: customerInfo, // Passing customerInfo here
                estimateData: const {}),
          ),
        );
      case 'Wallpaper':
        return Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Wallpaper(
                customerId: widget.customerId,
                customerName: widget.customerName,
                customerEmail: widget.customerEmail,
                customerPhone: widget.customerPhone,
                customerInfo: customerInfo, // Passing customerInfo here
                estimateData: const {}),
          ),
        );
      case 'Weinscoating':
        print("Selected Weinscoating estimate."); // Debugging statement
        return Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WeinscoatingEstimatePage(
              customerId: widget.customerId,
              customerName: widget.customerName,
              customerEmail: widget.customerEmail,
              customerPhone: widget.customerPhone,
              customerInfo: customerInfo, // Passing customerInfo here
            ),
          ),
        );
      case 'Granite':
        return Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GraniteStoneEstimate(
                customerId: widget.customerId,
                customerName: widget.customerName,
                customerEmail: widget.customerEmail,
                customerPhone: widget.customerPhone,
                customerInfo: customerInfo, // Passing customerInfo here
                estimateData: const {}),
          ),
        );
      default:
        return Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GraniteStoneEstimate(
                customerId: widget.customerId,
                customerName: widget.customerName,
                customerEmail: widget.customerEmail,
                customerPhone: widget.customerPhone,
                customerInfo: customerInfo, // Passing customerInfo here
                estimateData: const {}),
          ),
        );
    }
  }

// Ensure you set the default version (1.1) if it's available
  void _setDefaultVersion() {
    if (groupedEstimates.containsKey(1.1)) {
      setState(() {
        selectedVersion = 1.1; // Automatically set to version 1.1 if available
      });
    } else {
      // If version 1.1 doesn't exist, you can set the default to any available version
      setState(() {
        selectedVersion = groupedEstimates.keys.isNotEmpty
            ? groupedEstimates.keys.first
            : null;
      });
    }
  }

  void _filterData() {
    setState(() {
      filteredData = estimateData
          .where((e) => e['estimateType'] == selectedEstimateType)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    List<num> sortedVersions = groupedEstimates.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Estimates'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            SidebarController.of(context)?.goBack();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printEstimates(context),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _sharePdf(context),
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Select Version:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 12),
                DropdownButton<num>(
                  value: selectedVersion,
                  hint: const Text('Choose a version'),
                  items: sortedVersions.map((version) {
                    return DropdownMenuItem<num>(
                      value: version,
                      child: Text('Ver $version - ${_getVersionDate(version)}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedVersion = value;
                    });

                    if (value != null) {
                      // Now you are passing both customerId and version as arguments
                      _loadEstimates(value.toString());
                    }
                  },
                )
              ],
            ),
            const SizedBox(height: 20),
            if (selectedVersion != null) ...[
              _buildVersionDetails(selectedVersion!),
              const SizedBox(height: 16),
              SizedBox(
                height: 600, // 👈 Set a fixed height to contain the DataTable
                child: _buildEstimateTable(selectedVersion!),
              ),
            ] else
              const SizedBox(
                height: 400,
                child: Center(
                  child: Text(
                    'Please select a version to view estimates',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

// Function to Display Version Details at the Top
  Widget _buildVersionDetails(num? version) {
    List<Map<String, dynamic>> estimates = groupedEstimates[version] ?? [];

    DateTime? versionTimestamp = estimates.isNotEmpty
        ? DateTime.tryParse(estimates.first['timestamp'] ?? '')
        : null;
    String formattedVersionTimestamp = versionTimestamp != null
        ? DateFormat('dd MMM yyyy HH:mm').format(versionTimestamp)
        : 'Unknown Date';

    final fallbackCustomerName = widget.customerName;

    String customerName = estimates.isNotEmpty
        ? estimates.first['customerName'] ?? fallbackCustomerName
        : fallbackCustomerName;

    double totalAmount = estimates.fold(
      0.0,
      (sum, estimate) => sum + (estimate['totalAmount'] ?? 0.0),
    );

    String currentStatus = estimates.first['status'] ?? 'InProgress';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer: $customerName',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          'Version Date: $formattedVersionTimestamp',
          style: const TextStyle(fontSize: 16),
        ),
        Text(
          'Total Amount: ${currencyFormatter.format(totalAmount)}',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Text(
              'Status: ',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            DropdownButton<String>(
              value: currentStatus,
              items: ['InProgress', 'Won', 'Lost', 'Hold']
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      ))
                  .toList(),
              onChanged: (String? newStatus) async {
                if (newStatus != null && newStatus != currentStatus) {
                  // Update status in backend
                  final estimateId = estimates.first['estimateId'];
                  final response = await http.put(
                    Uri.parse(
                        "http://127.0.0.1:4000/api/customer/update-status"),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'estimateId': estimateId,
                      'status': newStatus,
                    }),
                  );

                  if (response.statusCode == 200) {
                    setState(() {
                      groupedEstimates[version]![0]['status'] = newStatus;
                    });
                  } else {
                    print("Failed to update status");
                  }
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  /// ✅ Function to build the estimates table for the selected version
  /// ✅ Function to build the estimates table (Show All Types)
  /// ✅ Improved Table UI: Better Spacing, Borders, & Readability
  /// ✅ Improved Responsive Table with Dynamic Width ₹
  Widget _buildEstimateTable(num? version) {
    List<String> allEstimateTypes = [
      'Woodwork',
      'Electrical',
      'False Ceiling',
      'Charcoal',
      'Quartz',
      'Wallpaper',
      'Weinscoating',
      'Granite',
      'Grass',
      'Mosquitonet',
    ];

    List<Map<String, dynamic>> estimates = groupedEstimates[version] ?? [];

    Map<String, Map<String, dynamic>> estimatesByType = {
      for (var estimate in estimates) estimate['estimateType']: estimate
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        double columnWidth = constraints.maxWidth / 5;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            width: constraints.maxWidth,
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: DataTable(
              columnSpacing: columnWidth / 4,
              border: TableBorder.all(
                color: Colors.grey.shade300,
                width: 1.0,
                borderRadius: BorderRadius.circular(8),
              ),
              columns: const [
                DataColumn(
                    label: Text('S.NO',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('Estimate Type',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('Amount',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('Created Date',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('Actions',
                        style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: allEstimateTypes.asMap().entries.map((entry) {
                int index = entry.key;
                String type = entry.value;
                Map<String, dynamic>? estimate = estimatesByType[type];

                DateTime? estimateTimestamp = estimate != null
                    ? DateTime.tryParse(estimate['timestamp'] ?? '')
                    : null;
                String formattedEstimateTimestamp = estimateTimestamp != null
                    ? DateFormat('dd MMM yyyy HH:mm').format(estimateTimestamp)
                    : '—';

                return DataRow(
                  color: WidgetStateProperty.resolveWith<Color?>(
                      (Set<WidgetState> states) {
                    return index.isEven ? Colors.grey.shade100 : Colors.white;
                  }),
                  cells: [
                    DataCell(
                      SizedBox(
                        width: columnWidth,
                        child: Text('${index + 1}',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: columnWidth,
                        child: Text(type,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          const Icon(Icons.currency_rupee,
                              size: 16, color: Colors.green),
                          Text(
                            estimate != null
                                ? currencyFormatter
                                    .format(estimate['totalAmount'] ?? 0.0)
                                : '—',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 16, color: Colors.blue[900]),
                          const SizedBox(width: 4),
                          Text(formattedEstimateTimestamp,
                              style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          if (estimate != null)
                            IconButton(
                              icon:
                                  const Icon(Icons.edit, color: Colors.orange),
                              tooltip: 'Edit Estimate',
                              onPressed: () =>
                                  _handleEditEstimate(context, estimate),
                            ),
                          IconButton(
                            icon: const Icon(Icons.add, color: Colors.green),
                            tooltip: 'New Estimate',
                            onPressed: () => _createNewEstimate(type, context),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Future<String> getCustomerNameByCustomerId(int customerId) async {
    // final customersDb = await openCustomersDatabase(); // For customers.db

    // if (customersDb == null) {
    //   print('Error: customers database is null');
    //   return 'Unknown';
    // }

    try {
      // Query customer name from customers.db using customerId
      final response = await http.get(Uri.parse("$baseUrl/api/customers"));

      if (response.statusCode == 200) {
        final Map<String, dynamic> customer = json.decode(response.body);
        return customer['name'] ?? 'Unknown';
      } else {
        return 'Unknown';
      }
    } catch (e) {
      print('Error fetching customer name: $e');
    }

    return 'Unknown';
  }

  Future<void> loadEstimatesWithCustomerNames() async {
    List<Map<String, dynamic>> estimates =
        await fetchEstimates(); // Your method to fetch estimates

    List<Map<String, dynamic>> estimatesWithCustomerNames = await Future.wait(
      estimates.map((estimate) async {
        String customerName =
            await getCustomerNameByCustomerId(estimate['customerId']);
        return {
          ...estimate,
          'customerName': customerName,
        };
      }).toList(),
    );

    // Now you can use estimatesWithCustomerNames
    for (var estimate in estimatesWithCustomerNames) {}
  }

  // ✅ Fetch all estimates
  static Future<List<Map<String, dynamic>>> fetchEstimates() async {
    final response = await http.get(Uri.parse("$baseUrl/all-estimates"));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception("❌ Failed to fetch False Ceiling estimates.");
    }
  }

  // Function to display estimates in a table-like structure

// Function to show the detailed data based on the estimateId

  // Fetch the details for a specific estimate based on estimateId
  Future<Map<String, dynamic>> fetchEstimateDetails(int estimateId) async {
    // Assuming you have a method that fetches the specific estimate details by ID
    final estimateDetails =
        await EstimateService.getEstimateDetailsById(estimateId);
    return estimateDetails;
  }

  Future<List<Map<String, dynamic>>> fetchAllEstimatesForCustomer(
      int customerId) async {
    try {
      final allEstimates =
          await EstimateService.getAllEstimatesByCustomerId(customerId);

      if (allEstimates.isEmpty) {
        return [];
      }
      return allEstimates; // ✅ Return full estimates here
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchVersionEstimatesForCustomer(
      int customerId, String version) async {
    try {
      final uri = Uri.parse('$baseUrl/selected-estimate/$customerId');
      final response = await http.get(
        uri.replace(queryParameters: {'version': version}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        print('❌ Failed to load estimates: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching estimates: $e');
      return [];
    }
  }

  Future<void> _printEstimates(BuildContext context) async {
    final estimates = await fetchVersionEstimatesForCustomer(
      widget.customerId,
      selectedVersion.toString(),
    );

    if (estimates.isEmpty) {
      print('❌ No estimates found for version $selectedVersion');
      return;
    }

    // ✅ Debug summary estimates
    print('✅ Fetched ${estimates.length} summary estimates:');
    for (var estimate in estimates) {
      print(
          '➡️ Estimate ID: ${estimate['estimateId']} | Type: ${estimate['estimateType']} | Total: ₹${estimate['totalAmount']}');
    }

    List<Map<String, dynamic>> detailedEstimates = [];
    Set<int> seenEstimateIds = <int>{};

    for (var estimate in estimates) {
      final estimateId = estimate['estimateId'];
      final estimateType = estimate['estimateType'];

      if (seenEstimateIds.contains(estimateId)) continue;
      seenEstimateIds.add(estimateId);

      final details = await getEstimateData(estimateId, estimateType);

      // ✅ Debug detail response
      print('\n📄 Details for Estimate ID $estimateId:');
      final rows =
          (details['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      for (int i = 0; i < rows.length; i++) {
        final row = rows[i];
        print(
            '  • Row ${i + 1}: Height = ${row['height']} | Width = ${row['width']} | Desc = ${row['description']} | Amount = ₹${row['amount']}');
      }

      detailedEstimates.add({
        'estimate': estimate,
        'details': details,
      });
    }

    if (detailedEstimates.isEmpty) {
      print('⚠️ No detailed estimates available.');
      return;
    }

    // ✅ Continue to generate PDF
    Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        final pdfBytes = await generatePdfForVersion(
          estimates,
          selectedVersion,
          detailedEstimates,
        );
        return pdfBytes;
      },
    );
  }

  Future<Uint8List> generatePdfForVersion(
    List<Map<String, dynamic>> estimates,
    num? selectedVersion,
    List<Map<String, dynamic>> detailedEstimates,
  ) async {
    final pdf = pw.Document();

    final logoBytes =
        (await rootBundle.load('assets/Black logo on White-01.jpg'))
            .buffer
            .asUint8List();
    final pw.MemoryImage logo = pw.MemoryImage(logoBytes);

    final formattedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
    final image = await imageFromAssetBundle('assets/images/decor.png');
    final headerImage1 =
        await imageFromAssetBundle('assets/images/header1.png');
    final headerImage2 =
        await imageFromAssetBundle('assets/images/header2.png');
    final missionIcon = pw.MemoryImage(
        (await rootBundle.load('assets/images/iconMission.png'))
            .buffer
            .asUint8List());
    final visionIcon = pw.MemoryImage(
        (await rootBundle.load('assets/images/iconVision.png'))
            .buffer
            .asUint8List());
    final coreIcon = pw.MemoryImage(
        (await rootBundle.load('assets/images/iconCore.png'))
            .buffer
            .asUint8List());
    final triangle = pw.MemoryImage(
        (await rootBundle.load('assets/images/iconTriangle.png'))
            .buffer
            .asUint8List());
    final object = await imageFromAssetBundle('assets/images/OBJECTS.png');
    final logoByte = await rootBundle.load('assets/images/101.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    // Assuming customer info from widget
    String customerName = widget.customerName; // From widget
    String customerEmail = widget.customerEmail; // From widget
    String customerPhone = widget.customerPhone; // From widget

    if (estimates.isEmpty) {
      return Uint8List(0);
    }

    final double grandTotal = estimates.fold(
      0.0,
      (sum, estimate) => sum + (estimate['totalAmount'] ?? 0.0),
    );

    // Calculate payment stages
    final bookingAdvance = grandTotal * 0.10;
    final designSignoff = grandTotal * 0.15;
    final completionOnSite = grandTotal * 0.40;
    final finalHandover = grandTotal * 0.35;
    // Group detailed estimates by room
    final Map<String, List<Map<String, dynamic>>> groupedByRoom = {};

    for (var estimate in detailedEstimates) {
      final type =
          estimate['estimate']?['estimateType']?.toString().toLowerCase() ?? '';

      print('🔍 Type: $type');
      print('🧾 Details: ${estimate['details']}');

      if (type == 'woodwork_estimate' || type == 'woodwork') {
        final rawDetails = estimate['details'];

        // Handle both fast API format and wrapped 'data' format
        final List<Map<String, dynamic>> rows = (rawDetails is List)
            ? rawDetails.whereType<Map<String, dynamic>>().toList()
            : (rawDetails is Map && rawDetails['details'] is List)
                ? (rawDetails['details'] as List)
                    .whereType<Map<String, dynamic>>()
                    .toList()
                : [];

        for (var row in rows) {
          final room = row['room']?.toString() ?? 'Unknown';
          groupedByRoom.putIfAbsent(room, () => []).add(row);
        }
      }
    }

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) {
          return [
            // Header Section from old code
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Image(headerImage1, height: 60),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Image(logo, height: 50),
                    pw.SizedBox(height: 8),
                    pw.Text(
                        'Address: Sri Sowdeswari Nagar, Chennai, Tamil Nadu 600097',
                        style: const pw.TextStyle(fontSize: 8)),
                    pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Email: info@anbre.in',
                              style: const pw.TextStyle(fontSize: 8)),
                          pw.SizedBox(width: 20),
                          pw.Text('Phone No.: 9884488892',
                              style: const pw.TextStyle(fontSize: 8)),
                        ]),
                    pw.SizedBox(height: 10),
                  ],
                ),
                pw.Image(headerImage2, height: 60),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(),

            // Customer Info Section from old code
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300)),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Quote ID: 15247"),
                      pw.Text("Date: $formattedDate"),
                      pw.Text("Client name: $customerName"),
                      pw.Text("Phone: $customerPhone"),
                      pw.Text("Company: Anbre Interiors"),
                    ],
                  ),
                  pw.Text("Quotation",
                      style: pw.TextStyle(
                          fontSize: 20, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),

            pw.SizedBox(height: 10),

            // Dear Sir Content (from old code)
            pw.Text('Dear Sir,'),
            pw.Text(
                'We sincerely thank you for the opportunity to present our quotation and greatly value your consideration.',
                style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 30),

            // Steps Section (from old code)
            pw.Center(
              child: pw.Text(
                'Dream home interiors made easy',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.orange50,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("1. Meet our consultants",
                      style: const pw.TextStyle(fontSize: 8)),
                  pw.Image(triangle, height: 5),
                  pw.Text("2. Book your quote",
                      style: const pw.TextStyle(fontSize: 8)),
                  pw.Image(triangle, height: 5),
                  pw.Text("3. Production",
                      style: const pw.TextStyle(fontSize: 8)),
                  pw.Image(triangle, height: 5),
                  pw.Text("4. Site Execution",
                      style: const pw.TextStyle(fontSize: 8)),
                  pw.Image(triangle, height: 5),
                  pw.Text("5. Handover",
                      style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
            ),
            pw.SizedBox(height: 30),
            pw.Container(
              //width: 150,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.orange),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildBox(
                      'Mission',
                      'To inspire and empower our clients to create dream homes by offering innovative design solutions, superior quality, and commitment to excellence.',
                      missionIcon),
                  _buildBox(
                      'Vision',
                      'To transform residential interiors using technology and design, while creating stunning and unique interiors, and setting new standards for quality and transparency in the industry.',
                      visionIcon),
                  _buildBox(
                      'Core Values',
                      'Quality, Innovation, Integrity & Transparency, Customer obsession, Results, Stakeholder excellence, Values-oriented, Empowerment',
                      coreIcon),
                ],
              ),
            ),
            pw.SizedBox(height: 30),
            pw.Center(
              child: pw.Column(children: [
                pw.Text("Ready to design your dream space?",
                    style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 10),
                pw.Text("Anbre interior is here!",
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Image(image, height: 150),
              ]),
            ),

            pw.SizedBox(height: 30),

            // Estimate Summary Table (from new code)
            pw.Text('Estimate Summary',
                style:
                    pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(children: [
                  pw.Text('S.No.',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Estimate Type',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Amount',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ]),
                ...estimates.map((estimate) {
                  return pw.TableRow(children: [
                    pw.Text('${estimate['estimateId']}'),
                    pw.Text(estimate['estimateType'] ?? 'Unknown'),
                    pw.Text('${estimate['totalAmount']}'),
                  ]);
                }),
              ],
            ),
            pw.SizedBox(height: 20),

            // Detailed Estimates (from new code)
            pw.Text('Detailed Estimates',
                style: const pw.TextStyle(fontSize: 18)),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
                4: const pw.FlexColumnWidth(2),
                5: const pw.FlexColumnWidth(2),
                6: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _cell('Room', bold: true),
                    _cell('Width (ft)', bold: true),
                    _cell('Height (ft)', bold: true),
                    _cell('Length (ft)', bold: true),
                    _cell('Sq. Feet', bold: true),
                    _cell('Qty', bold: true),
                    _cell('Amount (₹)', bold: true),
                  ],
                ),
                ...() {
                  List<pw.TableRow> allRows = [];
                  groupedByRoom.forEach((roomName, rows) {
                    final totalAmount = rows.fold<double>(
                      0.0,
                      (sum, row) =>
                          sum +
                          (double.tryParse(row['amount1']?.toString() ??
                                  row['amount']?.toString() ??
                                  '0') ??
                              0.0),
                    );

                    for (int i = 0; i < rows.length; i++) {
                      final row = rows[i];

                      final width = _toFeet(
                          row['width'], row['widthFeet'], row['widthMM']);
                      final height = _toFeet(
                          row['height'], row['heightFeet'], row['heightMM']);
                      final length = _toFeet(
                          row['length'], row['lengthFeet'], row['lengthMM']);
                      final quantity =
                          double.tryParse(row['quantity']?.toString() ?? '1') ??
                              1;

                      final sqFeet = (width > 0 && height > 0)
                          ? width * height
                          : (length > 0 && height > 0)
                              ? length * height
                              : 0.0;

                      allRows.add(
                        pw.TableRow(
                          children: [
                            _cell(roomName),
                            _cell(width > 0 ? width.toStringAsFixed(2) : '—'),
                            _cell(height > 0 ? height.toStringAsFixed(2) : '—'),
                            _cell(length > 0 ? length.toStringAsFixed(2) : '—'),
                            _cell(sqFeet > 0 ? sqFeet.toStringAsFixed(2) : '—'),
                            _cell(quantity.toStringAsFixed(0)),
                            _cell(i == 0
                                ? '₹ ${totalAmount.toStringAsFixed(2)}'
                                : ''),
                          ],
                        ),
                      );
                    }
                  });
                  return allRows;
                }(),
              ],
            ),

            pw.SizedBox(height: 20),

            // ✅ Other Estimate Types - Separate Tables
            ...detailedEstimates.map((estimate) {
              final type = estimate['estimate']?['estimateType']
                      ?.toString()
                      .toLowerCase() ??
                  '';
              if (type == 'woodwork' || type == 'woodwork_estimate') {
                return pw.SizedBox();
              }

              final rawDetails = estimate['details'];
              final List<Map<String, dynamic>> rows = (rawDetails is List)
                  ? rawDetails.whereType<Map<String, dynamic>>().toList()
                  : (rawDetails is Map && rawDetails['details'] is List)
                      ? (rawDetails['details'] as List)
                          .whereType<Map<String, dynamic>>()
                          .toList()
                      : [];

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                      '${type.replaceAll("_estimate", "").toUpperCase()} Estimate Details',
                      style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  pw.Table(
                    border: pw.TableBorder.all(),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(1),
                      1: const pw.FlexColumnWidth(4),
                      2: const pw.FlexColumnWidth(2),
                      3: const pw.FlexColumnWidth(3),
                    },
                    children: [
                      pw.TableRow(
                        decoration:
                            const pw.BoxDecoration(color: PdfColors.grey300),
                        children: [
                          _cell('S.No', bold: true),
                          _cell('Description', bold: true),
                          _cell('Qty', bold: true),
                          _cell('Amount (₹)', bold: true),
                        ],
                      ),
                      ...rows.asMap().entries.map((entry) {
                        final index = entry.key;
                        final row = entry.value;

                        final desc = row['description']?.toString() ??
                            row['selectedUnit']?.toString() ??
                            row['model']?.toString() ??
                            '—';

                        final qty = double.tryParse(
                                row['quantity']?.toString() ??
                                    row['qty']?.toString() ??
                                    '1') ??
                            1;

                        final amt = double.tryParse(row['amount']?.toString() ??
                                row['amount1']?.toString() ??
                                row['totalAmount']?.toString() ??
                                row['total']?.toString() ??
                                '0') ??
                            0;

                        return pw.TableRow(
                          children: [
                            _cell('${index + 1}'),
                            _cell(desc),
                            _cell(qty.toStringAsFixed(0)),
                            _cell(
                                amt > 0 ? '₹ ${amt.toStringAsFixed(2)}' : '—'),
                          ],
                        );
                      }),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                ],
              );
            }),

            pw.Container(
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.white)),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Image (optional)
                  pw.Expanded(
                    flex: 1,
                    child: pw.Image(
                      object,
                      height: 100,
                    ),
                  ),
                  pw.SizedBox(width: 30),
                  // Payment steps
                  pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        _buildPaymentStep(
                            "✓", "10% Advance for order confirmation"),
                        _buildPaymentStep(
                            "📐", "40% for finalization of designs"),
                        _buildPaymentStep(
                            "🚚", "50% On Delivery of carcass materials"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // Payment Table (added)
            pw.Text("Payment Stages",
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text("Stage")),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text("Amount")),
                  ],
                ),
                _paymentRow("Booking advance (10%)",
                    currencyFormatter.format(bookingAdvance)),
                _paymentRow("Design Signoff (15%)",
                    currencyFormatter.format(designSignoff)),
                _paymentRow("50% completion on site (40%)",
                    currencyFormatter.format(completionOnSite)),
                _paymentRow("Final 35% handover",
                    currencyFormatter.format(finalHandover)),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                "Total Quote Value: ₹ ${grandTotal.toStringAsFixed(2)}",
                style:
                    pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 20),

            // General Specifications (added part)
            pw.Text('General Specifications',
                style:
                    pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text("Warranty", style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 2),
            _pwBullet("i",
                "Enjoy Absolute Peace of Mind with our comprehensive warranty"),
            _pwBullet("ii", "All woodwork is covered by a 10-year warranty."),
            _pwBullet("iii",
                "All accessories, hardware, appliances etc. procured from OEMs are covered as per the respective Manufacturer’s Warranty Policy"),

            pw.SizedBox(height: 8),
            pw.Text("Wood Specification",
                style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 2),
            _pwBullet("i",
                "Anbre plywood are sourced from leading manufacturers, fully compliant with ISI standards, guaranteeing adherence to industry benchmarks and exceptional quality."),
            _pwBullet("ii",
                "All wood used in kitchen boxes and shutters are IS710 BWP (Boiling Water Proof)."),
            _pwBullet("iii",
                "For other applications (rest of the house), IS303 BWR (Boiling Water Resistant) hardwood plywood is used."),
            _pwBullet("iv",
                "The plywood is ISO-certified, termite and borer-treated, and comes with an ISI-certified manufacturer's guarantee, which will be passed on to clients."),
            _pwBullet("v",
                "WPC panels are used for Sink, Vanity and other extreme water prone areas."),
            _pwBullet("vi",
                "WPC panels used are IS 2380, 1734, 1659 compliant, Lead Free, Fire retardant, water proof and termite proof."),

            pw.SizedBox(height: 8),
            pw.Text("Panel Thickness", style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 2),
            _pwBullet("i",
                "Standard panel thickness is 18mm*. Panels are laminated plywood planks used for boxes and shutters."),
            _pwBullet("ii",
                "Plywood thickness is 16mm*, with the laminate and glue contributing an additional 2mm."),
            _pwBullet("iii", "*Thickness variation of ±1mm is permissible."),
            _pwBullet("iv", "Panel fixed amount"),

            pw.SizedBox(height: 8),
            pw.Text("Ledges & Tabletops",
                style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 2),
            _pwBullet("i",
                "Panel Thickness used varies between 18mm, 19mm, 22mm, 25mm and 36mm based on design."),

            pw.SizedBox(height: 8),
            pw.Text("Edge Band", style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 2),
            _pwBullet("i",
                "Edge band thickness used would be .5mm, .7mm, 1.3mm (Glossy), 2mm."),
            _pwBullet(
                "ii", "Thickness would be chosen as per desired application."),

            pw.SizedBox(height: 8),
            pw.Text("Carcass Finish", style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 2),
            _pwBullet("i",
                "All carcasses (boxes) come with 0.7mm off-white liner laminates as default colour."),
            _pwBullet("ii",
                "Other liner laminates are available at an additional cost."),

            pw.SizedBox(height: 8),
            pw.Text("Abbreviations", style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 2),
            _pwBullet("i", "B - box, F&S - Frame and Shutter, SP - Panels"),

            pw.SizedBox(height: 8),
            pw.Text("Shutter & Shutter Core Material",
                style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 2),
            _pwBullet("i",
                "For glossy finishes (PU, Duco, Acrylic) - shutters are made using HDHMR (High-Density, High-Moisture Resistant) boards of Tesa or equivalent brand."),
            _pwBullet("ii",
                "For laminated sliding doors (matte finish), block boards conforming to IS303 standards and treated for termite and borer resistance are used."),

            pw.SizedBox(height: 8),
            pw.Text("Wardrobe Specification",
                style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 2),
            _pwBullet("i",
                "Default wardrobe pricing includes one wooden draw per door of 150mm height."),
            _pwBullet("ii",
                "Additional drawers or accessories will be quoted separately."),
            _pwBullet("ii",
                "Kitchen and other accessories are also quoted separately."),

            pw.SizedBox(height: 8),
            pw.Text("Hardware & Fittings",
                style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 2),
            _pwBullet("i", "All hardware is of EBCO make."),
            pw.SizedBox(height: 15),

            // Terms and Conditions (added part)
            pw.Text('Terms and Conditions',
                style:
                    pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            _pwBullet("1",
                "Plumbing, electrical modification, decorative light fittings, gas piping, sink, taps, core cutting, civil changes, painting, and installation charges for appliances are not considered in the quote. These items are quoted separately if needed."),
            _pwBullet("2",
                "Only the wood work component and specified kitchen accessories are part of the preliminary scope unless specifically mentioned otherwise."),
            _pwBullet("3",
                "3D/Photos are for design representation only. Other than wood work, if they are to be accounted for in the scope, a separate line item has to be explicitly stated with appropriate estimates."),
            _pwBullet("4",
                "Electricity for work should be provided and cost to be borne by the client."),
            _pwBullet("5", "Order, once placed, will not be cancelled."),
            _pwBullet("6",
                "Customers are advised to do the painting touch-up only after all the interior works are completed."),
            _pwBullet("7",
                "Standard timeline for delivery of material is 45 working days and 15 working days for installation."),
            _pwBullet("8",
                "Timeline is subject to change in case of any natural calamities, political unrest, or power supply failure (both at factory and site) and any delay in payments."),

            pw.SizedBox(height: 10),
          ];
        },
      ),
    );

    // Return the generated PDF after all estimates processed
    return pdf.save();
  }

// Helper to convert any unit to feet
  double _toFeet(dynamic raw, dynamic feet, dynamic mm) {
    if (feet != null) return double.tryParse(feet.toString()) ?? 0.0;
    if (mm != null) return (double.tryParse(mm.toString()) ?? 0.0) / 304.8;
    return double.tryParse(raw?.toString() ?? '0') ?? 0.0;
  }

// Helper for styled cell
  pw.Widget _cell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _buildPaymentStep(String icon, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.Text(icon, style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(width: 5),
          pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  pw.Widget _buildBox(
      String title, String description, pw.ImageProvider image) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.white),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Image(image, height: 6),
          pw.SizedBox(height: 4),
          pw.Text(title,
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: PdfColors.orange)),
          pw.SizedBox(height: 4),
          pw.Text(description, style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  pw.TableRow _paymentRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(label)),
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(value)),
      ],
    );
  }

  pw.Widget _pwBullet(String number, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 20,
            child: pw.Text("$number.", style: const pw.TextStyle(fontSize: 10)),
          ),
          pw.Expanded(
            child: pw.Text(
              text,
              style: const pw.TextStyle(fontSize: 10),
              textAlign: pw.TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _tableHeaderCell(String text,
      {PdfColor color = PdfColors.black, bool alignRight = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      alignment:
          alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  pw.Widget _tableCell(String text, {bool alignRight = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      alignment:
          alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }

  Future<Map<String, dynamic>> getEstimateData(
      int estimateId, String estimateType) async {
    final uri = Uri.parse(
        '$baseUrl/estimate-details?estimateId=$estimateId&estimateType=$estimateType');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      // Ensure 'details' is a list
      if (data.containsKey('details') && data['details'] is List) {
        data['details'] =
            List<Map<String, dynamic>>.from(data['details'] ?? []);
      } else {
        data['details'] = <Map<String, dynamic>>[];
      }

      return data;
    } else {
      throw Exception(
          'Failed to fetch estimate details: ${response.statusCode}');
    }
  }

// Define the fields to be displayed for each estimate type
  final Map<String, List<String>> estimateFields = {
    'granite': [
      'estimateId',
      'description',
      'length',
      'width',
      'amount',
      'version',
      'totalAmount'
    ], // Fields for Granite
    'woodwork': [
      'customerName',
      'estimateId',
      'selectedUnit',
      'amount1',
      'version',
    ], // Fields for Woodwork
    'charcoal': [
      'description',
      'length',
      'height',
      'totalAmount',
      'estimateType',
      'version'
    ], // Fields for Charcoal
    'quartz': [
      'estimateId',
      'description',
      'length',
      'width',
      'amount',
      'version',
      'totalAmount'
    ], // Fields for Quartz
    'wallpaper': [
      'description',
      'length',
      'height',
      'quantity',
      'amount',
      'version',
      'timestamp',
      'totalAmount'
    ], // Fields for Wallpaper
    'weinscoating': [
      'description',
      'labour',
      'rate',
      'totalAmount',
      'estimateType',
      'version'
    ], // Fields for Weinscoating
  };

// PDF Generation with selective fields for each estimate type
  Future<Uint8List> generatePdf(List<Map<String, dynamic>> estimates) async {
    final pdf = pw.Document();

    // Load the logo image
    final Uint8List logoBytes =
        (await rootBundle.load('assets/Black logo on White-01.jpg'))
            .buffer
            .asUint8List();
    final pw.MemoryImage logo = pw.MemoryImage(logoBytes);

    // Assuming you have customer information available
    String customerName = widget.customerName; // From widget
    String customerEmail = widget.customerEmail; // From widget
    String customerPhone = widget.customerPhone; // From widget

    // Add a page to the PDF
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Customer Info Section
              pw.Text('Customer Info:',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('Name: $customerName'),
              pw.Text('Email: $customerEmail'),
              pw.Text('Phone: $customerPhone'),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 8),

              // Logo and Date
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Image(logo, width: 50, height: 50),
                  pw.Text(
                    'Generated on: ${DateFormat('dd-MM-yyyy').format(DateTime.now())}',
                    style:
                        const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                  ),
                ],
              ),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 8),

              // Title for Overall Estimate Types Section
              pw.Text('Overall Estimate Types and Amounts',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),

              // Summary Table
              pw.Table(
                border:
                    pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.blueGrey800),
                    children: [
                      _tableHeaderCell("S.No.", color: PdfColors.white),
                      _tableHeaderCell("Estimate Type", color: PdfColors.white),
                      _tableHeaderCell("Amount (₹)",
                          color: PdfColors.white, alignRight: true),
                    ],
                  ),
                  ...estimates.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final estimate = entry.value;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: index % 2 == 0
                            ? PdfColors.white
                            : PdfColors.grey100,
                      ),
                      children: [
                        _tableCell('$index'),
                        _tableCell(estimate['estimateType'] ?? 'Unknown'),
                        _tableCell('${estimate['totalAmount'] ?? 0}'),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 20),

              // Detailed Estimates Title
              pw.Text('Detailed Estimates',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),

              // Each Estimate Type Details
              ...estimates.map((estimate) {
                final estimateType = estimate['estimateType'] ?? 'Unknown';
                final fields = estimateFields[estimateType.toLowerCase()] ?? [];

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(estimateType,
                        style: pw.TextStyle(
                            fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 6),
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.grey300),
                      columnWidths: {
                        for (var i = 0; i <= fields.length; i++)
                          i: const pw.FlexColumnWidth(2),
                      },
                      children: [
                        // Header
                        pw.TableRow(
                          decoration:
                              const pw.BoxDecoration(color: PdfColors.grey200),
                          children: [
                            _tableHeaderCell("S.No."),
                            ...fields.map((f) => _tableHeaderCell(f)),
                          ],
                        ),
                        // Data Row
                        pw.TableRow(
                          decoration:
                              const pw.BoxDecoration(color: PdfColors.amber50),
                          children: [
                            _tableCell("1"), // Static S.No. for now
                            ...fields.map((field) {
                              var value = estimate[field];
                              if (value is List) {
                                value = value.join(', ');
                              } else if (value is Map) {
                                value = value.entries
                                    .map((e) => '${e.key}: ${e.value}')
                                    .join(', ');
                              }
                              return _tableCell(value?.toString() ?? '');
                            }),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 20),
                  ],
                );
              }),
            ],
          );
        },
      ),
    );

    // Return the generated PDF bytes
    return Uint8List.fromList(await pdf.save());
  }

  // Share PDF function
  Future<void> _sharePdf(BuildContext context) async {
    final estimates = await fetchAllEstimatesForCustomer(widget.customerId);
    final pdfFile = await generatePdf(estimates);
    await Printing.sharePdf(bytes: pdfFile, filename: 'customer_estimates.pdf');
  }

  String _getVersionDate(num version) {
    var estimates = groupedEstimates[version] ?? [];
    if (estimates.isEmpty) return 'Unknown Date';

    var timestamp = estimates.first['timestamp'];
    var date = DateTime.tryParse(timestamp ?? '');
    return date != null
        ? DateFormat('dd-MM-yyyy').format(date)
        : 'Unknown Date';
  }
}
