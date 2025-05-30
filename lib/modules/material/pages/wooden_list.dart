import 'package:erp_tool/modules/material/pages/wooden_item.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class WoodenItemsListPage extends StatefulWidget {
  const WoodenItemsListPage({super.key});

  @override
  _WoodenItemsListPageState createState() => _WoodenItemsListPageState();
}

const String baseUrl = "http://127.0.0.1:4000/api/material";

class _WoodenItemsListPageState extends State<WoodenItemsListPage> {
  late Future<List<Map<String, dynamic>>> _items;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    _items = _fetchItems();
  }

  Future<List<Map<String, dynamic>>> _fetchItems() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/wooden-items'), // ✅ Correct API URL
      );

      print("📩 Response Status: ${response.statusCode}");
      print("📨 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> items = json.decode(response.body);
        return List<Map<String, dynamic>>.from(
            items); // ✅ Ensure correct list format
      } else {
        print("❌ API Error: ${response.body}");
        throw Exception('Failed to fetch wooden items');
      }
    } catch (e) {
      print('❌ Error fetching wooden items: $e');
      return []; // ✅ Return an empty list to prevent crashes
    }
  }

  void _deleteItem(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/wooden-item/$id'),
      );

      if (response.statusCode == 200) {
        _fetchItems(); // Refresh the list after deletion
      } else {
        throw Exception('Failed to delete item');
      }
    } catch (e) {
      print('Error deleting item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error deleting item')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wooden Items List'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _items,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No items found.'));
          } else {
            final items = snapshot.data!;
            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  title: Text(item['name']),
                  subtitle: Text(item['description']),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteItem(item['id']),
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddWoodenItemPage()),
          ).then((_) => setState(() => _loadItems()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
