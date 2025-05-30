import 'package:flutter/material.dart';
import '../../../models/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class WoodworkMaterialFormPage extends StatefulWidget {
  final MaterialModel? material; // Existing material to edit, if any
  final void Function(MaterialModel material) onSave;
  final List<String> unitTypes;

  const WoodworkMaterialFormPage({
    super.key,
    this.material,
    required this.onSave,
    required this.unitTypes,
  });

  @override
  _WoodworkMaterialFormPageState createState() =>
      _WoodworkMaterialFormPageState();
}

class _WoodworkMaterialFormPageState extends State<WoodworkMaterialFormPage> {
  final _formKey = GlobalKey<FormState>();
  String? _unitType;
  String? _finish; // Renamed field 'materialName' to 'finish'
  double? _rate;
  DateTime _selectedDate = DateTime.now(); // Default to the current date

  @override
  void initState() {
    super.initState();
    if (widget.material != null) {
      _unitType = widget.material!.unitType;
      _finish = widget.material!.finish; // Updated field
      _rate = widget.material!.rate;
      _selectedDate = widget.material!.dateAdded;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newMaterial = MaterialModel(
        id: widget.material?.id, // ✅ Null for new materials
        type: 'Woodwork',
        unitType: _unitType!,
        finish: _finish!,
        rate: _rate!,
        dateAdded: _selectedDate,
      );

      print('📤 Saving material: ${jsonEncode(newMaterial.toMap())}');

      try {
        final Map<String, dynamic> materialData = newMaterial.toMap();
        http.Response response;

        // ✅ Use Base API URL
        const String baseUrl = "http://127.0.0.1:4000/api/material";
        final String url = widget.material == null
            ? "$baseUrl/save-finish" // ✅ Use POST to add new material
            : "$baseUrl/all-material/${widget.material!.id}"; // ✅ Use PUT for updating

        print("🌍 API Request to: $url");

        // Use the correct HTTP method based on whether it's an update or new material
        if (widget.material == null) {
          // Use POST method for adding new material
          response = await http.post(
            Uri.parse(url),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(materialData),
          );
        } else {
          // Use PUT method for updating existing material
          response = await http.put(
            Uri.parse(url),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(materialData),
          );
        }

        print("📩 Response Status: ${response.statusCode}");
        print("📨 Response Body: ${response.body}");

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (widget.material == null) {
            final result = json.decode(response.body);
            newMaterial.id = result['id']; // ✅ Assign ID after insertion
            _showSnackBar('Material added successfully!');
            print('✅ Material saved with ID: ${newMaterial.id}');
          } else {
            _showSnackBar('Material updated successfully!');
          }

          widget.onSave(newMaterial);
          Navigator.pop(context); // ✅ Close the form
        } else {
          throw Exception('Failed to save material');
        }
      } catch (e) {
        print('❌ Error saving material: $e');
        _showSnackBar('Error saving material');
      }
    } else {
      _showSnackBar('⚠️ Form validation failed!');
    }
  }

  void _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure no duplicates in the unitTypes list
    final uniqueUnitTypes = widget.unitTypes.toSet().toList();

    // Ensure _unitType is one of the items in the list
    if (_unitType != null && !uniqueUnitTypes.contains(_unitType)) {
      _unitType = uniqueUnitTypes.isNotEmpty ? uniqueUnitTypes[0] : null;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.material == null ? 'Add Material' : 'Edit Material'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            elevation: 6,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.material == null
                        ? 'Add New Material'
                        : 'Edit Material',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Form Fields
                  _buildTableRow(
                    'Unit Type',
                    DropdownButtonFormField<String>(
                      value: _unitType,
                      items: uniqueUnitTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _unitType = value),
                      onSaved: (value) => _unitType = value,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                      validator: (value) =>
                          value == null ? 'Please select a unit type' : null,
                    ),
                  ),
                  const Divider(),
                  _buildTableRow(
                    'Finish', // Updated field label
                    TextFormField(
                      initialValue: _finish,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter finish name', // Updated hint text
                      ),
                      onSaved: (value) => _finish = value,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter a finish name'
                          : null,
                    ),
                  ),
                  const Divider(),
                  _buildTableRow(
                    'Rate',
                    TextFormField(
                      initialValue: _rate?.toString(),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter rate',
                      ),
                      keyboardType: TextInputType.number,
                      onSaved: (value) => _rate = double.tryParse(value!),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a rate';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const Divider(),
                  _buildTableRow(
                    'Added Date',
                    GestureDetector(
                      onTap: _pickDate,
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Select date',
                          ),
                          controller: TextEditingController(
                              text: _selectedDate
                                  .toLocal()
                                  .toString()
                                  .split(' ')[0]),
                        ),
                      ),
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16),
                        backgroundColor: Colors.blueAccent,
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableRow(String label, Widget inputField) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: inputField,
          ),
        ],
      ),
    );
  }
}
