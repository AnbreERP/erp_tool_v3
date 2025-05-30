// lib/modules/estimate/pages/woodwork_estimate_page.dart

import 'package:flutter/material.dart';
import 'new_woodwork_estimate_page.dart';
import 'woodwork_estimate_list_page.dart';

class WoodworkEstimatePage extends StatelessWidget {
  const WoodworkEstimatePage({super.key});

  void _navigateToNewEstimate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => const NewWoodworkEstimatePage(
                customerId: 0,
                customerName: '',
                customerEmail: '',
                customerPhone: '',
              )),
    );
  }

  void _navigateToEstimateList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WoodworkEstimateListPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Woodwork Estimates'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('New Estimate'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                backgroundColor: Colors.blueAccent,
              ),
              onPressed: () => _navigateToNewEstimate(context),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.list),
              label: const Text('View Estimate List'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                backgroundColor: Colors.lightBlue,
              ),
              onPressed: () => _navigateToEstimateList(context),
            ),
          ],
        ),
      ),
    );
  }
}
