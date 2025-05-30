// import 'dart:nativewrappers/_internal/vm/lib/typed_data_patch.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart'; // This is where PdfColor is defined
import '../../../services/customer_database_service.dart';
import '../models/estimate_row.dart';
import '../models/woodwork_estimate.dart';
import 'dart:js_interop';
import 'new_woodwork_estimate_page.dart';

// JS binding to URL
@JS('URL')
external JSURL get jsURL;

@JS()
@staticInterop
class JSURL {}

extension JSURLBindings on JSURL {
  external String createObjectURL(Blob blob);
  external void revokeObjectURL(String url);
}

// JS binding to Blob
@JS('Blob')
@staticInterop
class Blob {
  external factory Blob(JSArray parts);
}

// JS binding to Array
@JS('Array')
@staticInterop
class JSArray {
  external factory JSArray();
}

extension JSArrayExtension on JSArray {
  external void push(JSAny? value); // ✅ JSAny is valid interop type
}

// JS binding to document
@JS('document')
external JSDocument get document;

@JS()
@staticInterop
class JSDocument {}

extension JSDocumentExtension on JSDocument {
  external JSAnchorElement createElement(String tag); // tag: "a"
}

// JS AnchorElement
@JS()
@staticInterop
class JSAnchorElement {}

extension JSAnchorElementExtension on JSAnchorElement {
  external set href(String value);
  external set download(String value);
  external void click();
}

class WoodworkEstimateDetailPage extends StatefulWidget {
  final WoodworkEstimate estimate;
  const WoodworkEstimateDetailPage({super.key, required this.estimate});

  @override
  _WoodworkEstimateDetailPageState createState() =>
      _WoodworkEstimateDetailPageState();
}

