import 'package:flutter/material.dart';
import '../../../modules/material/pages/electricalType.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DescriptionPage extends StatefulWidget {
  const DescriptionPage({super.key});

  @override
  _DescriptionPageState createState() => _DescriptionPageState();
}

class _DescriptionPageState extends State<DescriptionPage> {
  List<Map<String, dynamic>> _descriptions = [];

  final TextEditingController _descriptionController = TextEditingController();
  int? _selectedDescriptionId; // Store the selected description ID for updating

  @override
  void initState() {
    super.initState();
    _loadDescriptions();
  }

  Future<void> _loadDescriptions() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:4000/api/e-estimate/descriptions'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> descriptions = json.decode(response.body);
        setState(() {
          _descriptions = List<Map<String, dynamic>>.from(descriptions);
        });
      } else {
        print('Failed to load descriptions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching descriptions: $e');
    }
  }

  Future<void> _saveDescription() async {
    if (_descriptionController.text.isEmpty) return;

    try {
      final Map<String, dynamic> descriptionData = {
        'description': _descriptionController.text,
      };

      http.Response response;
      if (_selectedDescriptionId != null) {
        // Update existing description
        response = await http.put(
          Uri.parse(
              'http://127.0.0.1:4000/api/e-estimate/descriptions/$_selectedDescriptionId'),
          headers: {"Content-Type": "application/json"},
          body: json.encode(descriptionData),
        );
      } else {
        // Insert new description
        response = await http.post(
          Uri.parse('http://127.0.0.1:4000/api/e-estimate/descriptions'),
          headers: {"Content-Type": "application/json"},
          body: json.encode(descriptionData),
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        _descriptionController.clear();
        _selectedDescriptionId = null;
        _loadDescriptions();
      } else {
        throw Exception('Failed to save description');
      }
    } catch (e) {
      print('Error saving description: $e');
    }
  }

  _editDescription(int id, String description) {
    _descriptionController.text = description;
    _selectedDescriptionId = id; // Set the selected description ID for update
  }

  Future<void> _deleteDescription(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('http://127.0.0.1:4000/api/e-estimate/descriptions/$id'),
      );

      if (response.statusCode == 200) {
        _loadDescriptions();
      } else {
        print('Failed to delete description');
      }
    } catch (e) {
      print('Error deleting description: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Descriptions'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Enter Description'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _saveDescription,
              child: Text(_selectedDescriptionId == null
                  ? 'Save Description'
                  : 'Update Description'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _descriptions.length,
                itemBuilder: (context, index) {
                  var description = _descriptions[index];
                  return ListTile(
                    title: Text('ID: ${description['descriptionId']}'),
                    subtitle: Text(description['description']),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TypePage(description['descriptionId']),
                        ),
                      );
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            _editDescription(description['descriptionId'],
                                description['description']);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            _deleteDescription(description['descriptionId']);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
