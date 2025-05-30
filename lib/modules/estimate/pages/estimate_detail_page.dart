// lib/pages/estimate_detail_page.dart

import 'package:flutter/material.dart';
import '../models/woodwork_estimate.dart';

class EstimateDetailPage extends StatelessWidget {
  final WoodworkEstimate estimate;

  const EstimateDetailPage({super.key, required this.estimate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Estimate #${estimate.id}'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estimate #${estimate.id}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Total Amount: \$${estimate.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, color: Colors.blueAccent),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: estimate.rows.length,
                itemBuilder: (context, index) {
                  final row = estimate.rows[index];
                  return Card(
                    child: ListTile(
                      title: Text('Unit: ${row.selectedUnit ?? ''}'),
                      subtitle: Text(
                          'Finish: ${row.selectedFinish ?? ''}\nAmount: \$${row.amount.toStringAsFixed(2)}'),
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
