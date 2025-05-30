import 'package:erp_tool/modules/estimate/pages/wallpaper.dart';
import 'package:erp_tool/modules/estimate/pages/weinscoating_estimate.dart';
import 'package:flutter/material.dart';
import '../../../database/wc_database_helper.dart';
import '../../../services/customer_database_service.dart';
import 'Quartz_Slab_Page.dart';
import 'charcoal_estimate.dart';
import 'electrical_estimate_page.dart';
import 'estimate_list_page.dart';
import 'false_ceiling_estimate_page.dart';
import 'granite_stone_estimate.dart';
import 'new_woodwork_estimate_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:js_interop';
import 'package:excel/excel.dart';

@JS('URL')
external JSURL get jsURL;

@JS()
@staticInterop
class JSURL {}

extension JSURLBindings on JSURL {
  external String createObjectURL(Blob blob);
  external void revokeObjectURL(String url);
}

@JS('Blob')
@staticInterop
class Blob {
  external factory Blob(JSArray parts);
}

@JS('Array')
@staticInterop
class JSArray {
  external factory JSArray();
}

extension JSArrayExtension on JSArray {
  external void push(JSAny? value);
}

@JS('document')
external JSDocument get document;

@JS()
@staticInterop
class JSDocument {}

extension JSDocumentExtension on JSDocument {
  external JSAnchorElement createElement(String tag);
}

@JS()
@staticInterop
class JSAnchorElement {}

extension JSAnchorElementExtension on JSAnchorElement {
  external set href(String value);
  external set download(String value);
  external void click();
}

class WeinscoatingEstimateDetailPage extends StatefulWidget {
  final int estimateId;

  const WeinscoatingEstimateDetailPage({super.key, required this.estimateId});

  @override
  _WeinscoatingEstimateDetailPageState createState() =>
      _WeinscoatingEstimateDetailPageState();
}

