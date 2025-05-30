import 'package:erp_tool/modules/estimate/pages/wallpaper.dart';
import 'package:erp_tool/modules/estimate/pages/weinscoating_estimate.dart';
import 'package:flutter/material.dart';
import '../../../database/f_database_helper.dart';
import '../../../modules/estimate/pages/false_ceiling_estimate_detail.dart';
import '../../../services/customer_database_service.dart';
import 'Quartz_Slab_Page.dart';
import 'charcoal_estimate.dart';
import 'electrical_estimate_page.dart';
import 'estimate_list_page.dart';
import 'false_ceiling_estimate_page.dart';
import 'granite_stone_estimate.dart';
import 'new_woodwork_estimate_page.dart';

class FalseCeilingEstimateListPage extends StatefulWidget {
  const FalseCeilingEstimateListPage({super.key});

  @override
  _FalseCeilingEstimateListPageState createState() =>
      _FalseCeilingEstimateListPageState();
}

class _FalseCeilingEstimateListPageState
    extends State<FalseCeilingEstimateListPage> {
  final List<Map<String, dynamic>> _customers = [];
  Map<String, dynamic>? _selectedCustomer;
  late Future<List<Map<String, dynamic>>> _estimates;
  bool _isSidebarExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadEstimates();
  }

  void _loadEstimates() {
    _estimates = FDatabaseHelper
        .getFalseCeilingEstimates(); // Fetch wainscoting estimates
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
    });
  }

  // Function to delete a specific estimate
  Future<void> _deleteEstimate(int id) async {
    await FDatabaseHelper.deleteFalseCeilingEstimate(
        id); // Delete from wainscoting database
    _loadEstimates(); // Reload estimates after deletion
    setState(() {}); // Update UI
  }

  // Navigate to the detail page
  void _viewDetails(int estimateId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FalseCeilingEstimateDetailPage(
            estimateId: estimateId), // Updated page navigation
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("False Ceiling Estimates"),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: Row(
        children: [
          // Sidebar with Estimate Type options
          // AnimatedContainer(
          //   duration: const Duration(milliseconds: 300),
          //   width: _isSidebarExpanded ? 260 : 80, // Expands or collapses
          //   padding: const EdgeInsets.all(16.0),
          //   decoration: BoxDecoration(
          //     color: Colors.blue.shade900,
          //     borderRadius: const BorderRadius.only(
          //       topRight: Radius.circular(0),
          //       bottomRight: Radius.circular(20),
          //     ),
          //   ),
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       // Toggle Button
          //       Align(
          //         alignment: Alignment.centerRight,
          //         child: IconButton(
          //           icon: Icon(
          //             _isSidebarExpanded
          //                 ? Icons.chevron_left
          //                 : Icons.chevron_right,
          //             color: Colors.white,
          //           ),
          //           onPressed: _toggleSidebar,
          //         ),
          //       ),
          //       if (_isSidebarExpanded) // Show title only if expanded
          //         const Padding(
          //           padding: EdgeInsets.only(bottom: 16.0),
          //           child: Text(
          //             'Estimate Types',
          //             style: TextStyle(
          //               color: Colors.white,
          //               fontSize: 18,
          //               fontWeight: FontWeight.bold,
          //             ),
          //           ),
          //         ),
          //
          //       // Estimate Type Buttons (Responsive)
          //       _buildEstimateWidget(
          //           context, 'Woodwork', Icons.build, Colors.white),
          //       _buildEstimateWidget(context, 'Electrical',
          //           Icons.electrical_services, Colors.white),
          //       _buildEstimateWidget(context, 'False Ceiling',
          //           Icons.home_repair_service, Colors.white),
          //       _buildEstimateWidget(context, 'Wallpaper Estimate',
          //           Icons.wallpaper, Colors.white),
          //       _buildEstimateWidget(
          //           context, 'Charcoal Estimate', Icons.widgets, Colors.white),
          //       _buildEstimateWidget(context, 'Quartz Slab Estimate',
          //           Icons.kitchen, Colors.white),
          //       _buildEstimateWidget(
          //           context, 'Granite Estimate', Icons.ac_unit, Colors.white),
          //       _buildEstimateWidget(context, 'Wainscoting Estimate',
          //           Icons.format_paint, Colors.white),
          //     ],
          //   ),
          // ),

          // Main area with Estimates List Table
          // Table inside a Card with Padding
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
                        Colors.white.withOpacity(0.7)
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
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return FutureBuilder<List<Map<String, dynamic>>>(
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
                                                color: Colors.black87),
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
                                                    color: Colors.black87),
                                              ),
                                              IconButton(
                                                onPressed:
                                                    () {}, // Sorting action
                                                icon: const Icon(Icons.sort,
                                                    color: Colors.black87),
                                                iconSize: 18,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const DataColumn(
                                          label: Text(
                                            'Version',
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black87),
                                          ),
                                        ),
                                        const DataColumn(
                                          label: Text(
                                            'Description',
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black87),
                                          ),
                                        ),
                                        const DataColumn(
                                          label: Text(
                                            'GST',
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black87),
                                          ),
                                        ),
                                        const DataColumn(
                                          label: Text(
                                            'Total Amount',
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black87),
                                          ),
                                        ),
                                        const DataColumn(
                                          label: Text(
                                            'Actions',
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black87),
                                          ),
                                        ),
                                      ],
                                      rows: List<DataRow>.generate(
                                        snapshot.data!.length,
                                        (index) {
                                          final estimate =
                                              snapshot.data![index];
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
                                                  future:
                                                      CustomerDatabaseService()
                                                          .getCustomerNameById(
                                                              estimate[
                                                                  'customerId']),
                                                  builder: (context,
                                                      customerSnapshot) {
                                                    if (customerSnapshot
                                                            .connectionState ==
                                                        ConnectionState
                                                            .waiting) {
                                                      return const Text(
                                                          'Loading...');
                                                    } else if (customerSnapshot
                                                        .hasError) {
                                                      return Text(
                                                          'Error: ${customerSnapshot.error}');
                                                    } else {
                                                      return Text(
                                                          customerSnapshot
                                                                  .data ??
                                                              'Unknown',
                                                          style:
                                                              const TextStyle(
                                                                  fontSize:
                                                                      16));
                                                    }
                                                  },
                                                ),
                                              ),
                                              DataCell(Text(estimate['version']
                                                  .toString())),
                                              DataCell(Text(
                                                  estimate['description']
                                                      .toString())),
                                              DataCell(
                                                  Text('₹${estimate['gst']}')),
                                              DataCell(Text(
                                                  '₹${estimate['totalAmount']}')),
                                              DataCell(
                                                Row(
                                                  children: [
                                                    ElevatedButton(
                                                      onPressed: () =>
                                                          _viewDetails(
                                                              estimate['id']),
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            Colors.blue,
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 16,
                                                                vertical: 8),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                      ),
                                                      child: const Text(
                                                        "View",
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    ElevatedButton(
                                                      onPressed: () async {
                                                        bool confirmDelete =
                                                            await showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              AlertDialog(
                                                            title: const Text(
                                                                "Confirm Deletion"),
                                                            content: const Text(
                                                                "Are you sure you want to delete this estimate?"),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                        context,
                                                                        false),
                                                                child: const Text(
                                                                    "Cancel"),
                                                              ),
                                                              TextButton(
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                        context,
                                                                        true),
                                                                child:
                                                                    const Text(
                                                                  "Delete",
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .red),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        );

                                                        if (confirmDelete ==
                                                            true) {
                                                          _deleteEstimate(
                                                              estimate['id']);
                                                        }
                                                      },
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            Colors.red,
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 16,
                                                                vertical: 8),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                      ),
                                                      child: const Text(
                                                        "Delete",
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
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
                        );
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

  void _navigateToEstimateType(BuildContext context, String estimateType) {
    if (_selectedCustomer != null) {
      Widget page;
      switch (estimateType) {
        case 'Woodwork':
          page = NewWoodworkEstimatePage(
            customerId: _selectedCustomer!['id'],
            customerName: _selectedCustomer!['name'],
            customerEmail: _selectedCustomer!['email'],
            customerPhone: _selectedCustomer!['phone'],
          );
          break;
        case 'Electrical':
          page = ElectricalEstimatePage(
            customerId: _selectedCustomer!['id'],
            customerInfo: {
              'name': _selectedCustomer!['name'],
              'email': _selectedCustomer!['email'],
              'phone': _selectedCustomer!['phone'],
            },
            customerName: '',
            customerEmail: '',
            customerPhone: '',
          );
          break;
        case 'False Ceiling':
          page = FalseCeilingEstimatePage(
            customerId: _selectedCustomer!['id'],
            customerInfo: {
              'name': _selectedCustomer!['name'],
              'email': _selectedCustomer!['email'],
              'phone': _selectedCustomer!['phone'],
            },
            customerName: '',
            customerEmail: '',
            customerPhone: '',
          );
          break;
        case 'Charcoal Estimate':
          page = CharcoalEstimate(
            customerId: _selectedCustomer!['id'],
            customerInfo: {
              'name': _selectedCustomer!['name'],
              'email': _selectedCustomer!['email'],
              'phone': _selectedCustomer!['phone'],
            },
            customerName: '',
            customerEmail: '',
            customerPhone: '',
            estimateData: const {},
          );
          break;
        case 'Quartz Slab Estimate':
          page = QuartzSlabPage(
            customerId: _selectedCustomer!['id'],
            customerInfo: {
              'name': _selectedCustomer!['name'],
              'email': _selectedCustomer!['email'],
              'phone': _selectedCustomer!['phone'],
            },
            customerName: '',
            customerEmail: '',
            customerPhone: '',
            estimateData: const {},
          );
          break;
        case 'Granite Estimate':
          page = GraniteStoneEstimate(
            customerId: _selectedCustomer!['id'],
            customerInfo: {
              'name': _selectedCustomer!['name'],
              'email': _selectedCustomer!['email'],
              'phone': _selectedCustomer!['phone'],
            },
            customerName: '',
            customerEmail: '',
            customerPhone: '',
            estimateData: const {},
          );
          break;
        case 'Wainscoting Estimate':
          page = WeinscoatingEstimatePage(
            customerId: _selectedCustomer!['id'],
            customerInfo: {
              'name': _selectedCustomer!['name'],
              'email': _selectedCustomer!['email'],
              'phone': _selectedCustomer!['phone'],
            },
            customerName: '',
            customerEmail: '',
            customerPhone: '',
          );
          break;
        case 'Wallpaper Estimate':
          page = Wallpaper(
            customerId: _selectedCustomer!['id'],
            customerInfo: {
              'name': _selectedCustomer!['name'],
              'email': _selectedCustomer!['email'],
              'phone': _selectedCustomer!['phone'],
            },
            customerName: '',
            customerEmail: '',
            customerPhone: '',
            estimateData: const {},
          );
          break;
        default:
          page = EstimateListPage(
            customerId: _selectedCustomer!['id'],
          );
      }

      // Navigate to the estimate page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => page),
      );
    } else {
      // Show a message if no customer is selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer first')),
      );
    }
  }

  // Method to show the customer selection dialog (popup)
  void _showCustomerSelectionDialog(BuildContext context, String estimateType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select a Customer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dropdown to select a customer
              DropdownButton<Map<String, dynamic>>(
                value: _selectedCustomer,
                hint: const Text('Select a customer'),
                items: _customers.map((customer) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: customer,
                    child: Text(customer['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCustomer = value;
                  });
                },
              ),
              // If a customer is selected, show their details
              if (_selectedCustomer != null) ...[
                const SizedBox(height: 16),
                Text('Customer Name: ${_selectedCustomer!['name']}'),
                Text('Customer Email: ${_selectedCustomer!['email']}'),
                Text('Customer Phone: ${_selectedCustomer!['phone']}'),
              ]
            ],
          ),
          actions: [
            // Cancel button
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            // Confirm button to navigate to the selected estimate page
            ElevatedButton(
              onPressed: () {
                if (_selectedCustomer != null) {
                  Navigator.of(context).pop(); // Close the dialog
                  _navigateToEstimateType(context, estimateType);
                } else {
                  // Show a message if no customer is selected
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a customer')),
                  );
                }
              },
              child: const Text('Go to Estimate Page'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEstimateWidget(BuildContext context, String estimateType,
      IconData icon, Color iconColor) {
    double fontSize = MediaQuery.of(context).size.width < 600 ? 12 : 14;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            _showCustomerSelectionDialog(context, estimateType);
          },
          child: Container(
            // decoration: BoxDecoration(
            //   color: Colors.white,
            //   borderRadius: BorderRadius.circular(10),
            //   boxShadow: [
            //     BoxShadow(
            //       color: Colors.grey.shade300,
            //       blurRadius: 3,
            //       spreadRadius: 1,
            //     ),
            //   ],
            // ),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 28, color: iconColor),
                if (_isSidebarExpanded) ...[
                  Flexible(
                    child: Text(
                      estimateType,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
