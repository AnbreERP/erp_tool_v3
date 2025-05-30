import 'package:flutter/material.dart';
import 'package:erp_tool/database/grass_database_helper.dart';
import 'grass_estimate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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

class GrassEstimatesPage extends StatefulWidget {
  const GrassEstimatesPage({super.key});

  @override
  _GrassEstimatesPageState createState() => _GrassEstimatesPageState();
}

class _GrassEstimatesPageState extends State<GrassEstimatesPage> {
  late Future<List<dynamic>> _grassEstimates;

  @override
  void initState() {
    super.initState();
    _grassEstimates = GrassDatabaseHelper
        .getGrassEstimates(); // Fetch all estimates when the page loads
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('All Grass Estimates'),
          backgroundColor: Colors.blue.shade900,
          foregroundColor: Colors.white),
      backgroundColor: Colors.white,
      body: FutureBuilder<List<dynamic>>(
        future: _grassEstimates,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No grass estimates found.'));
          } else {
            return _buildEstimatesTable(snapshot.data!);
          }
        },
      ),
    );
  }

  Widget _buildEstimatesTable(List<dynamic> estimates) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, // Handle overflow for large tables
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Estimate ID')),
          DataColumn(label: Text('Customer ID')),
          DataColumn(label: Text('Hike')),
          DataColumn(label: Text('Transport')),
          DataColumn(label: Text('GST')),
          DataColumn(label: Text('Total Amount')),
          DataColumn(label: Text('Version')),
          //DataColumn(label: Text('Created At')),
        ],
        rows: estimates.map((estimate) {
          return DataRow(
            cells: [
              DataCell(Text(estimate['id'].toString())),
              DataCell(Text(estimate['customerId'].toString())),
              DataCell(Text(estimate['hike'].toString())),
              DataCell(Text(estimate['transport'].toString())),
              DataCell(Text(estimate['gst'].toString())),
              DataCell(Text(estimate['totalAmount'].toString())),
              DataCell(Text(estimate['version'].toString())),
              //DataCell(Text(estimate['timestamp'].toString())),
            ],
            onSelectChanged: (selected) async {
              if (selected!) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        GrassEstimateDetailsPage(estimateId: estimate['id']),
                  ),
                );
              }
              setState(() {
                _grassEstimates = GrassDatabaseHelper.getGrassEstimates();
              });
            },
          );
        }).toList(),
      ),
    );
  }
}

class GrassEstimateDetailsPage extends StatefulWidget {
  final int estimateId;
  const GrassEstimateDetailsPage({required this.estimateId, super.key});

  @override
  _GrassEstimateDetailsPageState createState() =>
      _GrassEstimateDetailsPageState();
}

class _GrassEstimateDetailsPageState extends State<GrassEstimateDetailsPage> {
  late Future<Map<String, dynamic>> _estimateDetails;

