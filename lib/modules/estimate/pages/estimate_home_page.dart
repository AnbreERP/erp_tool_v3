import 'package:erp_tool/modules/estimate/pages/Flooring_Estimate.dart';
import 'package:erp_tool/modules/estimate/pages/grass_estimate.dart';
import 'package:erp_tool/modules/estimate/pages/mosquito_Net_Estimate.dart';
import 'package:flutter/material.dart';
import 'package:erp_tool/modules/estimate/pages/wallpaper.dart';
import 'package:erp_tool/modules/estimate/pages/weinscoating_estimate.dart';
import 'package:provider/provider.dart';
import '../../../services/customer_database_service.dart'; // Assuming this service fetches customer data
import '../../../widgets/MainScaffold.dart';
import '../../auth/pages/login_page.dart';
import '../../auth/providers/auth_provider.dart';
import '../../customer/pages/customer_list_page.dart';
import 'CustomerEstimatePage.dart';
import 'Quartz_Slab_Page.dart';
import 'charcoal_estimate.dart';
import 'electrical_estimate_page.dart';
import 'estimate_list_page.dart';
import 'false_ceiling_estimate_page.dart';
import 'granite_stone_estimate.dart';
import 'new_woodwork_estimate_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:erp_tool/widgets/sidebar_menu.dart';

class EstimateHomePage extends StatefulWidget {
  const EstimateHomePage({super.key});

  @override
  _EstimateHomePageState createState() => _EstimateHomePageState();
}

