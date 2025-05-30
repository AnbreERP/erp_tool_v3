import 'package:erp_tool/modules/material/pages/electricalProductList.dart';
import 'package:flutter/material.dart';
import '../../../widgets/MainScaffold.dart';
import '../../../widgets/sidebar_menu.dart';
import 'add_page.dart';
import 'woodwork_material_list.dart';
import 'false_ceiling_material_list.dart';
import 'wooden_list.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MaterialHomePage extends StatefulWidget {
  const MaterialHomePage({super.key});

  @override
  _MaterialHomePageState createState() => _MaterialHomePageState();
}

class _MaterialHomePageState extends State<MaterialHomePage> {
  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> materialTypes = [
      {
        'name': 'Woodwork',
        'icon': Icons.home_repair_service,
        'page': const WoodworkMaterialListPage(),
      },
      {
        'name': 'Electrical',
        'icon': Icons.electrical_services,
        'page': const ElectricalProductListPage(),
      },
      {
        'name': 'False Ceiling',
        'icon': Icons.roofing,
        'page': const FalseCeilingMaterialListPage(),
      },
      {
        'name': 'Add Wooden Item Parts',
        'icon': Icons.add_box,
        'getPage': () async {
          int woodenItemId = await _getWoodenItemId(context);
          if (woodenItemId != -1) {
            SidebarController.of(context)?.openPage(
              AddWoodenItemPartPage(woodenItemId: woodenItemId),
            );
          }
        },
      },
      {
        'name': 'Wooden Items List',
        'icon': Icons.list,
        'page': const WoodenItemsListPage(),
      },
    ];

    return MainScaffold(
      title: 'Material Management',
      child: ListView.builder(
        itemCount: materialTypes.length,
        itemBuilder: (context, index) {
          final materialType = materialTypes[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              leading: Icon(materialType['icon'], size: 40, color: Colors.blue),
              title: Text(materialType['name'],
                  style: const TextStyle(fontSize: 18)),
              onTap: () async {
                if (materialType.containsKey('getPage')) {
                  final page = await materialType['getPage']();
                  if (page != null) {
                    SidebarController.of(context)?.openPage(page);
                  }
                } else if (materialType.containsKey('page')) {
                  SidebarController.of(context)?.openPage(materialType['page']);
                }
              },
            ),
          );
        },
      ),
    );
  }

  // Method to dynamically fetch or select a woodenItemId
  Future<int> _getWoodenItemId(BuildContext context) async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:4000/api/core-woodwork/wooden-items'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch wooden items');
      }

      final List<dynamic> items = json.decode(response.body);

      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No wooden items found. Please add one.'),
          ),
        );
        throw Exception('No wooden items available.');
      }

      int selectedWoodenItemId = items.first['id'] as int;

      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Select Wooden Item'),
            content: SingleChildScrollView(
              child: Column(
                children: items.map((item) {
                  final int id = item['id'] as int;
                  final String name = item['name'] as String;
                  return ListTile(
                    title: Text(name),
                    onTap: () {
                      selectedWoodenItemId = id;
                      Navigator.of(context).pop();
                    },
                  );
                }).toList(),
              ),
            ),
          );
        },
      );

      return selectedWoodenItemId;
    } catch (e) {
      print('❌ Error fetching wooden item ID: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      return -1; // Return -1 or any invalid ID to handle errors gracefully
    }
  }
}