class _WeinscoatingEstimateDetailPageState
    extends State<WeinscoatingEstimateDetailPage> {
  final List<Map<String, dynamic>> _customers = [];
  Map<String, dynamic>? _selectedCustomer;
  bool _isSidebarExpanded = true;
  Map<String, dynamic>? _estimateData;
  List<dynamic> _estimateRows = [];

  // Fetching customers from the database
  Future<void> _fetchCustomers() async {
    final dbService = CustomerDatabaseService();
    final response = await dbService.fetchCustomers();
    setState(() {
      _customers.clear();
      _customers.addAll(response['customers']);
    });
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchCustomers(); // Load customers when the page loads
  }

// Export Excel File
  void _downloadExcelWeb(Uint8List bytes, String fileName) {
    final array = JSArray();
    array.push(bytes.toJS);
    final blob = Blob(array);
    final url = jsURL.createObjectURL(blob);

    final anchor = document.createElement('a');
    anchor.href = url;
    anchor.download = fileName;
    anchor.click();

    jsURL.revokeObjectURL(url);
  }

  void _exportToExcel(Map<String, dynamic> estimate, List<dynamic> rows) {
    final excel = Excel.createExcel();
    final sheet = excel['Weinscoating Estimate'];

    sheet.appendRow([TextCellValue('Weinscoating Estimate')]);
    sheet.appendRow([]);
    sheet.appendRow([TextCellValue('Customer Info')]);
    sheet.appendRow([
      TextCellValue('Name'),
      TextCellValue(estimate['customerName'] ?? 'N/A')
    ]);
    sheet.appendRow([
      TextCellValue('Email'),
      TextCellValue(estimate['customerEmail'] ?? 'N/A')
    ]);
    sheet.appendRow([
      TextCellValue('Phone'),
      TextCellValue(estimate['customerPhone'] ?? 'N/A')
    ]);

    sheet.appendRow([]);
    sheet.appendRow([TextCellValue('Estimate Info')]);
    sheet.appendRow(
        [TextCellValue('Estimate ID'), TextCellValue('${estimate['id']}')]);
    sheet.appendRow(
        [TextCellValue('GST'), TextCellValue('${estimate['gst'] ?? 0}')]);
    sheet.appendRow([
      TextCellValue('Transport'),
      TextCellValue('${estimate['transportCharges'] ?? 0}')
    ]);
    sheet.appendRow([
      TextCellValue('Total Amount'),
      TextCellValue('${estimate['totalAmount'] ?? 0}')
    ]);

    sheet.appendRow([]);
    const headers = [
      'Description',
      'Length (mm)',
      'Width (mm)',
      'Area (sq.ft)',
      'Panel',
      'Rate',
      'Laying',
      'Labour',
      'Amount'
    ];
    sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());

    for (final row in rows) {
      sheet.appendRow([
        TextCellValue('${row['description'] ?? ''}'),
        TextCellValue('${row['length'] ?? ''}'),
        TextCellValue('${row['width'] ?? ''}'),
        TextCellValue('${row['area'] ?? ''}'),
        TextCellValue('${row['panel'] ?? ''}'),
        TextCellValue('${row['rate'] ?? ''}'),
        TextCellValue('${row['laying'] ?? ''}'),
        TextCellValue('${row['labour'] ?? ''}'),
        TextCellValue('${row['amount'] ?? ''}'),
      ]);
    }

    final customer = (estimate['customerName'] ?? 'Customer')
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(' ', '_');
    final fileName = 'WeinscoatingEstimate_${customer}_${estimate['id']}.xlsx';

    final bytes = excel.encode();
    if (bytes != null) {
      _downloadExcelWeb(Uint8List.fromList(bytes), fileName);
    }
  }

  //End
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weinscoating Estimate Details'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export to Excel',
            onPressed: () {
              if (_estimateData != null && _estimateRows.isNotEmpty) {
                _exportToExcel(_estimateData!, _estimateRows);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('❌ No estimate data available to export')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () async {
              try {
                final estimate =
                    await WcDatabaseHelper.getWeinscoatingEstimateById(
                        widget.estimateId);
                _navigateToEditWallpaper(context, estimate);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            tooltip: 'Edit Estimate',
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar with Estimate Type options
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isSidebarExpanded ? 260 : 80, // Expands or collapses
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.blue.shade900,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(0),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Toggle Button
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(
                      _isSidebarExpanded
                          ? Icons.chevron_left
                          : Icons.chevron_right,
                      color: Colors.white,
                    ),
                    onPressed: _toggleSidebar,
                  ),
                ),
                if (_isSidebarExpanded) // Show title only if expanded
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      'Estimate Types',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                // Estimate Type Buttons (Responsive)
                _buildEstimateWidget(
                    context, 'Woodwork', Icons.build, Colors.white),
                _buildEstimateWidget(context, 'Electrical',
                    Icons.electrical_services, Colors.white),
                _buildEstimateWidget(context, 'False Ceiling',
                    Icons.home_repair_service, Colors.white),
                _buildEstimateWidget(context, 'Wallpaper Estimate',
                    Icons.wallpaper, Colors.white),
                _buildEstimateWidget(
                    context, 'Charcoal Estimate', Icons.widgets, Colors.white),
                _buildEstimateWidget(context, 'Quartz Slab Estimate',
                    Icons.kitchen, Colors.white),
                _buildEstimateWidget(
                    context, 'Granite Estimate', Icons.ac_unit, Colors.white),
                _buildEstimateWidget(context, 'Wainscoting Estimate',
                    Icons.format_paint, Colors.white),
              ],
            ),
          ),

          // Main area with Estimate Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 6, // Higher shadow for premium feel
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.9),
                        Colors.white.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: FutureBuilder<Map<String, dynamic>>(
                      future: WcDatabaseHelper.getWeinscoatingEstimateById(
                          widget.estimateId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Center(child: Text('No data found.'));
                        } else {
                          _estimateData = snapshot.data!['estimate'];
                          _estimateRows = snapshot.data!['rows'];
                          final estimate = _estimateData!;
                          final rows = _estimateRows;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Estimate Details:',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 20),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text('Description')),
                                    DataColumn(label: Text('Length (mm)')),
                                    DataColumn(label: Text('Width (mm)')),
                                    DataColumn(label: Text('Area (sq.ft)')),
                                    DataColumn(label: Text('Panel')),
                                    DataColumn(label: Text('Rate')),
                                    DataColumn(label: Text('Laying')),
                                    DataColumn(label: Text('Labour')),
                                    DataColumn(label: Text('Amount')),
                                  ],
                                  rows: rows.map<DataRow>((row) {
                                    return DataRow(cells: [
                                      DataCell(Text(
                                          '${row['description'] ?? 'N/A'}')),
                                      DataCell(
                                          Text('${row['length'] ?? 0} mm')),
                                      DataCell(Text('${row['width'] ?? 0} mm')),
                                      DataCell(
                                          Text('${row['area'] ?? 0} sq.ft')),
                                      DataCell(
                                          Text('${row['panel'] ?? 'N/A'}')),
                                      DataCell(Text('₹${row['rate'] ?? 0}')),
                                      DataCell(Text('₹${row['laying'] ?? 0}')),
                                      DataCell(Text('${row['labour'] ?? 0}')),
                                      DataCell(Text('₹${row['amount'] ?? 0}')),
                                    ]);
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Transport Charges: ₹${estimate['transportCharges'] ?? 'N/A'}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                'GST: ₹${estimate['gst'] ?? 'N/A'}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                'Grand Total: ₹${estimate['totalAmount'] ?? 'N/A'}',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () =>
                                    _deleteEstimate(context, estimate['id']),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                ),
                                child: const Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Text(
                                    'Delete Estimate',
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEstimate(BuildContext context, int estimateId) async {
    await WcDatabaseHelper.DeleteEstimateById(estimateId);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Estimate deleted successfully!')),
    );
  }

  void _navigateToEditWallpaper(
      BuildContext context, Map<String, dynamic> estimateResponse) async {
    try {
      final mainEstimate = estimateResponse['estimate'] ?? {};
      final rows =
          List<Map<String, dynamic>>.from(estimateResponse['rows'] ?? []);
      final customerId = mainEstimate['customerId'] as int?;
      final estimateId = mainEstimate['id'] as int?;

      if (customerId == null || estimateId == null) {
        throw Exception('Invalid data: customerId or estimateId is null.');
      }

      // Fetch customer info from the API
      final customerInfo = await fetchCustomerById(customerId);

      if (customerInfo == null) {
        throw Exception('Customer data not found for ID: $customerId');
      }

      print(
          '✅ Navigating to edit weinscoating with: customerId=$customerId, estimateId=$estimateId');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WeinscoatingEstimatePage(
            customerId: customerId,
            estimateId: estimateId,
            customerInfo: {
              'name': customerInfo['name'] ?? 'Unknown',
              'email': customerInfo['email'] ?? 'No Email',
              'phone': customerInfo['phone'] ?? 'No Phone',
            },
            customerName: customerInfo['name'] ?? 'Unknown',
            customerEmail: customerInfo['email'] ?? 'No Email',
            customerPhone: customerInfo['phone'] ?? 'No Phone',
            estimateData: {
              'estimate': mainEstimate,
              'rows': rows,
            },
          ),
        ),
      );
    } catch (e) {
      print('❌ Error fetching customer info: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching customer info: $e')),
      );
    }
  }

  Future<Map<String, dynamic>?> fetchCustomerById(int customerId) async {
    final String apiUrl = 'http://127.0.0.1:4000/api/customers/$customerId';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        print('❌ Error: Customer not found.');
        return null;
      } else {
        print('❌ Error fetching customer: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Exception occurred: $e');
      return null;
    }
  }

  void _navigateToEstimateType(BuildContext context, String estimateType) {
    if (_selectedCustomer != null) {
      Widget page;
      switch (estimateType) {
        case 'Woodwork':
          page = NewWoodworkEstimatePage(
            customerId: _selectedCustomer!['id'],
            customerName: _selectedCustomer!['name'],
            customerEmail: _selectedCustomer!['email'],
            customerPhone: _selectedCustomer!['phone'],
          );
          break;
        case 'Electrical':
          page = ElectricalEstimatePage(
            customerId: _selectedCustomer!['id'],
            customerInfo: {
              'name': _selectedCustomer!['name'],
              'email': _selectedCustomer!['email'],
              'phone': _selectedCustomer!['phone'],
            },
            customerName: '',
            customerEmail: '',
            customerPhone: '',
          );
          break;
        case 'False Ceiling':
          page = FalseCeilingEstimatePage(
            customerId: _selectedCustomer!['id'],
            customerInfo: {
              'name': _selectedCustomer!['name'],
              'email': _selectedCustomer!['email'],
              'phone': _selectedCustomer!['phone'],
            },
            customerName: '',
            customerEmail: '',
            customerPhone: '',
          );
          break;
        case 'Charcoal Estimate':
          page = CharcoalEstimate(
            customerId: _selectedCustomer!['id'],
            customerInfo: {
              'name': _selectedCustomer!['name'],
              'email': _selectedCustomer!['email'],
              'phone': _selectedCustomer!['phone'],
            },
            customerName: '',
            customerEmail: '',
            customerPhone: '',
            estimateData: const {},
          );
          break;
        case 'Quartz Slab Estimate':
          page = QuartzSlabPage(
            customerId: _selectedCustomer!['id'],
            customerInfo: {
              'name': _selectedCustomer!['name'],
              'email': _selectedCustomer!['email'],
              'phone': _selectedCustomer!['phone'],
            },
            customerName: '',
            customerEmail: '',
            customerPhone: '',
            estimateData: const {},
          );
          break;
        case 'Granite Estimate':
          page = GraniteStoneEstimate(
            customerId: _selectedCustomer!['id'],
            customerInfo: {
              'name': _selectedCustomer!['name'],
              'email': _selectedCustomer!['email'],
              'phone': _selectedCustomer!['phone'],
            },
            customerName: '',
            customerEmail: '',
            customerPhone: '',
            estimateData: const {},
          );
          break;
        case 'Wainscoting Estimate':
          page = WeinscoatingEstimatePage(
            customerId: _selectedCustomer!['id'],
            customerInfo: {
              'name': _selectedCustomer!['name'],
              'email': _selectedCustomer!['email'],
              'phone': _selectedCustomer!['phone'],
            },
            customerName: '',
            customerEmail: '',
            customerPhone: '',
          );
          break;
        case 'Wallpaper Estimate':
          page = Wallpaper(
            customerId: _selectedCustomer!['id'],
            customerInfo: {
              'name': _selectedCustomer!['name'],
              'email': _selectedCustomer!['email'],
              'phone': _selectedCustomer!['phone'],
            },
            customerName: '',
            customerEmail: '',
            customerPhone: '',
            estimateData: const {},
          );
          break;
        default:
          page = EstimateListPage(
            customerId: _selectedCustomer!['id'],
          );
      }

      // Navigate to the estimate page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => page),
      );
    } else {
      // Show a message if no customer is selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer first')),
      );
    }
  }

  // Method to show the customer selection dialog (popup)
  void _showCustomerSelectionDialog(BuildContext context, String estimateType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select a Customer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dropdown to select a customer
              DropdownButton<Map<String, dynamic>>(
                value: _selectedCustomer,
                hint: const Text('Select a customer'),
                items: _customers.map((customer) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: customer,
                    child: Text(customer['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCustomer = value;
                  });
                },
              ),
              // If a customer is selected, show their details
              if (_selectedCustomer != null) ...[
                const SizedBox(height: 16),
                Text('Customer Name: ${_selectedCustomer!['name']}'),
                Text('Customer Email: ${_selectedCustomer!['email']}'),
                Text('Customer Phone: ${_selectedCustomer!['phone']}'),
              ]
            ],
          ),
          actions: [
            // Cancel button
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            // Confirm button to navigate to the selected estimate page
            ElevatedButton(
              onPressed: () {
                if (_selectedCustomer != null) {
                  Navigator.of(context).pop(); // Close the dialog
                  _navigateToEstimateType(context, estimateType);
                } else {
                  // Show a message if no customer is selected
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a customer')),
                  );
                }
              },
              child: const Text('Go to Estimate Page'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEstimateWidget(BuildContext context, String estimateType,
      IconData icon, Color iconColor) {
    double fontSize = MediaQuery.of(context).size.width < 600 ? 12 : 14;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            _showCustomerSelectionDialog(context, estimateType);
          },
          child: Container(
            // decoration: BoxDecoration(
            //   color: Colors.white,
            //   borderRadius: BorderRadius.circular(10),
            //   boxShadow: [
            //     BoxShadow(
            //       color: Colors.grey.shade300,
            //       blurRadius: 3,
            //       spreadRadius: 1,
            //     ),
            //   ],
            // ),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 28, color: iconColor),
                if (_isSidebarExpanded) ...[
                  Flexible(
                    child: Text(
                      estimateType,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
