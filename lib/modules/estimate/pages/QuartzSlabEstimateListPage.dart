import 'package:erp_tool/modules/estimate/pages/quartz_EstimateDetailsPage.dart';
import 'package:flutter/material.dart';
import '../../../database/q_database_helper.dart';
import '../../../services/customer_database_service.dart';
import '../../../widgets/sidebar_menu.dart';

class QuartzSlabEstimateListPage extends StatefulWidget {
  const QuartzSlabEstimateListPage({super.key});

  @override
  _QuartzSlabEstimateListPageState createState() =>
      _QuartzSlabEstimateListPageState();
}

class _QuartzSlabEstimateListPageState
    extends State<QuartzSlabEstimateListPage> {
  List<Map<String, dynamic>> _estimates = [];

  @override
  void initState() {
    super.initState();
    _loadEstimates();
  }

  Future<void> _loadEstimates() async {
    try {
      _estimates = await QDatabaseHelper.getQuartzEstimates();
      setState(() {});
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load estimates: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Delete estimate from database
  void _deleteEstimate(int estimateId) async {
    try {
      await QDatabaseHelper.deleteQuartzEstimate(estimateId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Estimate deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadEstimates(); // Reload estimates after deletion
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete estimate: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Estimates'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _estimates.isEmpty
            ? const Center(child: Text('No saved estimates'))
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16.0,
                  headingRowHeight: 50,
                  dataRowHeight: 60,
                  columns: const [
                    DataColumn(label: Text('S.No')),
                    DataColumn(label: Text('Customer Name')),
                    DataColumn(label: Text('Hike')),
                    DataColumn(label: Text('Transport')),
                    DataColumn(label: Text('Loading')),
                    DataColumn(label: Text('Version')),
                    DataColumn(label: Text('Total Amount')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: List<DataRow>.generate(
                    _estimates.length,
                    (index) {
                      var estimate = _estimates[index];
                      return DataRow(cells: [
                        DataCell(Text('${index + 1}')),
                        DataCell(FutureBuilder<String?>(
                          future: CustomerDatabaseService()
                              .getCustomerNameById(estimate['customerId']),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Text(
                                  'Loading...'); // While fetching the data
                            } else if (snapshot.hasError) {
                              return Text(
                                  'Error: ${snapshot.error}'); // Error fetching the data
                            } else if (snapshot.hasData) {
                              return Text(snapshot.data ??
                                  'Unknown'); // Display the customer name
                            } else {
                              return const Text(
                                  'Not Found'); // If no data found
                            }
                          },
                        )),
                        DataCell(Text(estimate['hike'].toString())),
                        DataCell(Text(estimate['transport'].toString())),
                        DataCell(Text(estimate['loading'].toString())),
                        DataCell(Text(estimate['version'].toString())),
                        DataCell(Text('₹${estimate['totalAmount']}')),
                        DataCell(
                          Row(
                            children: [
                              // View Icon
                              IconButton(
                                icon: const Icon(Icons.visibility),
                                onPressed: () {
                                  SidebarController.of(context)?.openPage(
                                    EstimateDetailsPage(
                                      estimateId: estimate['id'],
                                    ),
                                  );
                                },
                              ),
                              // Delete Icon
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _deleteEstimate(estimate['id']);
                                },
                              ),
                            ],
                          ),
                        ),
                      ]);
                    },
                  ),
                ),
              ),
      ),
    );
  }
}
