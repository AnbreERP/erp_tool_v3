import 'package:flutter/material.dart';
import 'package:erp_tool/database/e_database_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'electrical_estimate_page.dart';
import 'package:excel/excel.dart';
import 'dart:js_interop';
import 'package:flutter/services.dart'; // For Uint8List

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

class ElectricalEstimatesListPage extends StatefulWidget {
  const ElectricalEstimatesListPage({super.key});

  @override
  _ElectricalEstimatesListPageState createState() =>
      _ElectricalEstimatesListPageState();
}

class _ElectricalEstimatesListPageState
    extends State<ElectricalEstimatesListPage> {
  late Future<List<Map<String, dynamic>>> _electricalEstimates;

  @override
  void initState() {
    super.initState();
    _fetchEstimates();
  }

  Future<void> _fetchEstimates() async {
    setState(() {
      _electricalEstimates = EDatabaseHelper.getEstimates()
          .then((data) => data.cast<Map<String, dynamic>>());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Electrical Estimates'),
        backgroundColor: Colors.orange.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: "Export All Estimates to Excel",
            onPressed: () async {
              final data = await EDatabaseHelper.getEstimates();
              _exportEstimatesToExcel(data);
            },
          )
        ],
      ),
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _fetchEstimates,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _electricalEstimates,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return _buildErrorUI();
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildNoDataUI();
            } else {
              return _buildEstimatesTable(snapshot.data!);
            }
          },
        ),
      ),
    );
  }

//Export Excel All estimate
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

  void _exportEstimatesToExcel(List<Map<String, dynamic>> estimates) {
    final excel = Excel.createExcel();
    final sheet = excel['All Estimates'];

    // Title
    sheet.appendRow([TextCellValue('All Electrical Estimates')]);
    sheet.appendRow([
      TextCellValue('Exported on'),
      TextCellValue(DateTime.now().toString())
    ]);
    sheet.appendRow([]); // Spacer

    // Header
    final headers = [
      'Estimate ID',
      'Customer ID',
      'Customer Name',
      'Hike (%)',
      'Transport (₹)',
      'Grand Total (₹)',
      'Version'
    ];
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    // Rows
    for (final row in estimates) {
      final values = [
        row['id']?.toString() ?? '',
        row['customerId']?.toString() ?? '',
        row['customerName'] ?? '',
        row['hike']?.toString() ?? '0',
        row['transport']?.toString() ?? '0',
        row['grandTotal']?.toString() ?? '0',
        row['version']?.toString() ?? 'N/A',
      ];

      final excelRow = values.map<CellValue>((val) {
        final parsed =
            double.tryParse(val.replaceAll(',', '').replaceAll('₹', ''));
        return parsed != null ? DoubleCellValue(parsed) : TextCellValue(val);
      }).toList();

      sheet.appendRow(excelRow);
    }

    // Footer - Total Estimates Count
    sheet.appendRow([]);
    sheet.appendRow([
      TextCellValue('Total Estimates'),
      DoubleCellValue(estimates.length.toDouble())
    ]);

    // Export
    final bytes = excel.encode();
    if (bytes != null) {
      final date = DateTime.now().toIso8601String().substring(0, 10);
      final fileName = "AllElectricalEstimates_$date.xlsx";
      _downloadExcelWeb(Uint8List.fromList(bytes), fileName);
    }
  }

  //end
  Widget _buildEstimatesTable(List<Map<String, dynamic>> estimates) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Estimate ID')),
            DataColumn(label: Text('Customer ID')),
            DataColumn(label: Text('Customer Name')),
            DataColumn(label: Text('Hike')),
            DataColumn(label: Text('Transport')),
            DataColumn(label: Text('Grand Total')),
            DataColumn(label: Text('Version')),
          ],
          rows: estimates.map((estimate) {
            return DataRow(
              cells: [
                DataCell(Text(estimate['id']?.toString() ?? '')),
                DataCell(Text(estimate['customerId']?.toString() ?? '')),
                DataCell(Text(estimate['customerName']?.toString() ?? '')),
                DataCell(Text(estimate['hike']?.toString() ?? '0%')),
                DataCell(Text(estimate['transport']?.toString() ?? '0')),
                DataCell(Text(estimate['grandTotal']?.toString() ?? '0')),
                DataCell(Text(estimate['version']?.toString() ?? 'N/A')),
              ],
              onSelectChanged: (selected) async {
                if (selected!) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ElectricalEstimateDetailsPage(
                          estimateId: estimate['id']),
                    ),
                  );
                  _fetchEstimates();
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNoDataUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 50, color: Colors.grey),
          const SizedBox(height: 10),
          const Text("No electrical estimates found.",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ElevatedButton(
              onPressed: _fetchEstimates, child: const Text("Refresh")),
        ],
      ),
    );
  }

  Widget _buildErrorUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Failed to load data. Please try again.",
              style: TextStyle(fontSize: 16, color: Colors.red)),
          const SizedBox(height: 10),
          ElevatedButton(
              onPressed: _fetchEstimates, child: const Text("Retry")),
        ],
      ),
    );
  }
}

