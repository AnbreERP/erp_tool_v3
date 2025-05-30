import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../database/core_woodwork_data.dart';

class AddWoodenItemPartPage extends StatefulWidget {
  final int woodenItemId;

  const AddWoodenItemPartPage({super.key, required this.woodenItemId});

  @override
  _AddWoodenItemPartPageState createState() => _AddWoodenItemPartPageState();
}

const String baseUrl = "http://127.0.0.1:4000/api/core-woodwork";

class _AddWoodenItemPartPageState extends State<AddWoodenItemPartPage> {
  final _formKey = GlobalKey<FormState>();
  final List<Map<String, dynamic>> _rows = [];
  List<String> _tableTypes = [];
  String? _selectedTableType; // Default to null before API fetch
  bool _isTableTypeSelected = false;

  @override
  void initState() {
    super.initState();
    _fetchTableTypes();
    _fetchWoodworkFinishes();
    _fetchWoodenItem();
    if (widget.woodenItemId != 0) {
      _fetchWoodenItem();
    }
  }

  @override
  void dispose() {
    for (var row in _rows) {
      row['controllers'].values.forEach((controller) => controller.dispose());
    }
    super.dispose();
  }

  String woodenItemName = '';

  Future<void> _fetchWoodenItem() async {
    try {
      print("🔍 Fetching wooden item with ID: ${widget.woodenItemId}");

      final woodenItem =
          await CoreWoodworkDatabase.getWoodenItemById(widget.woodenItemId);

      print("✅ Wooden Item Fetched: $woodenItem");
      print("🔢 Wooden Item ID: ${widget.woodenItemId}");
    } catch (e) {
      print("❌ Error fetching wooden item: $e");
    }
  }

  /// Fetch dynamic table types from API.
  Future<void> _fetchTableTypes() async {
    try {
      print("📡 Fetching table types from API...");

      final response = await http.get(
        Uri.parse("$baseUrl/table-types"), // Ensure this matches the API
      );

      print("📩 Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> types = json.decode(response.body);
        setState(() {
          _tableTypes = List<String>.from(types);
          _selectedTableType = _tableTypes.isNotEmpty
              ? _tableTypes[0]
              : null; // Default selection
          _addRow(); // Initialize a row based on the first type
        });
      } else {
        throw Exception(
            "Failed to fetch table types. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching table types: $e");
    }
  }

  /// Fetch woodwork finishes from API.
  Future<void> _fetchWoodworkFinishes() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/woodwork-finishes'));

      if (response.statusCode == 200) {
        json.decode(response.body);
        setState(() {});
      } else {
        print('❌ Failed to load woodwork finishes: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching woodwork finishes: $e');
    }
  }

  /// Add a new row based on the selected table type.
  void _addRow() {
    if (_selectedTableType == null) return;

    Map<String, TextEditingController> controllers;

    if (_selectedTableType == 'wooden') {
      controllers = {
        'description': TextEditingController(),
        'type': TextEditingController(),
        'widthMm': TextEditingController(),
        'heightMm': TextEditingController(),
        'widthFeet': TextEditingController(),
        'heightFeet': TextEditingController(),
        'squareFeet': TextEditingController(),
        'quantity': TextEditingController(),
        'rate': TextEditingController(),
        'amount': TextEditingController(),
      };
    } else if (_selectedTableType == 'accessory') {
      controllers = {
        'description': TextEditingController(),
        'item_code': TextEditingController(),
        'mrp': TextEditingController(),
        'net_amount': TextEditingController(),
        'labour': TextEditingController(),
      };
    } else if (_selectedTableType == 'sliding') {
      controllers = {
        'description': TextEditingController(),
        'rate': TextEditingController(),
        'quantity': TextEditingController(),
        'mrp': TextEditingController(),
        'amount': TextEditingController(),
      };
    } else {
      controllers = {};
    }

    setState(() {
      _rows.add({'controllers': controllers, 'selectedFinish': null});
    });
  }

  /// Save all rows to the database.
  Future<void> _saveParts() async {
    try {
      if (_rows.isEmpty) {
        print("⚠️ No rows to save.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No data to save!")),
        );
        return;
      }

      // Convert each row into a structured JSON object
      List<Map<String, dynamic>> partsData = _rows.map((row) {
        final controllers =
            row['controllers'] as Map<String, TextEditingController>;

        return {
          'wooden_item_id': widget.woodenItemId, // ✅ Associate with wooden item
          'woodwork_finish_id': row['selectedFinish'],
          'table_type': _selectedTableType,
          'description': controllers['description']?.text ?? '',
          'type': controllers['type']?.text ?? 'No Type',
          'widthMm':
              double.tryParse(controllers['widthMm']?.text ?? '0') ?? 0.0,
          'heightMm':
              double.tryParse(controllers['heightMm']?.text ?? '0') ?? 0.0,
          'widthFeet':
              double.tryParse(controllers['widthFeet']?.text ?? '0') ?? 0.0,
          'heightFeet':
              double.tryParse(controllers['heightFeet']?.text ?? '0') ?? 0.0,
          'squareFeet':
              double.tryParse(controllers['squareFeet']?.text ?? '0') ?? 0.0,
          'quantity': int.tryParse(controllers['quantity']?.text ?? '0') ?? 0,
          'rate': double.tryParse(controllers['rate']?.text ?? '0') ?? 0.0,
          'amount': double.tryParse(controllers['amount']?.text ?? '0') ?? 0.0,
          'item_code': controllers['item_code']?.text ?? '',
          'mrp': double.tryParse(controllers['mrp']?.text ?? '0') ?? 0.0,
          'net_amount':
              double.tryParse(controllers['net_amount']?.text ?? '0') ?? 0.0,
          'labour': double.tryParse(controllers['labour']?.text ?? '0') ?? 0.0,
        };
      }).toList();