class _EstimateHomePageState extends State<EstimateHomePage> {
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _filteredCustomers = []; // For filtered results
  bool _isGridView = true;
  int _currentPage = 1;
  int _totalCustomers = 100;
  final int _itemsPerPage = 30;
  Map<String, dynamic>? _selectedCustomer;
  DateTime? _selectedDate;
  Timer? _debounce;
  final _dbService = CustomerDatabaseService();
  bool _isSidebarExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
    });
  }

  Future<void> _loadCustomers({int page = 1}) async {
    final response =
        await _dbService.fetchCustomers(page: page, perPage: _itemsPerPage);

    setState(() {
      _customers =
          response['customers']; // Fetch customers for the current page
      _filteredCustomers = List.from(_customers);
      _currentPage = page;
      _totalCustomers =
          response['totalCustomers']; // Fetch total customers count
    });
  }

  // Switch between grid and table views
  void _toggleView() {
    setState(() {
      _isGridView = !_isGridView;
    });
  }

  void _paginate(int page) {
    setState(() {
      _loadCustomers(page: page);
    });
  }

  void _filterCustomersByDate(DateTime date) {
    setState(() {
      _filteredCustomers = _customers.where((customer) {
        // Ensure 'addedDate' exists in the map
        if (customer.containsKey('createdAt')) {
          // Convert 'addedDate' string to DateTime
          DateTime customerDate = DateTime.parse(customer['createdAt']);
          return customerDate.year == date.year &&
              customerDate.month == date.month &&
              customerDate.day == date.day;
        }
        return false;
      }).toList();
    });
  }

  // Filter customers based on the search query
  void _filterCustomers(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        if (query.isEmpty) {
          _filteredCustomers = List.from(_customers);
        } else {
          _filteredCustomers = _customers
              .where((customer) =>
                  customer['name']
                      .toLowerCase()
                      .contains(query.toLowerCase()) ||
                  customer['email'].toLowerCase().contains(query.toLowerCase()))
              .toList();
        }
        _sortCustomers(); // Apply sorting after filtering
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // Method to navigate to the selected estimate type page
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
        case 'Flooring Estimate':
          page = FlooringEstimate(
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
        case 'Grass Estimate':
          page = GrassEstimate(
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
        case 'MosquitoNet Estimate':
          page = MosquitoNetEstimate(
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            _showCustomerSelectionDialog(context, estimateType);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: iconColor),
                if (_isSidebarExpanded) ...[
                  Flexible(
                    child: Text(
                      estimateType,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
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

  Future<Map<String, dynamic>> _fetchLatestEstimateForCustomer(
      int customerId) async {
    try {
      const String baseUrl = "http://127.0.0.1:4000/api";
      final response = await http.get(Uri.parse("$baseUrl/latest/$customerId"));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            "Failed to fetch latest estimate for customer $customerId");
      }
    } catch (e) {
      print("Error fetching latest estimate: $e");
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Estimate Page',
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            final authProvider =
                Provider.of<AuthProvider>(context, listen: false);
            await authProvider.logout();
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const LoginPage()));
          },
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("Add Customer",
              style: TextStyle(color: Colors.white, fontSize: 14)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CustomerAddEditPage()));
          },
        ),
        const SizedBox(width: 10),
        IconButton(
          icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
          onPressed: () => setState(() => _isGridView = !_isGridView),
        ),
      ],
      leading: IconButton(
          onPressed: () => SidebarController.of(context)?.goBack(),
          icon: const Icon(Icons.arrow_back)),
      child: Row(
        children: [
          // AnimatedContainer(
          //   duration: const Duration(milliseconds: 300),
          //   width: _isSidebarExpanded ? 260 : 80,
          //   padding: const EdgeInsets.all(16.0),
          //   decoration: BoxDecoration(
          //     color: Colors.grey.shade50,
          //     borderRadius: const BorderRadius.only(
          //       topRight: Radius.circular(0),
          //       bottomRight: Radius.circular(20),
          //     ),
          //   ),
          //   child: SingleChildScrollView(
          //     // Add scroll view here
          //     child: Column(
          //       crossAxisAlignment: CrossAxisAlignment.start,
          //       children: [
          //         // Toggle Button
          //         Align(
          //           alignment: Alignment.centerRight,
          //           child: IconButton(
          //             icon: Icon(
          //               _isSidebarExpanded
          //                   ? Icons.chevron_left
          //                   : Icons.chevron_right,
          //               color: Colors.black,
          //             ),
          //             onPressed: _toggleSidebar,
          //           ),
          //         ),
          //         if (_isSidebarExpanded) // Show title only if expanded
          //           const Padding(
          //             padding: EdgeInsets.only(bottom: 16.0),
          //             child: Text(
          //               'Estimate Types',
          //               style: TextStyle(
          //                   color: Colors.black,
          //                   fontSize: 16,
          //                   fontWeight: FontWeight.bold),
          //             ),
          //           ),
          //
          //         // Estimate Type Buttons (Responsive)
          //         _buildEstimateWidget(
          //             context, 'Woodwork', Icons.build, Colors.orange),
          //         _buildEstimateWidget(context, 'Electrical',
          //             Icons.electrical_services, Colors.orange),
          //         _buildEstimateWidget(context, 'False Ceiling',
          //             Icons.home_repair_service, Colors.orange),
          //         _buildEstimateWidget(context, 'Wallpaper Estimate',
          //             Icons.wallpaper, Colors.orange),
          //         _buildEstimateWidget(context, 'Charcoal Estimate',
          //             Icons.widgets, Colors.orange),
          //         _buildEstimateWidget(context, 'Quartz Slab Estimate',
          //             Icons.kitchen, Colors.orange),
          //         _buildEstimateWidget(context, 'Granite Estimate',
          //             Icons.ac_unit, Colors.orange),
          //         _buildEstimateWidget(context, 'Wainscoting Estimate',
          //             Icons.format_paint, Colors.orange),
          //         _buildEstimateWidget(context, 'Grass Estimate',
          //             Icons.format_paint, Colors.orange),
          //         _buildEstimateWidget(context, 'Flooring Estimate',
          //             Icons.format_paint, Colors.orange),
          //         _buildEstimateWidget(context, 'MosquitoNet Estimate',
          //             Icons.format_paint, Colors.orange),
          //       ],
          //     ),
          //   ),
          // ),
          // Right Side: Customers List & Search, Sort, Filter
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  // 🔹 Search, Filter, and Sort Row with White Background
                  Row(
                    children: [
                      const SizedBox(width: 10),
                      // 🔹 Search Bar (Now with White Background)
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          width: 300,
                          child: TextField(
                            onChanged: (value) {
                              _filterCustomers(
                                  value); // Implement search functionality
                            },
                            style: const TextStyle(
                                fontSize: 12), // Adjusted font size
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search,
                                  color: Colors.orange, size: 16),
                              hintText: 'Search...',
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 5), // Adjusted padding
                              filled: true,
                              fillColor:
                                  Colors.white, // Explicit white fill color
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    6.0), // Adjusted radius
                                borderSide: BorderSide(
                                    color: Colors.grey.shade400, width: 1),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        width: 10,
                      ),
                      // 🔹 Calendar Button (Filter by Date)
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border:
                              Border.all(color: Colors.grey.shade400, width: 1),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.calendar_today,
                              color: Colors.orange, size: 18),
                          padding: EdgeInsets.zero,
                          onPressed: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                              builder: (context, child) {
                                return Dialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        12), // Rounded edges for popup
                                  ),
                                  child: Container(
                                    width: 430, // ✅ Smaller width
                                    height: 300, // ✅ Smaller height
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Theme(
                                      data: ThemeData.light().copyWith(
                                        primaryColor:
                                            Colors.orange, // Top bar color
                                        hintColor: Colors
                                            .orange, // Selected date highlight
                                        colorScheme: const ColorScheme.light(
                                            primary: Colors.orange), // Background color
                                        textTheme: const TextTheme(
                                          bodyLarge: TextStyle(
                                              fontSize: 14), // ✅ Smaller text
                                          bodyMedium: TextStyle(
                                              fontSize: 10), // ✅ Smaller text
                                          labelLarge: TextStyle(
                                              fontSize:
                                                  11), // ✅ Buttons smaller
                                          titleLarge: TextStyle(
                                              fontSize:
                                                  14), // ✅ Smaller default date
                                          titleMedium: TextStyle(
                                              fontSize:
                                                  12), // ✅ Smaller month/year
                                        ), dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
                                      ),
                                      child: child!,
                                    ),
                                  ),
                                );
                              },
                            );

                            if (pickedDate != null) {
                              setState(() {
                                _selectedDate =
                                    pickedDate; // Store selected date
                                _filterCustomersByDate(_selectedDate!);
                              });
                            }
                          },
                        ),
                      ),

                      const SizedBox(width: 600),

                      // 🔹 Right-aligned Filter & Sorting options
                      Row(
                        children: [
                          // 🔹 Filter Estimate Button with Sorting Dropdown
                          Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.grey.shade400, width: 1),
                              borderRadius: BorderRadius.circular(6),
                              color: Colors.white,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.filter_list,
                                    color: Colors.orange, size: 16),
                                const SizedBox(width: 4),
                                DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedSortOption,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedSortOption = newValue!;
                                        _sortCustomers(); // Trigger sorting when user selects an option
                                      });
                                    },
                                    dropdownColor: Colors.white,
                                    elevation: 0,
                                    items: <String>[
                                      'Name (A-Z)',
                                      'Name (Z-A)',
                                      'Newest',
                                      'Oldest'
                                    ].map<DropdownMenuItem<String>>(
                                        (String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black)),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),

                          // 🔹 Sorting Button (Up/Down Arrow)
                          Container(
                            height: 40,
                            width: 30,
                            decoration: BoxDecoration(
                              color: Colors.white, // Background color added
                              borderRadius:
                                  BorderRadius.circular(6), // Rounded corners
                              border: Border.all(
                                  color: Colors.grey,
                                  width: 1), // Border to match other elements
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.unfold_more,
                                  color: Colors.black,
                                  size: 18), // Adjusted icon size
                              padding:
                                  EdgeInsets.zero, // Removes default padding
                              onPressed: () {
                                _showFilterDialog(); // Implement filter function
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(
                      height: 12), // Add spacing before the customer list

                  // 🔹 Customer List (Grid or Table View)
                  Expanded(
                    child: _isGridView ? _buildGridView() : _buildTableView(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _selectedSortOption = 'Name (A-Z)'; // Default sorting

  void _sortCustomers() {
    setState(() {
      if (_selectedSortOption == 'Name (A-Z)') {
        _filteredCustomers.sort((a, b) =>
            a['name'].toLowerCase().compareTo(b['name'].toLowerCase()));
      } else if (_selectedSortOption == 'Name (Z-A)') {
        _filteredCustomers.sort((a, b) =>
            b['name'].toLowerCase().compareTo(a['name'].toLowerCase()));
      } else if (_selectedSortOption == 'Newest') {
        _filteredCustomers.sort((a, b) => DateTime.parse(b['addedDate'])
            .compareTo(DateTime.parse(a['addedDate'])));
      } else if (_selectedSortOption == 'Oldest') {
        _filteredCustomers.sort((a, b) => DateTime.parse(a['addedDate'])
            .compareTo(DateTime.parse(b['addedDate'])));
      }
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Filter Customers"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                // Apply filter logic here
                Navigator.of(context).pop();
              },
              child: const Text("Apply"),
            ),
          ],
        );
      },
    );
  }

  // Build Table View
  Widget _buildTableView() {
    int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;
    List<Map<String, dynamic>> paginatedCustomers = _filteredCustomers.sublist(
        startIndex, endIndex.clamp(0, _filteredCustomers.length));

    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white, // White background for entire table
              borderRadius: BorderRadius.circular(12), // Rounded corners
            ),
            padding: const EdgeInsets.all(16), // Inner padding
            margin: const EdgeInsets.all(10), // Space around the container
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Align to the top
              children: [
                // Table Title
                const Padding(
                  padding: EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    'Customer List',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
                // Scrollable Table
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 30.0, // Adjusted spacing
                      headingRowColor: WidgetStateColor.resolveWith(
                          (states) =>
                              Colors.grey.shade200), // Header background color
                      headingTextStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                      dataTextStyle: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                      border: TableBorder.all(
                          color: Colors.grey.shade300), // Table border
                      columns: const [
                        DataColumn(label: Text('S. No.')),
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Phone')),
                        DataColumn(label: Text('View')),
                      ],
                      rows: List<DataRow>.generate(
                        paginatedCustomers.length,
                        (index) {
                          final customer = paginatedCustomers[index];
                          return DataRow(
                            color: WidgetStateColor.resolveWith((states) {
                              return index % 2 == 1
                                  ? Colors.grey.shade50
                                  : Colors.white; // Alternating row colors
                            }),
                            cells: [
                              DataCell(Text('${startIndex + index + 1}')),
                              DataCell(Text(customer['name'])),
                              DataCell(Text(customer['email'])),
                              DataCell(Text(customer['phone'])),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.remove_red_eye,
                                      color: Colors.blue),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CustomerEstimatePage(
                                          customerId: customer['id'],
                                          customerName: customer['name'],
                                          customerEmail: customer['email'],
                                          customerPhone: customer['phone'],
                                          customerInfo: const {},
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildPagination(), // Add pagination controls here
      ],
    );
  }

  // Build Grid View
  Widget _buildGridView() {
    int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;
    List<Map<String, dynamic>> paginatedCustomers = _filteredCustomers.sublist(
        startIndex, endIndex.clamp(0, _filteredCustomers.length));

    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white, // White background for all folders
              borderRadius:
                  BorderRadius.circular(12), // Rounded corners for container
            ),
            padding: const EdgeInsets.all(16), // Padding for inner content
            margin: const EdgeInsets.all(10), // Space around the container
            child: GridView.builder(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(), // Prevents internal scrolling
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8, // Adjust for number of columns
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.5, // Adjust to control size of grid items
              ),
              itemCount: paginatedCustomers.length,
              itemBuilder: (context, index) {
                final customer = paginatedCustomers[index];
                return GestureDetector(
                  onTap: () {
                    SidebarController.of(context)?.openPage(
                      CustomerEstimatePage(
                        customerId: customer['id'],
                        customerName: customer['name'],
                        customerEmail: customer['email'],
                        customerPhone: customer['phone'],
                        customerInfo: const {},
                      ),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.folder,
                          size: 50, color: Colors.orangeAccent),
                      const SizedBox(height: 10),
                      Text(
                        customer['name'],
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        _buildPagination(), // Add pagination controls here
      ],
    );
  }

  // Method to get customers who have estimates
  Future<List<Map<String, dynamic>>> _getCustomersWithEstimates() async {
    try {
      // ✅ Send API request to fetch customers with estimates
      final response = await http
          .get(Uri.parse("http://127.0.0.1:4000/api/customers-with-estimates"));

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        throw Exception("Failed to fetch customers with estimates");
      }
    } catch (e) {
      print("Error fetching customers with estimates: $e");
      return [];
    }
  }

  Widget _buildPagination() {
    int totalPages = (_filteredCustomers.length / _itemsPerPage).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left,
                color: _currentPage > 1 ? Colors.orange : Colors.grey),
            onPressed:
                _currentPage > 1 ? () => _paginate(_currentPage - 1) : null,
          ),
          for (int i = 1; i <= totalPages; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: GestureDetector(
                onTap: () => _paginate(i),
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor:
                      _currentPage == i ? Colors.orange : Colors.grey.shade300,
                  child: Text(
                    '$i',
                    style: TextStyle(
                        color: _currentPage == i ? Colors.white : Colors.black,
                        fontSize: 9),
                  ),
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.chevron_right,
                color: _currentPage < totalPages ? Colors.orange : Colors.grey),
            onPressed: _currentPage < totalPages
                ? () => _paginate(_currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }
}
