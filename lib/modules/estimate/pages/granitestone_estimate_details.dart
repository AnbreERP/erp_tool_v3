import 'package:flutter/material.dart';
import '../../../database/g_database_helper.dart';
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

class GranitestoneEstimateDetails extends StatefulWidget {
  final int estimateId;

  const GranitestoneEstimateDetails({super.key, required this.estimateId});

  @override
  _GranitestoneEstimateDetailsState createState() =>
      _GranitestoneEstimateDetailsState();
}

class _GranitestoneEstimateDetailsState
    extends State<GranitestoneEstimateDetails> {
  List<Map<String, dynamic>> _estimateDetails = [];

  @override
  void initState() {
    super.initState();
    _loadEstimateDetails(); // Load estimate details when the page is initialized
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

  void _exportToExcel() async {
    final excel = Excel.createExcel();
    final sheet = excel['Granite Estimate'];

    // Add header
    sheet.appendRow([TextCellValue('Granite Estimate Details')]);
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
        TextCellValue(row['description'] ?? '-'),
        DoubleCellValue(_toDouble(row['length'])),
        DoubleCellValue(_toDouble(row['width'])),
        DoubleCellValue(_toDouble(row['area'])),
        DoubleCellValue(_toDouble(row['rate'])),
        DoubleCellValue(_toDouble(row['labour'])),
        DoubleCellValue(_toDouble(row['amount'])),
      ]);
    }

    final fileName = 'GraniteEstimate_${widget.estimateId}.xlsx';
    final bytes = excel.encode();
    if (bytes != null) {
      _downloadExcelWeb(Uint8List.fromList(bytes), fileName);
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '').replaceAll('₹', '')) ??
          0.0;
    }
    return 0.0;
  }
  //End

  // Load estimate details from the database
  Future<void> _loadEstimateDetails() async {
    try {
      print("🔍 Checking estimateId: ${widget.estimateId}");

      if (widget.estimateId <= 0) {
        throw Exception("Invalid estimate ID: ${widget.estimateId}");
      }

      // 🔹 Fetch estimate details (main + rows)
      Map<String, dynamic> estimateResponse =
          await GraniteDatabaseHelper.fetchEstimateDetails(widget.estimateId);

      print("📦 Fetched response: $estimateResponse");
      // ✅ Validate and extract
      if (estimateResponse.isEmpty ||
          !estimateResponse.containsKey('rows') ||
          !estimateResponse.containsKey('estimate')) {
        throw Exception("Invalid estimate response structure.");
      }

      final List<Map<String, dynamic>> details =
          List<Map<String, dynamic>>.from(estimateResponse['rows']);

      setState(() {
        _estimateDetails = details;
        // If needed, you can also store `mainEstimate` to show info like customerName, date, etc.
      });

      print("✅ Estimate and rows loaded successfully!");
    } catch (error) {
      print("❌ Error loading estimate details: $error");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load estimate details: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Delete estimate detail from the database
  void _deleteEstimateDetail(int estimateDetailId) async {
    try {
      await GraniteDatabaseHelper.deleteGraniteEstimate(estimateDetailId);
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

      // Navigate to Granite Stone Estimate Page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GraniteStoneEstimate(
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
            estimateData: const {},
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
                // Correctly reference the estimateId through widget.estimateId
                final estimate =
                    await GraniteDatabaseHelper.getGraniteEstimateById(
                        widget.estimateId); // Use widget.estimateId
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
                              _deleteEstimateDetail(detail['id']);
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