  // Declare the missing variables
  String? customerName;
  String? customerEmail;
  String? customerPhone;
  Map<String, dynamic>? estimateData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _estimateDetails =
        GrassDatabaseHelper.getGrassEstimateById(widget.estimateId);
    _estimateDetails.then((estimate) {
      fetchCustomerInfo(estimate['customerId']);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estimate Details'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export to Excel',
            onPressed: () async {
              final data = await _estimateDetails;
              _exportToExcel(data);
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _estimateDetails,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData) {
              return const Center(child: Text('No estimate found.'));
            } else {
              return _buildEstimateDetails(snapshot.data!);
            }
          },
        ),
      ),
    );
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

  void _exportToExcel(Map<String, dynamic> estimate) {
    final excel = Excel.createExcel();
    final sheet = excel['Grass Estimate'];

    sheet.appendRow([TextCellValue('Grass Estimate')]);
    sheet.appendRow([]);
    sheet.appendRow([TextCellValue('Customer Info')]);
    sheet.appendRow(
        [TextCellValue('Name'), TextCellValue(customerName ?? 'N/A')]);
    sheet.appendRow(
        [TextCellValue('Email'), TextCellValue(customerEmail ?? 'N/A')]);
    sheet.appendRow(
        [TextCellValue('Phone'), TextCellValue(customerPhone ?? 'N/A')]);

    sheet.appendRow([]);
    sheet.appendRow([TextCellValue('Estimate Info')]);
    sheet.appendRow(
        [TextCellValue('Estimate ID'), TextCellValue('${widget.estimateId}')]);
    sheet.appendRow([
      TextCellValue('Total Amount'),
      DoubleCellValue(_toDouble(estimate['totalAmount']))
    ]);
    sheet.appendRow([]);

    const headers = [
      'Description',
      'Additional Info',
      'Length',
      'Height',
      'Area',
      'Rate',
      'Laying',
      'Amount'
    ];
    sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());

    List rows = estimate['rows'] ?? [];
    for (final row in rows) {
      sheet.appendRow([
        TextCellValue(row['description'] ?? ''),
        TextCellValue(row['additional_info'] ?? ''),
        DoubleCellValue(_toDouble(row['length'])),
        DoubleCellValue(_toDouble(row['height'])),
        DoubleCellValue(_toDouble(row['area'])),
        DoubleCellValue(_toDouble(row['rate'])),
        DoubleCellValue(_toDouble(row['laying'])),
        DoubleCellValue(_toDouble(row['amount'])),
      ]);
    }

    final fileName = 'GrassEstimate_${widget.estimateId}.xlsx';
    final bytes = excel.encode();
    if (bytes != null) {
      _downloadExcelWeb(Uint8List.fromList(bytes), fileName);
    }
  }

  //End
  Widget _buildEstimateDetails(Map<String, dynamic> estimate) {
    // Get the rows from the estimate data
    List<dynamic> rows = estimate['rows'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display estimate details in a row with padding
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                'Estimate ID: ${estimate['id']}',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Customer ID: ${estimate['customerId']}',
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Total Amount: ${estimate['totalAmount']}',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16), // Add some space before the table

        // Display estimate rows with Edit and Delete buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Text(
              'Estimate Rows:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    _editEstimate(estimate);
                  },
                  child: const Text('Edit'),
                ),
                TextButton(
                  onPressed: () {
                    _confirmDelete(estimate['id']);
                  },
                  child: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildEstimateRowsTable(rows),
      ],
    );
  }

  Widget _buildEstimateRowsTable(List<dynamic> rows) {
    return DataTable(
      columns: const [
        DataColumn(label: Text('Description')),
        DataColumn(label: Text('Additional Info')),
        DataColumn(label: Text('Length')),
        DataColumn(label: Text('Height')),
        DataColumn(label: Text('Area')),
        DataColumn(label: Text('Rate')),
        DataColumn(label: Text('Laying')),
        DataColumn(label: Text('Amount')),
      ],
      rows: rows.map((row) {
        return DataRow(
          cells: [
            DataCell(Text(row['description'] ?? '')),
            DataCell(Text(row['additional_info'] ?? '')),
            DataCell(Text(row['length'].toString())),
            DataCell(Text(row['height'].toString())),
            DataCell(Text(row['area'].toString())),
            DataCell(Text(row['rate'].toString())),
            DataCell(Text(row['laying'].toString())),
            DataCell(Text(row['amount'].toString())),
          ],
        );
      }).toList(),
    );
  }

  Future<void> fetchCustomerInfo(int customerId) async {
    try {
      const String baseUrl = "http://127.0.0.1:4000/api"; // API base URL
      final response =
          await http.get(Uri.parse("$baseUrl/customers/$customerId"));

      if (response.statusCode == 200) {
        // Parse the customer info from the response
        Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          customerName = data['customerName'];
          customerEmail = data['customerEmail'];
          customerPhone = data['customerPhone'];
          estimateData = data; // Set customer data for GrassEstimate
          isLoading = false; // Data has been loaded
        });
      } else {
        throw Exception('Failed to load customer info');
      }
    } catch (e) {
      print("Error fetching customer info: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // 🛠️ Edit Estimate Logic
  void _editEstimate(Map<String, dynamic> estimate) async {
    final customerData =
        await GrassDatabaseHelper.getCustomerById(estimate['customerId']);

    final updatedEstimate = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GrassEstimate(
          customerId: estimate['customerId'],
          estimateId: estimate['id'],
          customerInfo: customerData,
          customerName: customerData['customerName'] ?? 'Unknown',
          customerEmail: customerData['customerEmail'] ?? 'Unknown',
          customerPhone: customerData['customerPhone'] ?? 'Unknown',
          estimateData: estimate,
          existingEstimateData: estimate,
        ),
      ),
    );

    if (updatedEstimate != null) {
      // Instead of calling update, just refresh the page
      setState(() {
        _estimateDetails =
            GrassDatabaseHelper.getGrassEstimateById(widget.estimateId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('✅ New version of estimate created successfully')),
      );
    }
  }

  // 🛠️ Confirm Delete Estimate
  void _confirmDelete(int estimateId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Estimate'),
          content: const Text('Are you sure you want to delete this estimate?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteEstimate(estimateId);
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // 🛠️ Delete Estimate Logic
  void _deleteEstimate(int estimateId) async {
    bool success = await GrassDatabaseHelper.deleteGrassEstimate(estimateId);

    if (success) {
      // Navigator.pop(context); // Close dialog
      Navigator.pop(context); // Go back to the list page
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estimate deleted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete estimate')),
      );
    }
  }
}
