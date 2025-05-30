import 'package:flutter/material.dart';
import '../../../database/f_database_helper.dart';
import 'false_ceiling_estimate_page.dart';
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

class FalseCeilingEstimateDetailPage extends StatefulWidget {
  final int estimateId;

  const FalseCeilingEstimateDetailPage({super.key, required this.estimateId});

  @override
  _FalseCeilingEstimateDetailPageState createState() =>
      _FalseCeilingEstimateDetailPageState();
}

class _FalseCeilingEstimateDetailPageState
    extends State<FalseCeilingEstimateDetailPage> {
  Map<String, dynamic>? _selectedCustomer;
  // 🔹 Set AWS Public IP + Node.js API Port
  static const String baseUrl = "http://127.0.0.1:4000";

  // Toggle Sidebar Width

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '').replaceAll('₹', '')) ??
          0.0;
    }
    return 0.0;
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

  void _exportToExcel() async {
    final excel = Excel.createExcel();
    final sheet = excel['False Ceiling Estimate'];

    final snapshot =
        await FDatabaseHelper.fetchEstimateDetails(widget.estimateId);
    if (snapshot.isEmpty) return;

    final estimate = snapshot['estimate'];
    final rows = snapshot['rows'];

    // Header
    sheet.appendRow([TextCellValue('False Ceiling Estimate')]);
    sheet.appendRow([]);
    sheet.appendRow([TextCellValue('Customer Info')]);
    sheet.appendRow([
      TextCellValue('Name'),
      TextCellValue(_selectedCustomer?['name'] ?? 'N/A')
    ]);
    sheet.appendRow([
      TextCellValue('Email'),
      TextCellValue(_selectedCustomer?['email'] ?? 'N/A')
    ]);
    sheet.appendRow([
      TextCellValue('Phone'),
      TextCellValue(_selectedCustomer?['phone'] ?? 'N/A')
    ]);

    sheet.appendRow([]);
    sheet.appendRow([TextCellValue('Estimate Info')]);
    sheet.appendRow(
        [TextCellValue('Estimate ID'), TextCellValue('${estimate['id']}')]);
    sheet.appendRow(
        [TextCellValue('GST'), DoubleCellValue(_toDouble(estimate['gst']))]);
    sheet.appendRow([
      TextCellValue('Grand Total'),
      DoubleCellValue(_toDouble(estimate['totalAmount']))
    ]);

    sheet.appendRow([]);
    const headers = [
      'Type',
      'Description',
      'Length (mm)',
      'Height (mm)',
      'Length (ft)',
      'Height (ft)',
      'Area (sq.ft)',
      'Quantity',
      'Rate',
      'Amount'
    ];
    sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());

    for (final row in rows) {
      sheet.appendRow([
        TextCellValue('${row['type'] ?? ''}'),
        TextCellValue('${row['description'] ?? ''}'),
        DoubleCellValue(_toDouble(row['length'])),
        DoubleCellValue(_toDouble(row['width'])),
        DoubleCellValue(_toDouble(row['lengthFt'])),
        DoubleCellValue(_toDouble(row['widthFt'])),
        DoubleCellValue(_toDouble(row['area'])),
        DoubleCellValue(_toDouble(row['quantity'])),
        DoubleCellValue(_toDouble(row['rate'])),
        DoubleCellValue(_toDouble(row['amount'])),
      ]);
    }

    // Download
    final customerName = _selectedCustomer?['name'] ?? 'Customer';
    final safeName =
        customerName.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_');
    final fileName = 'FalseCeilingEstimate_${safeName}_${estimate['id']}.xlsx';

    final bytes = excel.encode();
    if (bytes != null) {
      _downloadExcelWeb(Uint8List.fromList(bytes), fileName);
    }
  }

  // End

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('False Ceiling Estimate Details'),
          backgroundColor: Colors.blue.shade900,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.file_download),
              tooltip: "Export to Excel",
              onPressed: _exportToExcel,
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () async {
                try {
                  final estimate =
                      await FDatabaseHelper.getFalseCeilingEstimateById(
                          widget.estimateId);
                  _navigateToEdit(context, estimate);
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
            //       _buildEstimateWidget(context, 'Charcoal Estimate',
            //           Icons.widgets, Colors.white),
            //       _buildEstimateWidget(context, 'Quartz Slab Estimate',
            //           Icons.kitchen, Colors.white),
            //       _buildEstimateWidget(
            //           context, 'Granite Estimate', Icons.ac_unit, Colors.white),
            //       _buildEstimateWidget(context, 'Wainscoting Estimate',
            //           Icons.format_paint, Colors.white),
            //     ],
            //   ),
            // ),
            FutureBuilder<Map<String, dynamic>>(
              future: FDatabaseHelper.fetchEstimateDetails(widget.estimateId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No data found.'));
                } else {
                  final estimate =
                      snapshot.data!['estimate']; // Get main estimate data
                  final rows = snapshot.data!['rows']; // Get rows data

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estimate Details:',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis
                              .horizontal, // Horizontal scroll for the table
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Type')),
                              DataColumn(label: Text('Description')),
                              DataColumn(label: Text('Length (mm)')),
                              DataColumn(label: Text('Height (mm)')),
                              DataColumn(label: Text('Length (ft)')),
                              DataColumn(label: Text('Height (ft)')),
                              DataColumn(label: Text('Area (sq.ft)')),
                              DataColumn(label: Text('Quantity')),
                              DataColumn(label: Text('Rate')),
                              DataColumn(label: Text('Amount')),
                            ],
                            rows: rows.map<DataRow>((row) {
                              return DataRow(cells: [
                                DataCell(Text('${row['type'] ?? 'N/A'}')),
                                DataCell(
                                    Text('${row['description'] ?? 'N/A'}')),
                                DataCell(Text('${row['length'] ?? 0}')),
                                DataCell(Text('${row['width'] ?? 0}')),
                                DataCell(Text('${row['lengthFt'] ?? 0}')),
                                DataCell(Text('${row['widthFt'] ?? 0}')),
                                DataCell(Text('${row['area'] ?? 0}')),
                                DataCell(Text('${row['quantity'] ?? 0}')),
                                DataCell(Text('₹${row['rate'] ?? 0}')),
                                DataCell(Text('₹${row['amount'] ?? 0}')),
                              ]);
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 20),

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

                        // Delete Button
                        ElevatedButton(
                          onPressed: () =>
                              _deleteEstimate(context, estimate['id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'Delete Estimate',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ],
        ));
  }

  Future<void> _deleteEstimate(BuildContext context, int estimateId) async {
    await FDatabaseHelper.deleteFalseCeilingEstimate(estimateId);
    Navigator.pop(context); // Close the current page after deletion
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Estimate deleted successfully!')),
    );
  }

  void _navigateToEdit(
      BuildContext context, Map<String, dynamic> estimate) async {
    try {
      final mainEstimate = estimate['estimate'] ?? {};
      final customerId = mainEstimate['customerId'] as int?;
      final estimateId = mainEstimate['id'] as int?;

      // Ensure valid customerId and estimateId
      if (customerId == null || estimateId == null) {
        throw Exception('Invalid data: customerId or estimateId is null.');
      }

      // Fetch customer info from API
      final customerInfo = await fetchCustomerById(customerId);

      if (customerInfo == null) {
        throw Exception('Customer data not found for ID: $customerId');
      }

      // Navigate to False Ceiling Estimate Page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FalseCeilingEstimatePage(
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
}
