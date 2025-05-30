import 'package:erp_tool/modules/estimate/pages/Quartz_Slab_Page.dart';
import 'package:flutter/material.dart';
import '../../../database/q_database_helper.dart';
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

class EstimateDetailsPage extends StatefulWidget {
  final int estimateId;

  const EstimateDetailsPage({super.key, required this.estimateId});

  @override
  _EstimateDetailsPageState createState() => _EstimateDetailsPageState();
}

class _EstimateDetailsPageState extends State<EstimateDetailsPage> {
  List<Map<String, dynamic>> _estimateDetails = [];

  @override
  void initState() {
    super.initState();
    _loadEstimateDetails(); // Load estimate details when the page is initialized
  }

  // Load estimate details from the database
  Future<void> _loadEstimateDetails() async {
    try {
      print("Fetching details for estimateId: ${widget.estimateId}");

      // 🔹 Fetch estimate data from API
      Map<String, dynamic> estimateResponse =
          await QDatabaseHelper.fetchEstimateDetails(widget.estimateId);

      if (estimateResponse.containsKey('rows')) {
        List<Map<String, dynamic>> details =
            List<Map<String, dynamic>>.from(estimateResponse['rows']);

        setState(() {
          _estimateDetails = details;
        });

        print("✅ Quartz Estimate details loaded successfully!");
      } else {
        throw Exception("Invalid response structure.");
      }
    } catch (error) {
      print("❌ Error loading estimate details: $error");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load estimate details: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  //Export Excel File
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

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  void _exportToExcel() async {
    final excel = Excel.createExcel();
    final sheet = excel['Quartz Slab Estimate'];

    sheet.appendRow([TextCellValue('Quartz Slab Estimate')]);
    sheet.appendRow([
      TextCellValue('Estimate ID'),
      TextCellValue(widget.estimateId.toString())
    ]);
    sheet.appendRow([]);

    const headers = [
      'Description',
      'Length (mm)',
      'Width (mm)',
      'Area (sq.ft)',
      'Rate',
      'Labour',
      'Amount'
    ];
    sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());

    for (final row in _estimateDetails) {
      sheet.appendRow([
        TextCellValue(row['description'] ?? ''),
        DoubleCellValue(_toDouble(row['length'])),
        DoubleCellValue(_toDouble(row['width'])),
        DoubleCellValue(_toDouble(row['area'])),
        DoubleCellValue(_toDouble(row['rate'])),
        DoubleCellValue(_toDouble(row['labour'])),
        DoubleCellValue(_toDouble(row['amount'])),
      ]);
    }

    final fileName = 'QuartzEstimate_${widget.estimateId}.xlsx';
    final bytes = excel.encode();
    if (bytes != null) {
      _downloadExcelWeb(Uint8List.fromList(bytes), fileName);
    }
  }

  // end

  void _navigateToEditWallpaper(
      BuildContext context, Map<String, dynamic> estimate) async {
    try {
      final mainEstimate = estimate['estimate'];
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
          builder: (context) => QuartzSlabPage(
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
            estimateData: estimate, // ✅ Pass full estimate (main + rows)
          ),
        ),
      );
    } catch (e) {
      print('❌ Error navigating to edit: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error navigating to edit: $e')),
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

  // Delete estimate detail from the database
  void _deleteEstimateDetail(int estimateDetailId) async {
    try {
      await QDatabaseHelper.deleteQuartzEstimate(
          estimateDetailId); // Delete the detail
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Estimate detail deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadEstimateDetails(); // Reload the details after deletion
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete estimate detail: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estimate Details'),
        backgroundColor: Colors.blueGrey,
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
                final estimate = await QDatabaseHelper.getQuartzEstimateById(
                    widget.estimateId); // Use the singleton instance
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _estimateDetails.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16.0,
                  headingRowHeight: 50,
                  dataRowHeight: 60,
                  columns: const [
                    DataColumn(label: Text('Description')),
                    DataColumn(label: Text('Length (mm)')),
                    DataColumn(label: Text('Width (mm)')),
                    DataColumn(label: Text('Area (sq.ft)')),
                    DataColumn(label: Text('Rate')),
                    DataColumn(label: Text('Labour')),
                    DataColumn(label: Text('Amount')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: List<DataRow>.generate(
                    _estimateDetails.length,
                    (index) {
                      var detail = _estimateDetails[index];
                      return DataRow(cells: [
                        DataCell(Text(detail['description'] ?? '-')),
                        DataCell(Text(detail['length'].toString())),
                        DataCell(Text(detail['width'].toString())),
                        DataCell(Text(detail['area'].toString())),
                        DataCell(Text(detail['rate'].toString())),
                        DataCell(Text(detail['labour'].toString())),
                        DataCell(Text(detail['amount'].toString())),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _deleteEstimateDetail(
                                  detail['id']); // Delete the detail by its ID
                            },
                          ),
                        ),
                      ]);
                    },
                  ),
                ),
              ),
      ),
    );
  }
}
