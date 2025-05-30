import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class WoodenItemPartsListPage extends StatefulWidget {
  final int woodenItemId;

  const WoodenItemPartsListPage({required this.woodenItemId, super.key});

  @override
  _WoodenItemPartsListPageState createState() =>
      _WoodenItemPartsListPageState();
}

class _WoodenItemPartsListPageState extends State<WoodenItemPartsListPage> {
  List<Map<String, dynamic>> _parts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWoodenItemParts();
  }

  /// Fetch parts for the specific wooden item from the database.
  Future<void> _fetchWoodenItemParts() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://127.0.0.1:4000/wooden-item-parts/${widget.woodenItemId}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> parts = json.decode(response.body);
        setState(() {
          _parts = List<Map<String, dynamic>>.from(parts);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch wooden item parts');
      }
    } catch (e) {
      print('Error fetching wooden item parts: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching data')),
      );
    }
  }

  /// Delete the part from the database and refresh the list.
  Future<void> _deletePart(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('http://127.0.0.1:4000/delete-part/$id'),
      );

      if (response.statusCode == 200) {
        _fetchWoodenItemParts(); // Refresh the list after deletion
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Part deleted successfully')),
        );
      } else {
        throw Exception('Failed to delete part');
      }
    } catch (e) {
      print('Error deleting part: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error deleting part')),
      );
    }
  }

  /// Confirm before deleting a part
  void _confirmDelete(int partId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Part'),
          content: const Text('Are you sure you want to delete this part?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deletePart(partId); // Call API instead of SQLite
                Navigator.of(context).pop(); // Close the dialog after deletion
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wooden Item Parts')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _parts.isEmpty
              ? const Center(child: Text('No parts available'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 12.0,
                    headingRowColor: WidgetStateColor.resolveWith(
                        (states) => Colors.grey[200]!),
                    columns: const [
                      DataColumn(label: Text('S.No')),
                      DataColumn(label: Text('Table Type')),
                      DataColumn(label: Text('Description')),
                      DataColumn(label: Text('Type')),
                      DataColumn(label: Text('Width (mm)')),
                      DataColumn(label: Text('Height (mm)')),
                      DataColumn(label: Text('Width (feet)')),
                      DataColumn(label: Text('Height (feet)')),
                      DataColumn(label: Text('Square Feet')),
                      DataColumn(label: Text('Quantity')),
                      DataColumn(label: Text('Rate')),
                      DataColumn(label: Text('Amount')),
                      DataColumn(label: Text('Item Code')),
                      DataColumn(label: Text('MRP')),
                      DataColumn(label: Text('Net Amount')),
                      DataColumn(label: Text('Labour')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: _parts.asMap().entries.map((entry) {
                      final index = entry.key;
                      final part = entry.value;

                      return DataRow(cells: [
                        DataCell(Text('${index + 1}')),
                        DataCell(Text(part['table_type'] ?? '')),
                        DataCell(Text(part['description'] ?? '')),
                        DataCell(Text(part['type'] ?? '')),
                        DataCell(Text('${part['widthMm'] ?? 0}')),
                        DataCell(Text('${part['heightMm'] ?? 0}')),
                        DataCell(Text('${part['widthFeet'] ?? 0.0}')),
                        DataCell(Text('${part['heightFeet'] ?? 0.0}')),
                        DataCell(Text('${part['squareFeet'] ?? 0.0}')),
                        DataCell(Text('${part['quantity'] ?? 1}')),
                        DataCell(Text('${part['rate'] ?? 0.0}')),
                        DataCell(Text('${part['amount'] ?? 0.0}')),
                        DataCell(Text('${part['item_code'] ?? 'N/A'}')),
                        DataCell(Text('${part['mrp'] ?? 0.0}')),
                        DataCell(Text('${part['net_amount'] ?? 0.0}')),
                        DataCell(Text('${part['labour'] ?? 0.0}')),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDelete(part['id']),
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
    );
  }
}
