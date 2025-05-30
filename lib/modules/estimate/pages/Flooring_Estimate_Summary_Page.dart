import 'package:flutter/material.dart';
import '../../../database/Flooring_Estimate_Database_helper.dart';
import '../../../widgets/sidebar_menu.dart';
import 'Flooring_Estimate.dart';
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

class FlooringEstimateSummaryPage extends StatefulWidget {
  final int customerId;

  const FlooringEstimateSummaryPage({super.key, required this.customerId});

  @override
  _FlooringEstimateSummaryPageState createState() =>
      _FlooringEstimateSummaryPageState();
}

class _FlooringEstimateSummaryPageState
    extends State<FlooringEstimateSummaryPage> {
  late Future<List<Map<String, dynamic>>> _estimatesFuture;

  @override
  void initState() {
    super.initState();
    _estimatesFuture =
        FlooringEstimateDatabaseHelper.getFlooringEstimatesByCustomer(
            widget.customerId);

    _estimatesFuture.then((data) {
      for (var row in data) {
        print('Row: $row');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flooring Estimates Summary'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        actions: const [],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _estimatesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No estimates found.'));
          } else {
            final estimates = snapshot.data!;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateColor.resolveWith(
                      (states) => Colors.grey.shade100),
                  columns: const [
                    DataColumn(label: Text('Estimate ID')),
                    DataColumn(label: Text('Version')),
                    DataColumn(label: Text('Flooring Type')),
                    DataColumn(label: Text('Total Amount')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: estimates.map<DataRow>((estimate) {
                    final estimateId = estimate['estimateId'];
                    final version = estimate['version'] ?? 'N/A';
                    final type = estimate['flooringType'] ?? 'Unknown';
                    final totalAmount = estimate['totalAmount'] ?? 0.0;

                    return DataRow(
                      cells: [
                        DataCell(Text(estimateId.toString())),
                        DataCell(Text(version.toString())),
                        DataCell(Text(type)),
                        DataCell(Text('₹$totalAmount')),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.visibility,
                                color: Colors.blue),
                            onPressed: () {
                              final estimateId = estimate['estimateId'];
                              final flooringType =
                                  estimate['flooringType'] ?? 'Unknown';
                              print(
                                  "Navigating to details page with estimateId: $estimateId");
                              print('Estimate keys: ${estimate.keys}');

                              if (estimateId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text("❌ Estimate ID is missing.")),
                                );
                                return;
                              }

                              SidebarController.of(context)?.openPage(
                                FlooringEstimateDetailsPage(
                                  estimateId: estimateId,
                                  flooringType: flooringType,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

class FlooringEstimateDetailsPage extends StatefulWidget {
  final int estimateId;
  final String flooringType;

  const FlooringEstimateDetailsPage({
    required this.estimateId,
    required this.flooringType,
    super.key,
  });

  @override
  _FlooringEstimateDetailsPageState createState() =>
      _FlooringEstimateDetailsPageState();
}

class _FlooringEstimateDetailsPageState
    extends State<FlooringEstimateDetailsPage> {
  late Future<Map<String, dynamic>> _estimateDetails;

  @override
  void initState() {
    super.initState();
    _fetchEstimate();
  }

//Export Excel File
  void _exportToExcel(Map<String, dynamic> estimate) {
    final excel = Excel.createExcel();
    final sheet = excel['Flooring Estimate'];

    final summary = estimate['summary'];
    final rows = List<Map<String, dynamic>>.from(estimate['rows'] ?? []);

    // Header
    sheet.appendRow([TextCellValue('Flooring Estimate Summary')]);
    sheet.appendRow([]);
    sheet.appendRow([
      TextCellValue('Customer Name'),
      TextCellValue(summary['customer_name'] ?? '')
    ]);
    sheet.appendRow([
      TextCellValue('Estimate ID'),
      TextCellValue((summary['estimateId'] ?? '').toString())
    ]);
    sheet.appendRow([
      TextCellValue('Flooring Type'),
      TextCellValue(summary['flooringType'] ?? '')
    ]);
    sheet.appendRow([
      TextCellValue('Installation Cost'),
      TextCellValue('₹${summary['installation_cost']}')
    ]);
    sheet.appendRow(
        [TextCellValue('Foam'), TextCellValue('₹${summary['foam']}')]);
    sheet.appendRow([
      TextCellValue('Transport Charges'),
      TextCellValue('₹${summary['transport_charges']}')
    ]);
    sheet.appendRow([
      TextCellValue('Total Amount'),
      TextCellValue('₹${summary['totalAmount']}')
    ]);
    sheet.appendRow([]);

    // Table Header
    const headers = [
      'Description',
      'Length',
      'Width',
      'Area',
      'Per Box',
      'Total Required',
      'Boxes',
      'Area Required',
      'Rate/Sqft',
      'Total Amount'
    ];
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    // Table Rows
    for (final row in rows) {
      sheet.appendRow([
        TextCellValue(row['description'] ?? ''),
        DoubleCellValue(_toDouble(row['length'])),
        DoubleCellValue(_toDouble(row['width'])),
        DoubleCellValue(_toDouble(row['area'])),
        DoubleCellValue(_toDouble(row['perBox'])),
        DoubleCellValue(_toDouble(row['totalRequired'])),
        DoubleCellValue(_toDouble(row['boxes'])),
        DoubleCellValue(_toDouble(row['areaRequired'])),
        DoubleCellValue(_toDouble(row['ratePerSqft'])),
        DoubleCellValue(_toDouble(row['totalAmount'])),
      ]);
    }

    // Export
    final fileName =
        'FlooringEstimate_${summary['customer_name'].toString().replaceAll(' ', '_')}_V${summary['version'] ?? summary['estimateId']}.xlsx';
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

  //End

  void _fetchEstimate() {
    _estimateDetails = FlooringEstimateDatabaseHelper.getFlooringEstimateById(
        widget.estimateId, widget.flooringType);
  }

  void _deleteEstimate() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Estimate'),
        content: const Text('Are you sure you want to delete this estimate?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Delete'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success =
          await FlooringEstimateDatabaseHelper.deleteFlooringEstimate(
              widget.estimateId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Estimate deleted successfully')),
        );
        Navigator.of(context).pop(); // Go back after deletion
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Failed to delete estimate')),
        );
      }
    }
  }

  // 🛠️ Edit Estimate Logic
  void _editEstimate(Map<String, dynamic> estimate) async {
    final summary = estimate['summary'];
    final customerId = summary['customer_id'];

    final customerData =
        await FlooringEstimateDatabaseHelper.getCustomerById(customerId);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlooringEstimate(
          customerId: customerId,
          estimateId: summary['estimateId'],
          customerInfo: {
            'name': summary['customer_name'],
            'email': customerData['email'],
            'phone': customerData['phone'],
          },
          customerName: summary['customer_name'],
          customerEmail: customerData['email'] ?? 'Unknown',
          customerPhone: customerData['phone'] ?? 'Unknown',
          estimateData: estimate, // Full estimate data (summary + rows)
        ),
      ),
    );
    // Refresh after edit
    _fetchEstimate();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.flooringType} Estimate Details'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export to Excel',
            onPressed: () async {
              final estimate = await _estimateDetails;
              _exportToExcel(estimate);
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () async {
              final estimate = await _estimateDetails;
              _editEstimate(estimate);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete',
            onPressed: _deleteEstimate,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _estimateDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No estimate found.'));
          } else {
            final estimate = snapshot.data!;
            final summary = estimate['summary'];
            final rows = estimate['rows'] ?? [];

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estimate Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Table(
                      border: TableBorder.all(color: Colors.grey, width: 1),
                      defaultColumnWidth: const FixedColumnWidth(150),
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                          ),
                          children: const [
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Estimate ID',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Customer Name',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Installation Cost',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Foam Cost',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Transport Charges',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Total Amount',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Flooring Type',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text((summary['Id'] ?? '--').toString()),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(summary['customer_name'] ?? ''),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child:
                                  Text('₹${summary['installation_cost'] ?? 0}'),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('₹${summary['foam'] ?? 0}'),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child:
                                  Text('₹${summary['transport_charges'] ?? 0}'),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('₹${summary['totalAmount'] ?? 0}'),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(summary['flooringType']),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(thickness: 2, color: Colors.black54),
                  const SizedBox(height: 16),
                  const Text(
                    'Estimate Rows',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateColor.resolveWith(
                            (states) => Colors.grey.shade100),
                        columns: const [
                          DataColumn(label: Text('Description')),
                          DataColumn(label: Text('Length')),
                          DataColumn(label: Text('Width')),
                          DataColumn(label: Text('Area')),
                          DataColumn(label: Text('Per Box')),
                          DataColumn(label: Text('Total Required')),
                          DataColumn(label: Text('Boxes')),
                          DataColumn(label: Text('Area Required')),
                          DataColumn(label: Text('Rate/Sqft')),
                          DataColumn(label: Text('Total Amount')),
                        ],
                        rows: rows.map<DataRow>((row) {
                          return DataRow(
                            cells: [
                              DataCell(Text(row['description'] ?? '')),
                              DataCell(Text((row['length'] ?? 0).toString())),
                              DataCell(Text((row['width'] ?? 0).toString())),
                              DataCell(Text((row['area'] ?? 0).toString())),
                              DataCell(Text((row['perBox'] ?? 0).toString())),
                              DataCell(
                                  Text((row['totalRequired'] ?? 0).toString())),
                              DataCell(Text((row['boxes'] ?? 0).toString())),
                              DataCell(
                                  Text((row['areaRequired'] ?? 0).toString())),
                              DataCell(
                                  Text((row['ratePerSqft'] ?? 0).toString())),
                              DataCell(
                                  Text((row['totalAmount'] ?? 0).toString())),
                            ],
                          );
                        }).toList(),
                      ),
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
}
