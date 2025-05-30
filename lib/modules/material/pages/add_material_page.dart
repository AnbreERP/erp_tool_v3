import 'package:flutter/material.dart';
// Import the DatabaseHelper

class AddMaterialPage extends StatefulWidget {
  const AddMaterialPage({super.key});

  @override
  _AddMaterialPageState createState() => _AddMaterialPageState();
}

class _AddMaterialPageState extends State<AddMaterialPage> {
  final TextEditingController _materialNameController = TextEditingController();
  final TextEditingController _materialRateController = TextEditingController();
  final TextEditingController _materialUnitController = TextEditingController();

  // Instance of DatabaseHelper to store the material
  // final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Function to add the material
  void _addMaterial() async {
    if (_materialNameController.text.isNotEmpty &&
        _materialRateController.text.isNotEmpty &&
        _materialUnitController.text.isNotEmpty) {
      // await _databaseHelper.insertMaterial(newMaterial);

      // Navigate back to the previous page (Material Management Page)
      Navigator.pop(context);
    } else {
      // Show error if any field is empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Material'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _materialNameController,
              decoration: const InputDecoration(labelText: 'Material Name'),
            ),
            TextField(
              controller: _materialRateController,
              decoration: const InputDecoration(labelText: 'Rate'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _materialUnitController,
              decoration: const InputDecoration(labelText: 'Unit'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addMaterial,
              child: const Text('Add Material'),
            ),
          ],
        ),
      ),
    );
  }
}
