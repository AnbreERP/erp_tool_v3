import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AddWoodenItemPage extends StatefulWidget {
  const AddWoodenItemPage({super.key});

  @override
  _AddWoodenItemPageState createState() => _AddWoodenItemPageState();
}

const String baseUrl = "http://127.0.0.1:4000/api/material";

class _AddWoodenItemPageState extends State<AddWoodenItemPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  void _saveItem() async {
    if (_formKey.currentState!.validate()) {
      try {
        final Map<String, dynamic> itemData = {
          'name': _nameController.text.trim(), // ✅ Trim whitespace
          'description': _descriptionController.text.trim(),
        };

        final response = await http.post(
          Uri.parse('$baseUrl/wooden-item'), // ✅ Use correct base URL
          headers: {"Content-Type": "application/json"},
          body: json.encode(itemData),
        );

        print("📩 Response Status: ${response.statusCode}");
        print("📨 Response Body: ${response.body}");

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item saved successfully')),
          );
          Navigator.pop(context); // ✅ Go back to the list page
        } else {
          print("❌ Failed to save item: ${response.body}");
          throw Exception('Failed to save item');
        }
      } catch (e) {
        print('❌ Error saving item: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving item')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Wooden Item')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a name' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveItem,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