class _WoodworkEstimateDetailPageState
    extends State<WoodworkEstimateDetailPage> {
  List<bool> _columnVisibility =
      List.generate(33, (index) => true); // Visibility state for 30 columns

  Map<String, dynamic>? _selectedCustomer;

  @override
  void initState() {
    super.initState();

    // Fetch customer data if customerId is available in the estimate
    if (widget.estimate.customerId != null) {
      print("Customer ID in estimate: ${widget.estimate.customerId}");
      _fetchCustomerData(widget.estimate.customerId!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Customer ID is missing in the estimate!')),
      );
    }
  }

  //export method

  void _downloadExcelWeb(Uint8List bytes, String fileName) {
    final array = JSArray();
    array.push(bytes.toJS); // ✅ Uint8List -> JSAny?

    final blob = Blob(array);
    final url = jsURL.createObjectURL(blob);

    final anchor = document.createElement('a');
    anchor.href = url;
    anchor.download = fileName;
    anchor.click();

    jsURL.revokeObjectURL(url);
  }

  void _exportToExcel() {
    final excel = Excel.createExcel();
    final sheet = excel['Woodwork Estimate'];

    // ---------------- HEADER SECTION ----------------
    sheet.appendRow([TextCellValue('Woodwork Estimate')]);
    sheet.appendRow([]); // Empty spacer

    sheet.appendRow([TextCellValue('Customer Info')]);
    sheet.appendRow([
      TextCellValue('Name'),
      TextCellValue(widget.estimate.customerName ?? 'N/A')
    ]);
    sheet.appendRow([
      TextCellValue('Email'),
      TextCellValue(widget.estimate.customerEmail ?? 'N/A')
    ]);
    sheet.appendRow([
      TextCellValue('Phone'),
      TextCellValue(widget.estimate.customerPhone ?? 'N/A')
    ]);

    sheet.appendRow([]); // Empty spacer

    // ---------------- TABLE HEADER ----------------
    sheet.appendRow([TextCellValue('Estimate Details')]);
    final headers = _getVisibleColumns();
    sheet.appendRow(
      headers.map<CellValue>((val) => TextCellValue(val)).toList(),
    );

    // ---------------- TABLE BODY ----------------
    for (final row in widget.estimate.rows) {
      final rowData = _getVisibleData(row);
      if (rowData.isEmpty) continue;

      final cells = rowData.map<CellValue>((val) {
        final parsed =
            double.tryParse(val.replaceAll(',', '').replaceAll('₹', ''));
        return parsed != null ? DoubleCellValue(parsed) : TextCellValue(val);
      }).toList();

      sheet.appendRow(cells);
    }

    // ---------------- FOOTER TOTALS ----------------
    sheet.appendRow([]); // Spacer
    sheet.appendRow([TextCellValue('Total Summary')]);

    sheet.appendRow([
      TextCellValue('Total Amount 1'),
      DoubleCellValue(widget.estimate.totalAmount)
    ]);
    sheet.appendRow([
      TextCellValue('Discounted Total 1'),
      DoubleCellValue(
          widget.estimate.totalAmount * (1 - widget.estimate.discount / 100))
    ]);

    sheet.appendRow([
      TextCellValue('Total Amount 2'),
      DoubleCellValue(widget.estimate.totalAmount2)
    ]);
    sheet.appendRow([
      TextCellValue('Discounted Total 2'),
      DoubleCellValue(
          widget.estimate.totalAmount2 * (1 - widget.estimate.discount / 100))
    ]);

    sheet.appendRow([
      TextCellValue('Total Amount 3'),
      DoubleCellValue(widget.estimate.totalAmount3)
    ]);
    sheet.appendRow([
      TextCellValue('Discounted Total 3'),
      DoubleCellValue(
          widget.estimate.totalAmount3 * (1 - widget.estimate.discount / 100))
    ]);

    // ---------------- EXPORT ----------------
    final bytes = excel.encode();
    if (bytes != null) {
      _downloadExcelWeb(Uint8List.fromList(bytes),
          "Woodwork_Estimate_${widget.estimate.id}.xlsx");
    }
  }

  //
  Future<void> _fetchCustomerData(int customerId) async {
    try {
      final customerData =
          await CustomerDatabaseService().fetchCustomerById(customerId);
      setState(() {
        _selectedCustomer = customerData; // Store customer data
      });
      print("Fetched Customer: $_selectedCustomer");
    } catch (e) {
      print("Error fetching customer: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Estimate ${widget.estimate.id} Details'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_on),
            tooltip: "Export to Excel",
            onPressed: _exportToExcel,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showColumnToggleDialog, // Show the column toggle dialog
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed:
                _printEstimate, // Print the estimate with selected columns
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed:
                _exportToPDF, // Export the estimate to PDF with selected columns
          ),
          IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                // Ensure that _selectedCustomer is not null before accessing its properties
                if (_selectedCustomer == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('No customer data available!')),
                  );
                  return; // Stop the navigation if customer data is missing
                }
                // Print customer details before navigating
                print(
                    "Navigating to NewWoodworkEstimatePage with customer: $_selectedCustomer");
                // Extract customer data safely from _selectedCustomer
                try {
                  // Fetch the customer data by customerId
                  // Now you can navigate and pass the customer data
                  final updatedEstimate = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NewWoodworkEstimatePage(
                        estimateId: widget.estimate.id,
                        customerId: _selectedCustomer!['id'],
                        customerName: _selectedCustomer!['name'],
                        customerEmail: _selectedCustomer!['email'],
                        customerPhone: _selectedCustomer!['phone'],
                      ),
                    ),
                  );

                  // After returning from the edit page, update the state if the estimate was modified
                  if (updatedEstimate != null) {
                    setState(() {
                      widget.estimate.id = updatedEstimate;
                    });
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Failed to fetch customer data: $e')),
                  );
                }
              })
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical, // Enable vertical scrolling
                child: DataTable(
                  columnSpacing: 16.0,
                  columns: _buildColumns(),
                  rows: _buildRows(),
                ),
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  List<DataColumn> _buildColumns() {
    return [
      if (_columnVisibility[0]) const DataColumn(label: Text('S.no')),
      if (_columnVisibility[1]) const DataColumn(label: Text('Room')),
      if (_columnVisibility[2]) const DataColumn(label: Text('Unit')),
      if (_columnVisibility[3]) const DataColumn(label: Text('Description')),
      if (_columnVisibility[4]) const DataColumn(label: Text('Width Input')),
      if (_columnVisibility[5]) const DataColumn(label: Text('Height Input')),
      if (_columnVisibility[6]) const DataColumn(label: Text('Width (MM)')),
      if (_columnVisibility[7]) const DataColumn(label: Text('Height (MM)')),
      if (_columnVisibility[8]) const DataColumn(label: Text('Width (Feet)')),
      if (_columnVisibility[9]) const DataColumn(label: Text('Height (Feet)')),
      if (_columnVisibility[10]) const DataColumn(label: Text('Square Feet')),
      if (_columnVisibility[11]) const DataColumn(label: Text('Quantity')),
      if (_columnVisibility[12]) const DataColumn(label: Text('Finish Type 1')),
      if (_columnVisibility[13]) const DataColumn(label: Text('Rate 1')),
      if (_columnVisibility[14]) const DataColumn(label: Text('Amount 1')),
      if (_columnVisibility[15]) const DataColumn(label: Text('Finish Type 2')),
      if (_columnVisibility[16]) const DataColumn(label: Text('Rate 2')),
      if (_columnVisibility[17]) const DataColumn(label: Text('Amount 2')),
      if (_columnVisibility[18]) const DataColumn(label: Text('Finish Type 3')),
      if (_columnVisibility[19]) const DataColumn(label: Text('Rate 3')),
      if (_columnVisibility[20]) const DataColumn(label: Text('Amount 3')),
      if (_columnVisibility[21]) const DataColumn(label: Text('Side Panel 1')),
      if (_columnVisibility[22]) const DataColumn(label: Text('Side Rate 1')),
      if (_columnVisibility[23])
        const DataColumn(label: Text('Side Quantity 1')),
      if (_columnVisibility[24]) const DataColumn(label: Text('Side Amount 1')),
      if (_columnVisibility[25]) const DataColumn(label: Text('Side Panel 2')),
      if (_columnVisibility[26]) const DataColumn(label: Text('Side Rate 2')),
      if (_columnVisibility[27])
        const DataColumn(label: Text('Side Quantity 2')),
      if (_columnVisibility[28]) const DataColumn(label: Text('Side Amount 2')),
      if (_columnVisibility[29]) const DataColumn(label: Text('Side Panel 3')),
      if (_columnVisibility[30]) const DataColumn(label: Text('Side Rate 3')),
      if (_columnVisibility[31])
        const DataColumn(label: Text('Side Quantity 3')),
      if (_columnVisibility[32]) const DataColumn(label: Text('Side Amount 3')),
    ];
  }

  List<DataRow> _buildRows() {
    return widget.estimate.rows.map((row) {
      return DataRow(cells: [
        if (_columnVisibility[0])
          DataCell(
              Text((row.sNo ?? 0).toString())), // Use default value if null
        if (_columnVisibility[1]) DataCell(Text(row.room ?? 'N/A')),

        if (_columnVisibility[2])
          DataCell(Text(row.selectedUnit ?? 'N/A')), // Default 'N/A' if null
        if (_columnVisibility[3])
          DataCell(Text(row.descriptionController.text.isNotEmpty
              ? row.descriptionController.text
              : 'N/A')), // Default 'N/A' if empty
        if (_columnVisibility[4])
          DataCell(Text('${row.widthInput ?? 0}')), // Default 0 if null
        if (_columnVisibility[5])
          DataCell(Text('${row.heightInput ?? 0}')), // Default 0 if null
        if (_columnVisibility[6])
          DataCell(Text('${row.widthMM ?? 0}')), // Default 0 if null
        if (_columnVisibility[7])
          DataCell(Text('${row.heightMM ?? 0}')), // Default 0 if null
        if (_columnVisibility[8])
          DataCell(Text(
              (row.widthInFeet ?? 0).toStringAsFixed(2))), // Default 0 if null
        if (_columnVisibility[9])
          DataCell(Text(
              (row.heightInFeet ?? 0).toStringAsFixed(2))), // Default 0 if null
        if (_columnVisibility[10])
          DataCell(Text(
              (row.squareFeet ?? 0).toStringAsFixed(2))), // Default 0 if null
        if (_columnVisibility[11])
          DataCell(Text('${row.quantity}')), // Default 0 if null
        if (_columnVisibility[12])
          DataCell(Text(row.selectedFinish ?? 'N/A')), // Default 'N/A' if null
        if (_columnVisibility[13])
          DataCell(Text(
              '₹${(row.selectedFinishRate ?? 0).toStringAsFixed(2)}')), // Default 0 if null
        if (_columnVisibility[14])
          DataCell(Text(
              '₹${(row.baseAmount ?? 0).toStringAsFixed(2)}')), // Default 0 if null
        if (_columnVisibility[15])
          DataCell(
              Text(row.selectedSecondFinish ?? 'N/A')), // Default 'N/A' if null
        if (_columnVisibility[16])
          DataCell(Text(
              '₹${(row.selectedFinishRate2 ?? 0).toStringAsFixed(2)}')), // Default 0 if null
        if (_columnVisibility[17])
          DataCell(Text(
              '₹${(row.baseSecondAmount ?? 0).toStringAsFixed(2)}')), // Default 0 if null
        if (_columnVisibility[18])
          DataCell(
              Text(row.selectedThirdFinish ?? 'N/A')), // Default 'N/A' if null
        if (_columnVisibility[19])
          DataCell(Text(
              '₹${(row.selectedFinishRate3 ?? 0).toStringAsFixed(2)}')), // Default 0 if null
        if (_columnVisibility[20])
          DataCell(Text(
              '₹${(row.baseThirdAmount ?? 0).toStringAsFixed(2)}')), // Default 0 if null
        if (_columnVisibility[21])
          DataCell(
              Text(row.selectedSidePanel1 ?? 'N/A')), // Default 'N/A' if null
        if (_columnVisibility[22])
          DataCell(Text(
              '₹${(row.sidePanelRate1 ?? 0).toStringAsFixed(2)}')), // Default 0 if null
        if (_columnVisibility[23])
          DataCell(Text('${row.sidePanelQuantity1 ?? 0}')), // Default 0 if null
        if (_columnVisibility[24])
          DataCell(Text(
              '₹${(row.sidePanelAmount1 ?? 0).toStringAsFixed(2)}')), // Default 0 if null
        if (_columnVisibility[25])
          DataCell(
              Text(row.selectedSidePanel2 ?? 'N/A')), // Default 'N/A' if null
        if (_columnVisibility[26])
          DataCell(Text(
              '₹${(row.sidePanelRate2 ?? 0).toStringAsFixed(2)}')), // Default 0 if null
        if (_columnVisibility[27])
          DataCell(Text('${row.sidePanelQuantity2 ?? 0}')), // Default 0 if null
        if (_columnVisibility[28])
          DataCell(Text(
              '₹${(row.sidePanelAmount2 ?? 0).toStringAsFixed(2)}')), // Default 0 if null
        if (_columnVisibility[29])
          DataCell(
              Text(row.selectedSidePanel3 ?? 'N/A')), // Default 'N/A' if null
        if (_columnVisibility[30])
          DataCell(Text(
              '₹${(row.sidePanelRate3 ?? 0).toStringAsFixed(2)}')), // Default 0 if null
        if (_columnVisibility[31])
          DataCell(Text('${row.sidePanelQuantity3 ?? 0}')), // Default 0 if null
        if (_columnVisibility[32])
          DataCell(Text(
              '₹${(row.sidePanelAmount3 ?? 0).toStringAsFixed(2)}')), // Default 0 if null
      ]);
    }).toList();
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            children: [
              Text(
                'Total Amount 1: ₹${widget.estimate.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.orange),
              ),
              Text(
                'Discounted Total 1: ₹${(widget.estimate.totalAmount * (1 - widget.estimate.discount / 100)).toStringAsFixed(2)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                'Total Amount 2: ₹${widget.estimate.totalAmount2.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.orange),
              ),
              Text(
                'Discounted Total 2: ₹${(widget.estimate.totalAmount2 * (1 - widget.estimate.discount / 100)).toStringAsFixed(2)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                'Total Amount 3: ₹${widget.estimate.totalAmount3.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.orange),
              ),
              Text(
                'Discounted Total 3: ₹${(widget.estimate.totalAmount3 * (1 - widget.estimate.discount / 100)).toStringAsFixed(2)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Show dialog to toggle column visibility
  void _showColumnToggleDialog() {
    showDialog(
      context: context,
      builder: (context) {
        // Create a copy of the visibility state to work with inside the dialog
        List<bool> tempColumnVisibility = List.from(_columnVisibility);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Toggle Columns'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(tempColumnVisibility.length, (index) {
                    return Row(
                      children: [
                        Checkbox(
                          value: tempColumnVisibility[index],
                          onChanged: (value) {
                            setDialogState(() {
                              tempColumnVisibility[index] = value!;
                            });
                          },
                        ),
                        Expanded(
                          child: Text(_getColumnName(index)),
                        ),
                      ],
                    );
                  }),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Update the main state with the modified values
                    setState(() {
                      _columnVisibility = List.from(tempColumnVisibility);
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _printEstimate() async {
    final doc = await _generatePdf(); // Generate the PDF document
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async {
      return doc.save(); // Return the PDF bytes for printing
    });
  }

  void _exportToPDF() async {
    final doc = await _generatePdf(); // Generate the PDF document
    final outputBytes = await doc.save(); // Get PDF bytes
    await Printing.sharePdf(
        bytes: outputBytes,
        filename: "estimate_${widget.estimate.id}.pdf"); // Share PDF
  }

  Future<pw.Document> _generatePdf() async {
    try {
      final pdf = pw.Document();

      // Load the logo image from assets
      final ByteData bytes =
          await rootBundle.load('assets/Black logo on White-01.jpg');
      final List<int> imageBytes = bytes.buffer.asUint8List();
      final Uint8List uint8ImageBytes = Uint8List.fromList(imageBytes);
      final pw.MemoryImage logo = pw.MemoryImage(uint8ImageBytes);

      pdf.addPage(pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              // Add Logo
              pw.Padding(
                padding: const pw.EdgeInsets.all(8.0),
                child: pw.Image(logo, width: 100, height: 100),
              ),

              // Customer Info
              pw.Padding(
                padding: const pw.EdgeInsets.all(8.0),
                child: pw.Text('Customer Information',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 10)),
              ),
              pw.Row(
                children: [
                  pw.Text('Customer Name: ',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text(widget.estimate.customerName ?? 'N/A'),
                ],
              ),
              pw.Row(
                children: [
                  pw.Text('Customer ID: ',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text(widget.estimate.customerId.toString()),
                ],
              ),
              pw.Row(
                children: [
                  pw.Text('Customer Email: ',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text(widget.estimate.customerEmail ?? 'N/A'),
                ],
              ),
              pw.Row(
                children: [
                  pw.Text('Customer Mobile: ',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text(widget.estimate.customerPhone ?? 'N/A'),
                ],
              ),
              pw.SizedBox(height: 20),
              // Add other customer info...
              pw.Padding(
                padding: const pw.EdgeInsets.all(8.0),
                child: pw.Text('Wood-Work Information',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 10)),
              ),
              // Add table if rows exist
              if (widget.estimate.rows.isNotEmpty)
                pw.Table(
                  border: pw.TableBorder.all(
                      width: 0, color: const PdfColor.fromInt(0xFF4A4947)),
                  children: [
                    // Header
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                          color: PdfColor.fromInt(0xFFC0EBA6)),
                      children: _getVisibleColumns().map((columnName) {
                        return pw.Padding(
                          padding: const pw.EdgeInsets.all(4.0),
                          child: pw.Text(
                            columnName,
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 8),
                            textAlign: pw.TextAlign.center,
                          ),
                        );
                      }).toList(),
                    ),
                    // Data Rows
                    ...widget.estimate.rows.map((row) {
                      return pw.TableRow(
                        children: _getVisibleData(row).map((cellData) {
                          return pw.Padding(
                            padding: const pw.EdgeInsets.all(4.0),
                            child: pw.Text(
                              cellData,
                              style: const pw.TextStyle(fontSize: 6),
                              textAlign: pw.TextAlign.center,
                            ),
                          );
                        }).toList(),
                      );
                    }),
                  ],
                ),
            ],
          );
        },
      ));

      return pdf;
    } catch (e) {
      debugPrint("Error generating PDF: $e");
      rethrow;
    }
  }

