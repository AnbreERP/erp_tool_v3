import 'package:flutter/material.dart';
import '../../../database/estimate_database.dart';
import '../models/woodwork_estimate.dart';

class EstimateListPage extends StatelessWidget {
  const EstimateListPage({super.key, required int customerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Estimates')),
      body: FutureBuilder<List<WoodworkEstimate>>(
        future: EstimateDatabase
            .getEstimates(), // The return type is now List<WoodworkEstimate>
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child:
                  Text('No estimates found.', style: TextStyle(fontSize: 18)),
            );
          }

          final estimates = snapshot.data!; // Now it's a List<WoodworkEstimate>

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical, // Vertical scrolling
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal, // Horizontal scrolling
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('Version')),
                    DataColumn(label: Text('Customer Name')),
                    DataColumn(label: Text('Customer Email')),
                    DataColumn(label: Text('Mobile Number')),
                    DataColumn(label: Text('Total Amount 1')),
                    DataColumn(label: Text('Total Amount 2')),
                    DataColumn(label: Text('Total Amount 3')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: estimates.map((estimate) {
                    return DataRow(
                      cells: [
                        DataCell(Text(estimate.id.toString())),
                        DataCell(Text(estimate.version)),
                        DataCell(Text(estimate.customerName ?? 'Unknown')),
                        DataCell(Text(estimate.customerEmail ?? 'Unknown')),
                        DataCell(Text(estimate.customerPhone ?? 'Unknown')),
                        DataCell(Text(
                            '₹${estimate.totalAmount.toStringAsFixed(2)}')),
                        DataCell(Text(
                            '₹${estimate.totalAmount2.toStringAsFixed(2)}')),
                        DataCell(Text(
                            '₹${estimate.totalAmount3.toStringAsFixed(2)}')),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility,
                                    color: Colors.blue),
                                onPressed: () async {
                                  // Add the navigation logic for viewing estimate details
                                },
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  // Add the logic for deleting an estimate
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
