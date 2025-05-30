import 'package:flutter/material.dart';
import '../../../database/w_database_helper.dart';
import '../../../services/customer_database_service.dart';
import '../../../widgets/sidebar_menu.dart';
import 'WallpaperEstimateDetailPage.dart';

class WallpaperEstimateListPage extends StatefulWidget {
  const WallpaperEstimateListPage({super.key});

  @override
  _WallpaperEstimateListPageState createState() =>
      _WallpaperEstimateListPageState();
}

class _WallpaperEstimateListPageState extends State<WallpaperEstimateListPage> {
  // ✅ Properly initialize _estimates as a Future
  late Future<List<Map<String, dynamic>>> _estimates;

  @override
  void initState() {
    super.initState();
    _loadEstimates();
  }

  // ✅ Correctly fetch estimates
  void _loadEstimates() {
    setState(() {
      _estimates = _fetchEstimates();
    });
  }

  // ✅ Fetch estimates from the database
  Future<List<Map<String, dynamic>>> _fetchEstimates() async {
    try {
      return await WDatabaseHelper.getWallpaperEstimates();
    } catch (e) {
      print("Error loading estimates: $e");
      return []; // Return an empty list instead of crashing
    }
  }

  // ✅ Function to delete a specific estimate
  Future<void> _deleteEstimate(int id) async {
    await WDatabaseHelper.deleteWallpaperEstimate(id);
    _loadEstimates(); // Reload estimates after deletion
  }

  // ✅ Navigate to the detail page
  void _viewDetails(int estimateId) {
    SidebarController.of(context)?.openPage(
      WallpaperEstimateDetailPage(estimateId: estimateId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Saved Wallpaper Estimates"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _estimates,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No estimates found.'));
          } else {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal, // Horizontal scroll for table
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('S.No')),
                  DataColumn(label: Text('Customer Name')),
                  DataColumn(label: Text('Discount')),
                  DataColumn(label: Text('GST')),
                  DataColumn(label: Text('Transport')),
                  DataColumn(label: Text('Labour')),
                  DataColumn(label: Text('Total Amount')),
                  DataColumn(label: Text('Version')),
                  DataColumn(label: Text('status')),
                  DataColumn(label: Text('stage')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: snapshot.data!.asMap().entries.map((entry) {
                  final index = entry.key;
                  final estimate = entry.value;
                  return DataRow(
                    cells: [
                      DataCell(Text('${index + 1}')), // Serial number
                      DataCell(FutureBuilder<String?>(
                        future: CustomerDatabaseService()
                            .getCustomerNameById(estimate['customerId']),
                        builder: (context, customerSnapshot) {
                          if (customerSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Text('Loading...');
                          } else if (customerSnapshot.hasError) {
                            return Text('Error: ${customerSnapshot.error}');
                          } else if (customerSnapshot.hasData) {
                            return Text(customerSnapshot.data ?? 'Unknown');
                          } else {
                            return const Text('Not Found');
                          }
                        },
                      )),
                      DataCell(Text('₹${estimate['discount']}')),
                      DataCell(Text('₹${estimate['gstPercentage']}')),
                      DataCell(Text('₹${estimate['transportCost']}')),
                      DataCell(Text('₹${estimate['labour']}')),
                      DataCell(Text('₹${estimate['totalAmount']}')),
                      DataCell(Text(estimate['version'].toString())),
                      DataCell(Text(estimate['status'].toString())),
                      DataCell(Text(estimate['stage'].toString())),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility,
                                  color: Colors.blue),
                              onPressed: () {
                                _viewDetails(estimate['id']);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _deleteEstimate(estimate['id']);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            );
          }
        },
      ),
    );
  }
}
