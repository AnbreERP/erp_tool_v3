import 'package:erp_tool/modules/estimate/pages/wallpaper.dart';
import 'package:flutter/material.dart';
import '../../../database/w_database_helper.dart';
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

class WallpaperEstimateDetailPage extends StatefulWidget {
  final int estimateId;

  const WallpaperEstimateDetailPage({super.key, required this.estimateId});
  // 🔹 Set AWS Public IP + Node.js API Port
  static const String baseUrl = "http://127.0.0.1:4000/api/wallpaper";

  @override
  State<WallpaperEstimateDetailPage> createState() =>
      _WallpaperEstimateDetailPageState();
}

class _WallpaperEstimateDetailPageState
    extends State<WallpaperEstimateDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estimate Details'),
        backgroundColor: Colors.purple,
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
              try {
                final estimate = await WDatabaseHelper.getWallpaperEstimateById(
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
      body: FutureBuilder<Map<String, dynamic>>(
        future:
            WDatabaseHelper.fetchWallpaperEstimateDetails(widget.estimateId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data found.'));
          } else {
            final Map<String, dynamic> estimate =
                snapshot.data!['estimate'] ?? {};
            final List<Map<String, dynamic>> rows =
                List<Map<String, dynamic>>.from(snapshot.data!['rows'] ?? []);

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estimate Details:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Discount')),
                        DataColumn(label: Text('GST')),
                        DataColumn(label: Text('Transport')),
                        DataColumn(label: Text('Labour')),
                        DataColumn(label: Text('Total Amount')),
                        DataColumn(label: Text('Room')),
                        DataColumn(label: Text('Description')),
                        DataColumn(label: Text('Length')),
                        DataColumn(label: Text('Height')),
                        DataColumn(label: Text('Rate')),
                        DataColumn(label: Text('Quantity')),
                        DataColumn(label: Text('Amount')),
                        DataColumn(label: Text('Primer Included')),
                        DataColumn(label: Text('Action')),
                      ],
                      rows: rows.map<DataRow>((row) {
                        return DataRow(cells: [
                          DataCell(Text('₹${estimate['discount'] ?? 'N/A'}')),
                          DataCell(
                              Text('₹${estimate['gstPercentage'] ?? 'N/A'}')),
                          DataCell(
                              Text('₹${estimate['transportCost'] ?? 'N/A'}')),
                          DataCell(Text('₹${estimate['labour'] ?? 'N/A'}')),
                          DataCell(
                              Text('₹${estimate['totalAmount'] ?? 'N/A'}')),
                          DataCell(Text('${row['room'] ?? 'N/A'}')),
                          DataCell(Text('${row['description'] ?? 'N/A'}')),
                          DataCell(Text('${row['length'] ?? 'N/A'} mm')),
                          DataCell(Text('${row['height'] ?? 'N/A'} mm')),
                          DataCell(Text('₹${row['rate'] ?? 'N/A'}')),
                          DataCell(Text('${row['quantity'] ?? 'N/A'}')),
                          DataCell(Text('₹${row['amount'] ?? 'N/A'}')),
                          DataCell(Text((row['primerIncluded'] ?? 0) == 1
                              ? 'Yes'
                              : 'No')),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () {
                                    _deleteEstimate(context, estimate['id']);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          }
        },
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
    final sheet = excel['Wallpaper Estimate'];

    // Fetch your estimate data
    final data =
        await WDatabaseHelper.fetchWallpaperEstimateDetails(widget.estimateId);
    if (data.isEmpty) return;

    final estimate = data['estimate'] ?? {};
    final rows = data['rows'] ?? [];

    // Header
    sheet.appendRow([TextCellValue('Wallpaper Estimate')]);
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
      'Room',
      'Description',
      'Width (ft)',
      'Height (ft)',
      'Area (sq.ft)',
      'Rolls Required',
      'Rate',
      'Amount'
    ];
    sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());

    for (final row in rows) {
      sheet.appendRow([
        TextCellValue('${row['room'] ?? ''}'),
        TextCellValue('${row['description'] ?? ''}'),
        DoubleCellValue(_toDouble(row['width'])),
        DoubleCellValue(_toDouble(row['height'])),
        DoubleCellValue(_toDouble(row['area'])),
        DoubleCellValue(_toDouble(row['rolls'])),
        DoubleCellValue(_toDouble(row['rate'])),
        DoubleCellValue(_toDouble(row['amount'])),
      ]);
    }

    final customer = (estimate['customerName'] ?? 'Customer')
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(' ', '_');

    final fileName = 'WallpaperEstimate_${customer}_${estimate['id']}.xlsx';

    final bytes = excel.encode();
    if (bytes != null) {
      _downloadExcelWeb(Uint8List.fromList(bytes), fileName);
    }
  }

  // End
  void _navigateToEditWallpaper(
      BuildContext context, Map<String, dynamic> estimate) async {
    try {
      final mainEstimate = estimate['estimate'] ?? {};
      final customerId = mainEstimate['customerId'] as int?;
      final estimateId = mainEstimate['id'] as int?;

      // Ensure customerId and estimateId are valid
      if (customerId == null || estimateId == null) {
        throw Exception('Invalid data: customerId or estimateId is null.');
      }

      // Fetch customer info from the API (not database)
      final customerInfo = await fetchCustomerById(customerId);

      if (customerInfo == null) {
        throw Exception('Customer data not found for ID: $customerId');
      }

      print(
          '✅ Navigating to edit wallpaper with: customerId=$customerId, estimateId=$estimateId');

      final estimateData =
          await WDatabaseHelper.getWallpaperEstimateById(estimateId);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Wallpaper(
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
            estimateData: estimateData, // ✅ Pass the loaded estimate data
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

  Future<void> _deleteEstimate(BuildContext context, int estimateId) async {
    await WDatabaseHelper.deleteWallpaperEstimate(estimateId);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Estimate deleted successfully!')),
    );
  }
}
