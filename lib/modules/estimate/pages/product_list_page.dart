import 'package:flutter/material.dart';
import '../../../models/electrical_product_model.dart';
//import '../../../database/e_database_helper.dart';

class ProductDetailsPage extends StatelessWidget {
  final List<Product> products;

  // Constructor to receive products from the previous page
  const ProductDetailsPage({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 0.0),
              child: Container(
                padding:
                    const EdgeInsets.all(16.0), // Add padding inside the card
                height: 170, // Increase height of the card
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.description,
                      style:
                          const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.light_details,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Spacer(), // Spacer to push the text to the top
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Material Rate: ${product.material_rate}'),
                        Text('Labour Rate: ${product.labour_rate}'),
                        Text('BOQ Material Rate: ${product.boq_material_rate}'),
                        Text('BOQ Labour Rate: ${product.boq_labour_rate}'),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
