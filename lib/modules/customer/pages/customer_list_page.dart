import 'package:flutter/material.dart';
import '../../../services/customer_database_service.dart';
import '../../../widgets/MainScaffold.dart';
import 'customer_detail_page.dart';
import 'dart:async';

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  _CustomerListPageState createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _filteredCustomers = [];
  bool _isGridView = true;
  int _currentPage = 1;
  int _totalCustomers = 100;
  final int _itemsPerPage = 30;
  String _selectedSortOption = 'Name (A-Z)';
  final _dbService = CustomerDatabaseService();
  Timer? _debounce;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
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

  void _paginate(int page) {
    if (page == _currentPage) return;

    setState(() {
      _currentPage = page;
    });

    _loadCustomers(page: page);
  }

  Widget _buildPagination() {
    int totalPages = (_totalCustomers / _itemsPerPage).ceil();

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

  // 🔹 Function to Show Floating Customer Add/Edit Window
  void _showFloatingCustomerWindow([Map<String, dynamic>? customer]) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing by clicking outside
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white, // Ensure white background
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Rounded corners
          ),
          child: SizedBox(
            width: 600, // Reduced width
            height: 500, // Reduced height
            child: CustomerAddEditPage(
                customer: customer), // Customer form inside dialog
          ),
        );
      },
    );
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Filter Customers"),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [],
          ),
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

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Customer Management',
      actions: [
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
          onPressed: () =>
              _showFloatingCustomerWindow(), // Open Floating Window
        ),
        IconButton(
          icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
          onPressed: () => setState(() => _isGridView = !_isGridView),
        ),
      ],
      child: Row(
        children: [
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
                  const SizedBox(height: 12),
                  Expanded(
                    child: _isGridView ? _buildGridView() : _buildListView(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarOption(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(title, style: const TextStyle(color: Colors.black)),
      onTap: () {},
    );
  }

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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              CustomerDetailPage(customer: customer)),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person,
                          size: 40, color: Colors.orangeAccent),
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

  Widget _buildListView() {
    return ListView.builder(
      itemCount: _filteredCustomers.length,
      itemBuilder: (context, index) {
        final customer = _filteredCustomers[index];
        return ListTile(
          title: Text(customer['name']),
          subtitle: Text(customer['email']),
          trailing: IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () =>
                _showFloatingCustomerWindow(customer), // Open Floating Window
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => CustomerDetailPage(customer: customer)),
          ),
        );
      },
    );
  }
}

//Customer Add Page
class CustomerAddEditPage extends StatefulWidget {
  final Map<String, dynamic>? customer;
  const CustomerAddEditPage({super.key, this.customer});

  @override
  _CustomerAddEditPageState createState() => _CustomerAddEditPageState();
}