// Helper method to get visible column names
  List<String> _getVisibleColumns() {
    final columnNames = [
      'S.NO',
      'Room',
      'Unit',
      'Description',
      'Width',
      'Height',
      'Width MM',
      'Height MM',
      'Width Feet',
      'Height Feet',
      'Square Feet',
      'Quantity',
      'Finish Type',
      'Rate',
      'Amount',
      'Second Finish',
      'Second Rate',
      'Second Amount',
      'Third Finish',
      'Third Rate',
      'Third Amount'
    ];
    return columnNames
        .asMap()
        .entries
        .where((entry) {
          return _columnVisibility[entry.key];
        })
        .map((entry) => entry.value)
        .toList();
  }

// Helper method to get visible row data
  List<String> _getVisibleData(EstimateRow row) {
    final rowData = [
      row.sNo.toString(),
      row.room ?? 'N/A',
      row.selectedUnit ?? 'N/A',
      row.descriptionController.text,
      row.widthInput ?? '0',
      row.heightInput ?? '0',
      row.widthMM.toStringAsFixed(0),
      row.heightMM.toStringAsFixed(0),
      row.widthInFeet.toStringAsFixed(2),
      row.heightInFeet.toStringAsFixed(2),
      row.squareFeet.toStringAsFixed(2),
      row.quantity.toString(),
      row.selectedFinish ?? 'N/A',
      (row.selectedFinishRate.toStringAsFixed(2)),
      (row.amount.toStringAsFixed(0)),
      row.selectedSecondFinish ?? 'N/A',
      (row.selectedFinishRate2.toStringAsFixed(2)),
      (row.secondAmount.toStringAsFixed(2)),
      row.selectedThirdFinish ?? 'N/A',
      (row.selectedFinishRate3.toStringAsFixed(2)),
      (row.thirdAmount.toStringAsFixed(2)),
    ];
    return rowData
        .asMap()
        .entries
        .where((entry) {
          return _columnVisibility[entry.key];
        })
        .map((entry) => entry.value)
        .toList();
  }

  // Get column name by index
  String _getColumnName(int index) {
    switch (index) {
      case 0:
        return 'S.no';
      case 1:
        return 'Unit';
      case 2:
        return 'Description';
      case 3:
        return 'Width Input';
      case 4:
        return 'Width Input';
      case 5:
        return 'Width (MM)';
      case 6:
        return 'Height (MM)';
      case 7:
        return 'Width (Feet)';
      case 8:
        return 'Height (Feet)';
      case 9:
        return 'Square Feet';
      case 10:
        return 'Quantity';
      case 11:
        return 'Finish Type 1';
      case 12:
        return 'Rate 1';
      case 13:
        return 'Amount 1';
      case 14:
        return 'Finish Type 2';
      case 15:
        return 'Rate 2';
      case 16:
        return 'Amount 2';
      case 17:
        return 'Finish Type 3';
      case 18:
        return 'Rate 3';
      case 19:
        return 'Amount 3';
      case 20:
        return 'Side Panel 1';
      case 21:
        return 'Side Rate 1';
      case 22:
        return 'Side Quantity 1';
      case 23:
        return 'Side Amount 1';
      case 24:
        return 'Side Panel 2';
      case 25:
        return 'Side Rate 2';
      case 26:
        return 'Side Quantity 2';
      case 27:
        return 'Side Amount 2';
      case 28:
        return 'Side Panel 3';
      case 29:
        return 'Side Rate 3';
      case 30:
        return 'Side Quantity 3';
      case 31:
        return 'Side Amount 3';
      default:
        return 'Unknown';
    }
  }
}