      print("📤 Sending parts data: ${jsonEncode({'parts': partsData})}");

      // Send API request
      final response = await http.post(
        Uri.parse(
            'http://127.0.0.1:4000/api/core-woodwork/save-parts'), // Update with correct endpoint
        headers: {"Content-Type": "application/json"},
        body: json.encode({'parts': partsData}),
      );

      print("📩 Response Status: ${response.statusCode}");
      print("📨 Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Data saved successfully!")),
        );
        setState(() {
          _rows.clear();
          _addRow(); // Reset table with one row
        });
      } else {
        throw Exception(
            "Failed to save data. Server returned ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error saving data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save data.")),
      );
    }
  }

  /// Remove a row.
  void _removeRow(int index) {
    setState(() {
      _rows.removeAt(index);
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Wooden Item Parts')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Select Table Type:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    hint: const Text('Select Table Type'),
                    value: _selectedTableType,
                    onChanged: (value) {
                      setState(() {
                        _selectedTableType = value!;
                        _rows.clear();

                        _addRow();
                        _isTableTypeSelected = true;
                      });
                    },
                    items: _tableTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                  ),
                  const Spacer(),
                  if (_isTableTypeSelected)
                    ElevatedButton(
                      onPressed: _addRow,
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                ],
              ),
              if (_isTableTypeSelected) ...[
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 12.0,
                      headingRowColor: WidgetStateColor.resolveWith(
                          (states) => Colors.grey[200]!),
                      columns: _buildTableColumns(),
                      rows: _rows.asMap().entries.map((entry) {
                        final index = entry.key;
                        final row = entry.value;
                        final controllers = row['controllers']
                            as Map<String, TextEditingController>;

                        return DataRow(
                            cells:
                                _buildTableRowCells(index, controllers, row));
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton.icon(
                    onPressed: _saveParts,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Parts'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<DataColumn> _buildTableColumns() {
    List<DataColumn> columns = [const DataColumn(label: Text('S.NO'))];

    if (_selectedTableType == 'wooden') {
      columns.addAll([
        const DataColumn(label: Text('Description')),
        const DataColumn(label: Text('Type')),
        const DataColumn(label: Text('Width (mm)')),
        const DataColumn(label: Text('Height (mm)')),
        const DataColumn(label: Text('Quantity')),
        const DataColumn(label: Text('Rate')),
        const DataColumn(label: Text('Amount')),
        const DataColumn(label: Text('Actions')),
      ]);
    } else if (_selectedTableType == 'accessory') {
      columns.addAll([
        const DataColumn(label: Text('Description')),
        const DataColumn(label: Text('Item Code')),
        const DataColumn(label: Text('MRP')),
        const DataColumn(label: Text('Net Amount')),
        const DataColumn(label: Text('Labour')),
        const DataColumn(label: Text('Actions')),
      ]);
    } else if (_selectedTableType == 'sliding') {
      columns.addAll([
        const DataColumn(label: Text('Description')),
        const DataColumn(label: Text('Rate')),
        const DataColumn(label: Text('Quantity')),
        const DataColumn(label: Text('MRP')),
        const DataColumn(label: Text('Amount')),
        const DataColumn(label: Text('Actions')),
      ]);
    }

    return columns;
  }

  List<DataCell> _buildTableRowCells(
      int index,
      Map<String, TextEditingController> controllers,
      Map<String, dynamic> row) {
    List<DataCell> cells = [DataCell(Text((index + 1).toString()))];

    if (_selectedTableType == 'wooden') {
      cells.addAll([
        DataCell(TextField(controller: controllers['description'])),
        DataCell(TextField(controller: controllers['type'])),
        DataCell(TextField(controller: controllers['widthMm'])),
        DataCell(TextField(controller: controllers['heightMm'])),
        DataCell(TextField(controller: controllers['quantity'])),
        DataCell(TextField(controller: controllers['rate'])),
        DataCell(TextField(controller: controllers['amount'])),
        DataCell(
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _removeRow(index),
          ),
        ),
      ]);
    } else if (_selectedTableType == 'accessory') {
      cells.addAll([
        DataCell(TextField(controller: controllers['description'])),
        DataCell(TextField(controller: controllers['item_code'])),
        DataCell(TextField(controller: controllers['mrp'])),
        DataCell(TextField(controller: controllers['net_amount'])),
        DataCell(TextField(controller: controllers['labour'])),
        DataCell(
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _removeRow(index),
          ),
        ),
      ]);
    } else if (_selectedTableType == 'sliding') {
      cells.addAll([
        DataCell(TextField(controller: controllers['description'])),
        DataCell(TextField(controller: controllers['rate'])),
        DataCell(TextField(controller: controllers['quantity'])),
        DataCell(TextField(controller: controllers['mrp'])),
        DataCell(TextField(controller: controllers['amount'])),
        DataCell(
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _removeRow(index),
          ),
        ),
      ]);
    }

    return cells;
  }
}