class ElectricalEstimateDetailsPage extends StatefulWidget {
  final int estimateId;
  const ElectricalEstimateDetailsPage({required this.estimateId, super.key});

  @override
  _ElectricalEstimateDetailsPageState createState() =>
      _ElectricalEstimateDetailsPageState();
}

class _ElectricalEstimateDetailsPageState
    extends State<ElectricalEstimateDetailsPage> {
  Future<Map<String, dynamic>>? _estimateDetails;
  String? customerName, customerEmail, customerPhone;
  bool isLoading = true, hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchEstimateDetails();
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

  void _fetchEstimateDetails() {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    EDatabaseHelper.getEstimateById(widget.estimateId).then((estimate) {
      if (estimate.isNotEmpty && estimate.containsKey('estimate')) {
        setState(() {
          _estimateDetails = Future.value(
              estimate['estimate']); // ✅ Fix: Ensure correct parsing
          if (estimate.containsKey('rows')) {
            _estimateDetails = Future.value(
                {'estimate': estimate['estimate'], 'rows': estimate['rows']});
          }
          isLoading = false;
        });

        if (estimate['estimate'].containsKey('customerId')) {
          fetchCustomerInfo(estimate['estimate']['customerId']);
        }
      }
    }).catchError((error) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    });
  }

  Future<void> fetchCustomerInfo(int customerId) async {
    try {
      const String baseUrl = "http://127.0.0.1:4000/api";
      final response =
          await http.get(Uri.parse("$baseUrl/customers/$customerId"));

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          customerName = data['customerName'];
          customerEmail = data['customerEmail'];
          customerPhone = data['customerPhone'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        customerName = "Unknown";
        customerEmail = "N/A";
        customerPhone = "N/A";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estimate Details'),
        backgroundColor: Colors.orange.shade900,
        foregroundColor: Colors.white,
        actions: [
          ElevatedButton.icon(
            onPressed: () => _exportToExcel(),
            icon: const Icon(Icons.file_download),
            label: const Text("Export to Excel"),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _estimateDetails,
        builder: (context, snapshot) {
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (hasError || snapshot.hasError) return _buildErrorUI();
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildNoDataUI();
          }

          final data = snapshot.data!;
          final estimate = data['estimate'] ?? {};
          final rows = data['rows'] ?? [];

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildEstimateSummary(estimate),
              const SizedBox(height: 20),
              const Text('Estimate Rows:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildEstimateRowsTable(rows),
            ],
          );
        },
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

  void _exportToExcel() async {
    final excel = Excel.createExcel();
    final sheet = excel['Electrical Estimate'];

    // ✅ Safe way to fetch estimate and rows
    if (_estimateDetails == null) return;

    final data = await _estimateDetails!;
    if (data.isEmpty) return;

    final estimate = data['estimate'] ?? {};
    final rows = data['rows'] ?? [];

    // Header: Customer Info
    sheet.appendRow([TextCellValue('Electrical Estimate')]);
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
        [TextCellValue('Estimate ID'), TextCellValue("${widget.estimateId}")]);
    sheet.appendRow([
      TextCellValue('Version'),
      TextCellValue("${estimate['version'] ?? 'N/A'}")
    ]);
    sheet.appendRow([]);

    // Table header
    const headers = [
      'Floor',
      'Room',
      'Description',
      'Type',
      'Light Type',
      'Light Detail',
      'Quantity',
      'Material Rate',
      'Labour Rate',
      'Total Amount'
    ];
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    // Table rows
    for (final row in rows) {
      sheet.appendRow([
        TextCellValue(row['floor'] ?? ''),
        TextCellValue(row['room'] ?? ''),
        TextCellValue(row['description'] ?? ''),
        TextCellValue(row['type'] ?? ''),
        TextCellValue(row['lightType'] ?? ''),
        TextCellValue(row['lightDetails'] ?? ''),
        DoubleCellValue(_toDouble(row['quantity'])),
        DoubleCellValue(_toDouble(row['materialRate'])),
        DoubleCellValue(_toDouble(row['labourRate'])),
        DoubleCellValue(_toDouble(row['totalAmount'])),
      ]);
    }

    // Footer total (optional)
    sheet.appendRow([]);
    sheet.appendRow([
      TextCellValue('Grand Total'),
      DoubleCellValue(_toDouble(estimate['grandTotal']))
    ]);

    // File name with customer and version
    final customer = (customerName ?? 'Customer')
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(' ', '_');
    final version =
        estimate['version']?.toString() ?? widget.estimateId.toString();
    final fileName = 'ElectricalEstimate_${customer}_V$version.xlsx';

    final bytes = excel.encode();
    if (bytes != null) {
      _downloadExcelWeb(Uint8List.fromList(bytes), fileName);
    }
  }

  //End Export
  Widget _buildErrorUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Failed to load data. Please try again.",
              style: TextStyle(fontSize: 16, color: Colors.red)),
          const SizedBox(height: 10),
          ElevatedButton(
              onPressed: _fetchEstimateDetails, child: const Text("Retry")),
        ],
      ),
    );
  }

  Widget _buildNoDataUI() {
    return const Center(
      child: Text(
        "No estimate found.",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _editEstimate(Map<String, dynamic> estimate) async {
    final customerData =
        await EDatabaseHelper.getCustomerById(estimate['customerId']);

    final updatedEstimate = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ElectricalEstimatePage(
          customerId: estimate['customerId'],
          estimateId: estimate['id'],
          customerInfo: customerData,
          customerName: customerData['customerName'] ?? 'Unknown',
          customerEmail: customerData['customerEmail'] ?? 'Unknown',
          customerPhone: customerData['customerPhone'] ?? 'Unknown',
          estimateData: estimate,
        ),
      ),
    );

    if (updatedEstimate != null) {
      _fetchEstimateDetails(); // Refresh after editing
    }
  }

  void _confirmDelete(int estimateId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Delete"),
          content: const Text(
              "Are you sure you want to delete this estimate? This action cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Cancel
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteEstimate(estimateId);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _deleteEstimate(int estimateId) async {
    try {
      final String baseUrl = "http://127.0.0.1:4000/api/estimates/$estimateId";
      final response = await http.delete(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Estimate deleted successfully.")),
        );
        Navigator.pop(context, true); // Go back to the list and refresh
      } else {
        throw Exception("Failed to delete estimate");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error deleting estimate.")),
      );
    }
  }

  Widget _buildEstimateSummary(Map<String, dynamic> estimate) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Estimate ID: ${estimate['id'] ?? 'N/A'}",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
                "Customer: ${customerName ?? estimate['customerName'] ?? 'N/A'}",
                style: const TextStyle(fontSize: 16)),
            Text("Total Amount: ₹${estimate['grandTotal'] ?? 'N/A'}",
                style: const TextStyle(fontSize: 16)),
            Text("Hike: ${estimate['hike'] ?? 'N/A'}%",
                style: const TextStyle(fontSize: 16)),
            Text("Transport Charges: ₹${estimate['transport'] ?? 'N/A'}",
                style: const TextStyle(fontSize: 16)),
            Text("Version: ${estimate['version'] ?? 'N/A'}",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit"),
                  onPressed: () {
                    _editEstimate(estimate);
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  label: const Text("Delete"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    _confirmDelete(estimate['id']);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstimateRowsTable(List<dynamic> rows) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Floor')),
          DataColumn(label: Text('Room')),
          DataColumn(label: Text('Description')),
          DataColumn(label: Text('Type')),
          DataColumn(label: Text('Light Type')),
          DataColumn(label: Text('Light Detail')),
          DataColumn(label: Text('Quantity')),
          DataColumn(label: Text('Material Rate')),
          DataColumn(label: Text('Labour Rate')),
          DataColumn(label: Text('Total Amount')),
        ],
        rows: rows.map((row) {
          return DataRow(
            cells: [
              DataCell(Text(row['floor'] ?? '')),
              DataCell(Text(row['room'] ?? '')),
              DataCell(Text(row['description'] ?? '')),
              DataCell(Text(row['type'] ?? '')),
              DataCell(Text(row['lightType'] ?? '')),
              DataCell(Text(row['lightDetails'] ?? '')),
              DataCell(Text(row['quantity'].toString())),
              DataCell(Text("₹${row['materialRate'] ?? '0'}")),
              DataCell(Text("₹${row['labourRate'] ?? '0'}")),
              DataCell(Text("₹${row['totalAmount'] ?? '0'}")),
            ],
          );
        }).toList(),
      ),
    );
  }
}
