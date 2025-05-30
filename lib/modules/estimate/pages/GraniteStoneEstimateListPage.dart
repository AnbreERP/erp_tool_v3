// GraniteStoneEstimatelistpage.dart

import 'package:flutter/material.dart';
import '../../../database/g_database_helper.dart';
import '../../../services/customer_database_service.dart';
import '../../../widgets/sidebar_menu.dart';
import 'granitestone_estimate_details.dart';

class GraniteStoneEstimatelistpage extends StatefulWidget {
  const GraniteStoneEstimatelistpage({super.key});

  @override
  _GraniteStoneEstimatelistpageState createState() =>
      _GraniteStoneEstimatelistpageState();
}

class _GraniteStoneEstimatelistpageState
    extends State<GraniteStoneEstimatelistpage> {
  late Future<List<Map<String, dynamic>>> _estimates;

  @override
  void initState() {
    super.initState();
    _loadEstimates(); // Initialize estimates loading
  }

  void _loadEstimates() {
    setState(() {
      _estimates =
          GraniteDatabaseHelper.fetchGraniteStoneEstimate().catchError((error) {
        print("Error fetching data: $error");
        return []; // Return an empty list on error
      });
    });
  }

  // Function to delete an estimate based on its ID
  Future<void> deleteEstimate(int estimateId) async {
    await GraniteDatabaseHelper.deleteGraniteEstimate(estimateId);
    _loadEstimates(); // Reload estimates after deletion
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Estimate deleted successfully'),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Function to view the detailed estimate
  void _viewEstimate(dynamic estimateId) {
    if (estimateId != null && estimateId is int && estimateId > 0) {
      SidebarController.of(context)?.openPage(
        GranitestoneEstimateDetails(estimateId: estimateId),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Invalid Estimate ID'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Granite Stone Estimates List'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _estimates,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data available.'));
          }

          final List<Map<String, dynamic>> estimates = snapshot.data!;

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('S.No')),
                DataColumn(label: Text('Customer Name')),
                DataColumn(label: Text('Total Amount')),
                DataColumn(label: Text('Action')),
              ],
              rows: List<DataRow>.generate(estimates.length, (index) {
                Map<String, dynamic> estimate = estimates[index];

                return DataRow(cells: [
                  DataCell(Text('${index + 1}')),
                  DataCell(FutureBuilder<String?>(
                    future: CustomerDatabaseService()
                        .getCustomerNameById(estimate['customerId']),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text(
                            'Loading...'); // While fetching the data
                      } else if (snapshot.hasError) {
                        return Text(
                            'Error: ${snapshot.error}'); // Error fetching the data
                      } else if (snapshot.hasData) {
                        return Text(snapshot.data ??
                            'Unknown'); // Display the customer name
                      } else {
                        return const Text('Not Found'); // If no data found
                      }
                    },
                  )),
                  DataCell(Text('₹${estimate['totalAmount']}')),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility),
                          onPressed: () {
                            _viewEstimate(estimate['id']); // Use 'id'
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            deleteEstimate(estimate['estimateId'] ??
                                0); // Handle null case
                          },
                        ),
                      ],
                    ),
                  ),
                ]);
              }),
            ),
          );
        },
      ),
    );
  }
}
