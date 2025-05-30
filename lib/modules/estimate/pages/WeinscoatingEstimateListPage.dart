import 'package:flutter/material.dart';
import '../../../database/wc_database_helper.dart'; // Updated import for Wainscoting
import '../../../modules/estimate/pages/wc_estimate_detail_page.dart';
import '../../../services/customer_database_service.dart';
import '../../../widgets/MainScaffold.dart';
import '../../../widgets/sidebar_menu.dart';

class WeinscoatingEstimateListPage extends StatefulWidget {
  const WeinscoatingEstimateListPage({super.key});

  @override
  _WeinscoatingEstimateListPageState createState() =>
      _WeinscoatingEstimateListPageState();
}

class _WeinscoatingEstimateListPageState
    extends State<WeinscoatingEstimateListPage> {
  final List<Map<String, dynamic>> _customers = [];
  Map<String, dynamic>? _selectedCustomer;
  late Future<List<Map<String, dynamic>>> _estimates;
  bool _isSidebarExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadEstimates();
    _fetchCustomers();
  }

  void _loadEstimates() {
    _estimates =
        WcDatabaseHelper.fetchAllEstimates(); // Fetch wainscoting estimates
  }

  Future<void> _fetchCustomers() async {
    final dbService = CustomerDatabaseService();
    final response = await dbService.fetchCustomers();
    setState(() {
      _customers.clear();
      _customers.addAll(response['customers']);
    });
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
    });
  }

  // Function to delete a specific estimate
  Future<void> _deleteEstimate(int id) async {
    await WcDatabaseHelper.DeleteEstimateById(
        id); // Delete from wainscoting database
    _loadEstimates(); // Reload estimates after deletion
    setState(() {}); // Update UI
  }

  // Navigate to the detail page
  void _viewDetails(int estimateId) {
    SidebarController.of(context)?.openPage(
      WeinscoatingEstimateDetailPage(
          estimateId: estimateId), // Updated page navigation
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: "Weinscoating Estimates",
      leading: IconButton(
          onPressed: () => SidebarController.of(context)?.goBack(),
          icon: const Icon(Icons.arrow_back)),
      child: Row(
        children: [
          // Main area with Estimates List Table
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 6, // Higher shadow for premium feel
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.9),
                        Colors.white.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _estimates,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Center(
                              child: Text('No estimates found.'));
                        } else {
                          return Align(
                            alignment: Alignment.topCenter,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columnSpacing: 20,
                                  headingRowColor:
                                      WidgetStateProperty.all(Colors.white),
                                  border: const TableBorder(
                                    bottom: BorderSide(
                                        color: Colors.white60, width: 1.5),
                                  ),
                                  columns: [
                                    const DataColumn(
                                      label: Text(
                                        'S.No',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Row(
                                        children: [
                                          const Text(
                                            'Customer Name',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () {}, // Sorting action
                                            icon: const Icon(Icons.sort,
                                                color: Colors.black87),
                                            iconSize: 18,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const DataColumn(
                                      label: Text(
                                        'GST',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    const DataColumn(
                                      label: Text(
                                        'Discount',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    const DataColumn(
                                      label: Text(
                                        'Transport',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    const DataColumn(
                                      label: Text(
                                        'Total Amount',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    const DataColumn(
                                      label: Text(
                                        'Actions',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                  rows: List<DataRow>.generate(
                                    snapshot.data!.length,
                                    (index) {
                                      final estimate = snapshot.data![index];
                                      return DataRow(
                                        color: index.isEven
                                            ? WidgetStateProperty.all(
                                                Colors.grey[200])
                                            : WidgetStateProperty.all(
                                                Colors.white),
                                        cells: [
                                          DataCell(Text('${index + 1}',
                                              style: const TextStyle(
                                                  fontSize: 16))),
                                          DataCell(
                                            FutureBuilder<String?>(
                                              future: CustomerDatabaseService()
                                                  .getCustomerNameById(
                                                      estimate['customerId']),
                                              builder:
                                                  (context, customerSnapshot) {
                                                if (customerSnapshot
                                                        .connectionState ==
                                                    ConnectionState.waiting) {
                                                  return const Text(
                                                      'Loading...');
                                                } else if (customerSnapshot
                                                    .hasError) {
                                                  return Text(
                                                      'Error: ${customerSnapshot.error}');
                                                } else {
                                                  return Text(
                                                      customerSnapshot.data ??
                                                          'Unknown',
                                                      style: const TextStyle(
                                                          fontSize: 16));
                                                }
                                              },
                                            ),
                                          ),
                                          DataCell(Text(
                                              estimate['gst']?.toString() ??
                                                  '0')),
                                          DataCell(Text(estimate['discount']
                                                  ?.toString() ??
                                              '0')),
                                          DataCell(Text(estimate['transport']
                                                  ?.toString() ??
                                              '0')),
                                          DataCell(Text(
                                              '₹${estimate['totalAmount']?.toString() ?? '0'}')),
                                          DataCell(
                                            Row(
                                              children: [
                                                ElevatedButton(
                                                  onPressed: () => _viewDetails(
                                                      estimate['id']),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.green,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 16,
                                                        vertical: 8),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    "View",
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      _deleteEstimate(
                                                          estimate['id']),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 16,
                                                        vertical: 8),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    "Delete",
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
