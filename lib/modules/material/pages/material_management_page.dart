import 'package:flutter/material.dart';
// Import the DatabaseHelper
import 'add_material_page.dart'; // Import the Add Material page

class MaterialManagementPage extends StatefulWidget {
  const MaterialManagementPage({super.key});

  @override
  _MaterialManagementPageState createState() => _MaterialManagementPageState();
}

class _MaterialManagementPageState extends State<MaterialManagementPage> {
  // final DatabaseHelper _databaseHelper = DatabaseHelper();

  final List<Map<String, dynamic>> _materials = [];

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  // Load all materials from the database
  void _loadMaterials() async {
    // final materials = await _databaseHelper.getAllMaterials();
    setState(() {
      // _materials = materials;
    });
  }

  // Function to delete material
  void _deleteMaterial(int id) async {
    // await _databaseHelper.deleteMaterial(id);
    _loadMaterials(); // Reload the materials after deletion
  }

  // Build the list of materials
  Widget _buildMaterialList() {
    return ListView.builder(
      itemCount: _materials.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(_materials[index]['name']),
          subtitle: Text(
              'Rate: ${_materials[index]['rate']} | Unit: ${_materials[index]['unit']}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteMaterial(_materials[index]['id']),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Material Management'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                // Navigate to AddMaterialPage to add a new material
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AddMaterialPage()),
                ).then((_) {
                  // After returning from the Add Material page, reload materials
                  _loadMaterials();
                });
              },
              child: const Text('Add Material'),
            ),
            const SizedBox(height: 20),
            Expanded(child: _buildMaterialList()),
          ],
        ),
      ),
    );
  }
}
