import 'package:erp_tool/modules/estimate/pages/wallpaper.dart';
import 'package:erp_tool/modules/estimate/pages/weinscoating_estimate.dart';
import 'package:flutter/material.dart';
import '../../../database/c_database_helper.dart';
import 'charcoal_estimate.dart';
import 'new_woodwork_estimate_page.dart';
import 'Quartz_Slab_Page.dart';
import 'electrical_estimate_page.dart';
import 'estimate_list_page.dart';
import 'false_ceiling_estimate_page.dart';
import 'granite_stone_estimate.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:excel/excel.dart';
import 'dart:typed_data';
import 'dart:js_interop';

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

class EstimateDetailPage extends StatefulWidget {
  final int estimateId;
  const EstimateDetailPage({
    super.key,
    required this.estimateId,
  });

  @override
  _EstimateDetailPageState createState() => _EstimateDetailPageState();
}

class _EstimateDetailPageState extends State<EstimateDetailPage> {
  Map<String, dynamic>? _selectedCustomer;
  final List<Map<String, dynamic>> _customers = [];
  bool _isSidebarExpanded = true;
  // 🔹 Set AWS Public IP + Node.js API Port
  static const String baseUrl = "http://127.0.0.1:4000";

  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Estimate Details"),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export to Excel',
            onPressed: _exportToExcel,
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () async {
              print(
                  "Edit button clicked. Fetching estimate for ID: ${widget.estimateId}");
              try {
                final estimate =
                    await CDatabaseHelper.fetchCharcoalEstimateById(
                        widget.estimateId);
                print("Fetched estimate: $estimate");
                _navigateToEditCharcoal(context, estimate);
                print(
                    "Navigation to edit page successful for estimate ID: ${widget.estimateId}");
              } catch (e) {
                print("Error fetching estimate or navigating to edit: $e");
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
          // AnimatedContainer(
          //   duration: const Duration(milliseconds: 300),
          //   width: _isSidebarExpanded ? 260 : 80, // Expands or collapses
          //   padding: const EdgeInsets.all(16.0),
          //   decoration: BoxDecoration(
          //     color: Colors.blue.shade900,
          //     borderRadius: const BorderRadius.only(
          //       topRight: Radius.circular(0),
          //       bottomRight: Radius.circular(20),
          //     ),
          //   ),
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       // Toggle Button
          //       Align(
          //         alignment: Alignment.centerRight,
          //         child: IconButton(
          //           icon: Icon(
          //             _isSidebarExpanded
          //                 ? Icons.chevron_left
          //                 : Icons.chevron_right,
          //             color: Colors.white,
          //           ),
          //           onPressed: _toggleSidebar,
          //         ),
          //       ),
          //       if (_isSidebarExpanded) // Show title only if expanded
          //         const Padding(
          //           padding: EdgeInsets.only(bottom: 16.0),
          //           child: Text(
          //             'Estimate Types',
          //             style: TextStyle(
          //               color: Colors.white,
          //               fontSize: 18,
          //               fontWeight: FontWeight.bold,
          //             ),
          //           ),
          //         ),
          //
          //       // Estimate Type Buttons (Responsive)
          //       _buildEstimateWidget(
          //           context, 'Woodwork', Icons.build, Colors.white),
          //       _buildEstimateWidget(context, 'Electrical',
          //           Icons.electrical_services, Colors.white),
          //       _buildEstimateWidget(context, 'False Ceiling',
          //           Icons.home_repair_service, Colors.white),
          //       _buildEstimateWidget(context, 'Wallpaper Estimate',
          //           Icons.wallpaper, Colors.white),
          //       _buildEstimateWidget(
          //           context, 'Charcoal Estimate', Icons.widgets, Colors.white),
          //       _buildEstimateWidget(context, 'Quartz Slab Estimate',
          //           Icons.kitchen, Colors.white),
          //       _buildEstimateWidget(
          //           context, 'Granite Estimate', Icons.ac_unit, Colors.white),
          //       _buildEstimateWidget(context, 'Wainscoting Estimate',
          //           Icons.format_paint, Colors.white),
          //     ],
          //   ),
          // ),

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
                      future: CDatabaseHelper.fetchCharcoalEstimateById(
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
                          return const Center(
                              child: Text('No estimate found.'));
                        } else {
                          final estimate = snapshot.data!;
                          return _buildEstimateDetails(context, estimate);
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

  // Export Excel File
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '').replaceAll('₹', '')) ??
          0.0;
    }
    return 0.0;
  }

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

  void _exportToExcel() async {
    final excel = Excel.createExcel();
    final sheet = excel['Charcoal Estimate'];

    // Fetch your estimate data
    final data =
        await CDatabaseHelper.fetchCharcoalEstimateById(widget.estimateId);
    if (data.isEmpty) return;

    final estimate = data['estimate'] ?? {};
    final rows = data['rows'] ?? [];

    // Header
    sheet.appendRow([TextCellValue('Charcoal Estimate')]);
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
    sheet.appendRow([
      TextCellValue('Discount'),
      DoubleCellValue(_toDouble(estimate['discount']))
    ]);
    sheet.appendRow(
        [TextCellValue('GST'), DoubleCellValue(_toDouble(estimate['gst']))]);
    sheet.appendRow([
      TextCellValue('Total Amount'),
      DoubleCellValue(_toDouble(estimate['totalAmount']))
    ]);

    sheet.appendRow([]);

    // Table Header
    const headers = [
      'S.No',
      'Description',
      'Length (mm)',
      'Width (mm)',
      'Rate',
      'Laying',
      'Area',
      'Amount'
    ];
    sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());

    for (final row in rows) {
      sheet.appendRow([
        TextCellValue('${row['S.No'] ?? ''}'),
        TextCellValue('${row['description'] ?? ''}'),
        DoubleCellValue(_toDouble(row['length'])),
        DoubleCellValue(_toDouble(row['height'])),
        DoubleCellValue(_toDouble(row['rate'])),
        DoubleCellValue(_toDouble(row['laying'])),
        DoubleCellValue(_toDouble(row['area'])),
        DoubleCellValue(_toDouble(row['amount'])),
      ]);
    }

    final customer = (estimate['customerName'] ?? 'Customer')
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(' ', '_');

    final fileName = 'CharcoalEstimate_${customer}_${estimate['id']}.xlsx';

    final bytes = excel.encode();
    if (bytes != null) {
      _downloadExcelWeb(Uint8List.fromList(bytes), fileName);
    }
  }

  // End

  Widget _buildEstimateDetails(
      BuildContext context, Map<String, dynamic> response) {
    final estimate = response['estimate'] as Map<String, dynamic>;
    final rows = List<Map<String, dynamic>>.from(response['rows']);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          _buildDetailRow("Estimate ID", estimate['id']?.toString() ?? "N/A"),
          _buildDetailRow(
              "Customer ID", estimate['customerId']?.toString() ?? "N/A"),
          _buildDetailRow("GST", "₹${estimate['gst']?.toString() ?? "0"}"),
          _buildDetailRow(
              "Discount", "₹${estimate['discount']?.toString() ?? "0"}"),
          _buildDetailRow(
              "Transport", "₹${estimate['transport']?.toString() ?? "0"}"),
          _buildDetailRow(
              "Total Amount", "₹${estimate['totalAmount']?.toString() ?? "0"}"),
          const Divider(thickness: 2, color: Colors.black12),
          const SizedBox(height: 16),
          const Text(
            "Row Details",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 10),
          _buildRowDetails(context, rows),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          Text(value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRowDetails(
      BuildContext context, List<Map<String, dynamic>> rows) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text("S.No")),
          DataColumn(label: Text("Description")),
          DataColumn(label: Text("Length (mm)")),
          DataColumn(label: Text("Width (mm)")),
          DataColumn(label: Text("Rate (₹)")),
          DataColumn(label: Text("Laying (₹)")),
          DataColumn(label: Text("Area (ft²)")),
          DataColumn(label: Text("Amount (₹)")),
        ],
        rows: List<DataRow>.generate(
          rows.length,
          (index) {
            final row = rows[index];
            return DataRow(
              cells: [
                DataCell(Text('${index + 1}')),
                DataCell(Text(row['description'] ?? 'N/A')),
                DataCell(Text(row['length']?.toString() ?? '0')),
                DataCell(Text(row['height']?.toString() ?? '0')),
                DataCell(Text(row['rate']?.toString() ?? '0')),
                DataCell(Text(row['laying']?.toString() ?? '0')),
                DataCell(Text(row['area']?.toString() ?? '0')),
                DataCell(Text(row['amount']?.toString() ?? '0')),
              ],
            );
          },
        ),
      ),
    );
  }

  void _navigateToEditCharcoal(
      BuildContext context, Map<String, dynamic> estimate) async {
    try {
      final mainEstimate = estimate['estimate'] ?? {};
      final customerId = mainEstimate['customerId'] as int?;
      final estimateId = mainEstimate['id'] as int?;

      if (customerId == null || estimateId == null) {
        throw Exception('Invalid data: customerId or estimateId is null.');
      }

      final customerInfo = await fetchCustomerById(customerId);

      if (customerInfo == null) {
        throw Exception('Customer data not found for ID: $customerId');
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CharcoalEstimate(
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
            estimateData: estimate, // Pass full estimate data
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
    final String apiUrl = '$baseUrl/api/customers/$customerId';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        print('Error: Customer not found.');
        return null;
      } else {
        print('Error fetching customer: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception occurred: $e');
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
