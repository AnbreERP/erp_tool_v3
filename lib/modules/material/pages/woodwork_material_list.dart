import 'package:flutter/material.dart';
import '../../../models/material.dart';
import 'woodwork_material_form.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class WoodworkMaterialListPage extends StatefulWidget {
  const WoodworkMaterialListPage({super.key});

  @override
  _WoodworkMaterialListPageState createState() =>
      _WoodworkMaterialListPageState();
}

const String baseUrl = "http://127.0.0.1:4000/api/material";

class _WoodworkMaterialListPageState extends State<WoodworkMaterialListPage> {
  List<MaterialModel> woodworkMaterials = [];
  final List<String> unitTypes = [
    'KitchenFinishTypes',
    'BedroomFinishTypes',
    'EndCapFinishTypes',
    'SlidingFittingsTypes',
    'AccessoryTypes',
    'HandleTypes',
    'SideOptions',
  ];

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  // Fetch materials from the database
  Future<void> _loadMaterials() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/all-material"),
      );

      if (response.statusCode == 200) {
        final List<dynamic> materials = json.decode(response.body);
        setState(() {
          woodworkMaterials = materials.map((material) {
            return MaterialModel(
              id: int.parse(material['id'].toString()), // ✅ Ensure integer
              type: material['type'] as String,
              unitType: material['unitType'] as String,
              finish: material['finish'] as String,
              rate: double.tryParse(material['rate'].toString()) ??
                  0.0, // ✅ Convert rate safely
              dateAdded: DateTime.tryParse(material['dateAdded'].toString()) ??
                  DateTime.now(), // ✅ Handle null
            );
          }).toList();
        });
      } else {
        throw Exception('Failed to load materials');
      }
    } catch (e) {
      print('❌ Error loading materials: $e');
    }
  }

  // Fetch matching rows from wooden_item_parts table
  Future<List<Map<String, dynamic>>> _fetchMatchingParts(String finish) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/matching-parts/$finish"),
      );

      if (response.statusCode == 200) {
        final List<dynamic> parts = json.decode(response.body);
        return List<Map<String, dynamic>>.from(parts);
      } else {
        throw Exception('Failed to fetch matching parts');
      }
    } catch (e) {
      print('Error fetching matching parts: $e');
      return [];
    }
  }

  // Show popup with matching parts data
  void _showMatchingPartsPopup(String finishName) async {
    final results = await _fetchMatchingParts(finishName);

    // Calculate the sum of the "Amount" column
    double totalAmount = results.fold(0.0, (sum, item) {
      return sum + (item['amount'] != null ? item['amount'] as double : 0.0);
    });

    double hikePercentage = 31; // Default hike percentage
    double hikeMultiplier =
        1 / (1 - (hikePercentage / 100)); // Formula for hike multiplier
    double hikedTotalAmount = totalAmount * hikeMultiplier;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          // Allow state changes within the popup
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Matching Parts for "$finishName"'),
              content: results.isEmpty
                  ? const Text('No matching parts found.')
                  : SizedBox(
                      width: double.maxFinite,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // DataTable
                            DataTable(
                              columns: const [
                                DataColumn(label: Text('ID')),
                                DataColumn(label: Text('Finish')),
                                DataColumn(label: Text('Description')),
                                DataColumn(label: Text('Type')),
                                DataColumn(label: Text('Actual Length (mm)')),
                                DataColumn(label: Text('Actual Height (mm)')),
                                DataColumn(label: Text('Length (ft)')),
                                DataColumn(label: Text('Height (ft)')),
                                DataColumn(label: Text('Area (sqft)')),
                                DataColumn(label: Text('Quantity')),
                                DataColumn(label: Text('Rate')),
                                DataColumn(label: Text('Amount')),
                                DataColumn(label: Text('Item Code')),
                                DataColumn(label: Text('MRP')),
                                DataColumn(label: Text('Net Amount')),
                                DataColumn(label: Text('Labour')),
                              ],
                              rows: results.map((item) {
                                return DataRow(cells: [
                                  DataCell(Text(item['id'].toString())),
                                  DataCell(Text(item['finish_name'] ?? 'N/A')),
                                  DataCell(Text(item['description'] ?? 'N/A')),
                                  DataCell(Text(item['type'] ?? 'N/A')),
                                  DataCell(Text(item['widthMm'].toString())),
                                  DataCell(Text(item['heightMm'].toString())),
                                  DataCell(Text(item['widthFeet'].toString())),
                                  DataCell(Text(item['heightFeet'].toString())),
                                  DataCell(Text(item['squareFeet'].toString())),
                                  DataCell(Text(item['quantity'].toString())),
                                  DataCell(Text(item['rate'].toString())),
                                  DataCell(Text(item['amount'].toString())),
                                  DataCell(Text(item['item_code'] ?? 'N/A')),
                                  DataCell(Text(item['mrp'].toString())),
                                  DataCell(Text(item['net_amount'].toString())),
                                  DataCell(Text(item['labour'].toString())),
                                ]);
                              }).toList(),
                            ),
                            const SizedBox(height: 16), // Spacing
                            // Input for Hike Percentage
                            Row(
                              children: [
                                const Text(
                                  'Hike Percentage (%): ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(
                                  width: 80,
                                  child: TextField(
                                    controller: TextEditingController(
                                      text: hikePercentage.toString(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      setState(() {
                                        hikePercentage =
                                            double.tryParse(value) ?? 0.0;
                                        hikeMultiplier =
                                            1 / (1 - (hikePercentage / 100));
                                        hikedTotalAmount =
                                            totalAmount * hikeMultiplier;
                                      });
                                    },
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Display Total Amount and Hiked Amount
                            Align(
                              alignment: Alignment.centerRight,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Total Amount: \$${totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Hiked Total (with $hikePercentage%): '
                                    '\$${hikedTotalAmount.roundToDouble()}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Add new material
  void _addMaterial() async {
    final newMaterial = await Navigator.push<MaterialModel>(
      context,
      MaterialPageRoute(
        builder: (context) => WoodworkMaterialFormPage(
          onSave: (newMaterial) async {
            try {
              final response = await http.post(
                Uri.parse('http://127.0.0.1:4000/materials'),
                headers: {"Content-Type": "application/json"},
                body: json.encode(newMaterial.toMap()),
              );

              if (response.statusCode == 201) {
                final result = json.decode(response.body);
                newMaterial.id = result['id']; // Assign ID from the database
                setState(() {
                  woodworkMaterials.add(newMaterial);
                });
              } else {
                throw Exception('Failed to add material');
              }
            } catch (e) {
              print('Error adding material: $e');
            }
          },
          unitTypes: unitTypes,
        ),
      ),
    );

    if (newMaterial != null) {
      _loadMaterials();
    }
  }

  // Edit existing material
  void _editMaterial(MaterialModel material) async {
    final updatedMaterial = await Navigator.push<MaterialModel>(
      context,
      MaterialPageRoute(
        builder: (context) => WoodworkMaterialFormPage(
          material: material,
          unitTypes: unitTypes,
          onSave: (updatedMaterial) async {
            try {
              final response = await http.put(
                Uri.parse('$baseUrl/all-material/${material.id}'),
                headers: {"Content-Type": "application/json"},
                body: json.encode(updatedMaterial.toMap()),
              );

              if (response.statusCode == 200) {
                setState(() {
                  final index = woodworkMaterials.indexOf(material);
                  woodworkMaterials[index] = updatedMaterial;
                });
              } else {
                throw Exception('Failed to update material');
              }
            } catch (e) {
              print('Error updating material: $e');
            }
          },
        ),
      ),
    );

    if (updatedMaterial != null) {
      _loadMaterials();
    }
  }

  // Delete material
  void _deleteMaterial(MaterialModel material) async {
    try {
      final response = await http.delete(
        Uri.parse('http://127.0.0.1:4000/materials/${material.id}'),
      );

      if (response.statusCode == 200) {
        _loadMaterials();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${material.finish} deleted successfully.')),
        );
      } else {
        throw Exception('Failed to delete material');
      }
    } catch (e) {
      print('Error deleting material: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error deleting material')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Woodwork Materials'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addMaterial,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: woodworkMaterials.isEmpty
            ? Center(
                child: Text(
                  'No materials added yet.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              )
            : Column(
                children: [
                  _buildTableHeader(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: woodworkMaterials.length,
                      itemBuilder: (context, index) {
                        final material = woodworkMaterials[index];
                        return _buildTableRow(material, index);
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Row(
      children: [
        _buildHeaderCell('Unit Type', flex: 2),
        _buildHeaderCell('Finish Name', flex: 3),
        _buildHeaderCell('Rate', flex: 2),
        _buildHeaderCell('Actions', flex: 2),
      ],
    );
  }

  Widget _buildTableRow(MaterialModel material, int index) {
    return Container(
      color: index % 2 == 0 ? Colors.white : Colors.grey[100],
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          _buildCell(material.unitType, flex: 2),
          _buildCell(material.finish, flex: 3),
          _buildCell(material.rate.toStringAsFixed(2), flex: 2),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.blue),
                  onPressed: () => _showMatchingPartsPopup(material.finish),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.green),
                  onPressed: () => _editMaterial(material),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteMaterial(material),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String title, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCell(String value, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        value,
        textAlign: TextAlign.center,
      ),
    );
  }
}
