import 'package:flutter/material.dart';

class ElectricalList extends StatefulWidget {
  const ElectricalList({super.key});

  @override
  State<StatefulWidget> createState() {
    return _ElectricalListState();
  }
}

class _ElectricalListState extends State<ElectricalList> {
  // Placeholder function to simulate fetching categories (Replace with real data fetching logic)
  Future<List<Category>> fetchCategories() async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay
    return [
      Category(category: 'Wiring', description: 'Electrical wiring for the house'),
      Category(category: 'Lighting', description: 'Light fixtures and installation'),
      Category(category: 'Outlets', description: 'Electrical outlets and switches'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Electrical Estimate Data'),
        backgroundColor: Colors.orangeAccent,
        foregroundColor: Colors.white,
      ),
      body: getElectricalListView(),
    );
  }

  // This function returns the ListView with FutureBuilder for async data loading
  Widget getElectricalListView() {
    return FutureBuilder<List<Category>>(
      future: fetchCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No categories available"));
        } else {
          var categories = snapshot.data!;
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(categories[index].category),
                subtitle: Text(categories[index].description),
              );
            },
          );
        }
      },
    );
  }
}

// Simple Category model to represent the data structure
class Category {
  final String category;
  final String description;

  Category({required this.category, required this.description});
}