class _CustomerAddEditPageState extends State<CustomerAddEditPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  bool _isSaving = false;
  int? _selectedCustomerId;
  String _selectedType = 'Hot'; // Default type selection

  @override
  void initState() {
    super.initState();
    _selectedCustomerId = widget.customer?['id'];

    // Fields that require TextEditingControllers
    List<String> fields = [
      'name',
      'email',
      'phone',
      'altPhone',
      'street',
      'city',
      'postalCode',
      'siteStreet',
      'siteCity',
      'sitePostalCode',
      'projectName',
      'projectType'
    ];

    for (String field in fields) {
      _controllers[field] =
          TextEditingController(text: widget.customer?[field] ?? '');
    }

    _selectedType = widget.customer?['type'] ?? 'Hot';
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackbar('Please fill in all required fields.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final customer = {
        'name': _controllers['name']!.text.trim(),
        'email': _controllers['email']!.text.trim(),
        'phone': _controllers['phone']!.text.trim(),
        'altPhone': _controllers['altPhone']!.text.trim(),
        'address': {
          'street': _controllers['street']!.text.trim(),
          'city': _controllers['city']!.text.trim(),
          'postalCode': _controllers['postalCode']!.text.trim(),
        },
        'siteDetails': {
          'siteStreet': _controllers['siteStreet']!.text.trim(),
          'siteCity': _controllers['siteCity']!.text.trim(),
          'sitePostalCode': _controllers['sitePostalCode']!.text.trim(),
          'projectName': _controllers['projectName']!.text.trim(),
          'projectType': _controllers['projectType']!.text.trim(),
        },
        'type': _selectedType,
      };

      bool success = _selectedCustomerId == null
          ? await CustomerDatabaseService.instance.addCustomer(customer)
          : await CustomerDatabaseService.instance
              .updateCustomer(_selectedCustomerId!, customer);

      if (success) {
        _showSnackbar(_selectedCustomerId == null
            ? 'Customer added successfully!'
            : 'Customer updated successfully!');
        Navigator.pop(context);
      } else {
        _showSnackbar('Failed to save customer.');
      }
    } catch (e) {
      _showSnackbar('Error saving customer.');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sectionTitle("Customer Details"),
              _buildTextField('name', "Name", Icons.person),
              _buildTextField('email', "Email", Icons.email),
              _buildRow([
                _buildTextField('phone', "Phone", Icons.phone),
                _buildTextField('altPhone', "Alt Phone", Icons.phone),
              ]),
              _buildRow([
                _buildTextField('street', "Street", Icons.home),
                _buildTextField('city', "City", Icons.location_city),
              ]),
              _buildTextField('postalCode', "Postal Code", Icons.location_on),
              const SizedBox(height: 20),
              _sectionTitle("Site Details"),
              _buildRow([
                _buildTextField('siteStreet', "Street", Icons.location_on),
                _buildTextField('siteCity', "City", Icons.location_city),
              ]),
              _buildTextField(
                  'sitePostalCode', "Postal Code", Icons.markunread_mailbox),
              _buildTextField('projectName', "Project Name", Icons.assignment),
              _buildTextField('projectType', "Project Type", Icons.category),
              const SizedBox(height: 10),
              _sectionTitle("Type"),
              _buildTypeSelection(),
              const SizedBox(height: 20),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
      ),
    );
  }

  Widget _buildTextField(String field, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: TextFormField(
        controller: _controllers[field],
        validator: (value) => _validateField(field, value),
        keyboardType: _getKeyboardType(field),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 16),
          prefixIcon: Icon(icon, color: Colors.orange, size: 18),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.orange),
          ),
        ),
      ),
    );
  }

  String? _validateField(String field, String? value) {
    if (value == null || value.trim().isEmpty) {
      return "$field is required";
    }

    if (field == "email") {
      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
        return "Enter a valid email address";
      }
    }

    if (field == "phone" || field == "altPhone") {
      if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
        return "Enter a valid 10-digit phone number";
      }
    }

    if (field == "postalCode" || field == "sitePostalCode") {
      if (!RegExp(r'^[0-9]{5,6}$').hasMatch(value)) {
        return "Enter a valid postal code";
      }
    }

    return null; // No validation errors
  }

  TextInputType _getKeyboardType(String field) {
    if (field == "email") {
      return TextInputType.emailAddress;
    } else if (field == "phone" ||
        field == "altPhone" ||
        field == "postalCode" ||
        field == "sitePostalCode") {
      return TextInputType.number;
    }
    return TextInputType.text;
  }

  Widget _buildRow(List<Widget> children) {
    return Row(
      children: children
          .asMap()
          .entries
          .map((entry) => [
                if (entry.key != 0)
                  const SizedBox(
                      width: 10), // Add spacing except before the first item
                Expanded(child: entry.value),
              ])
          .expand((widget) => widget) // Flatten list
          .toList(),
    );
  }

  Widget _buildTypeSelection() {
    final Map<String, Color> typeColors = {
      "Hot": Colors.red,
      "Warm": Colors.orange,
      "Cold": Colors.blue,
      "Junk": Colors.black,
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: ["Hot", "Warm", "Cold", "Junk"].map((type) {
        return ChoiceChip(
          label: Text(type),
          selected: _selectedType == type,
          selectedColor: typeColors[type],
          checkmarkColor: Colors.white,
          onSelected: (selected) {
            setState(() => _selectedType = type);
          },
          labelStyle: TextStyle(
              color: _selectedType == type ? Colors.white : Colors.black),
          backgroundColor: Colors.grey.shade300,
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel",
              style: TextStyle(color: Colors.grey, fontSize: 14)),
        ),
        ElevatedButton(
          onPressed: _saveCustomer,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text("Save",
              style: TextStyle(fontSize: 14, color: Colors.white)),
        ),
      ],
    );
  }
}
