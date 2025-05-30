import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/customer_database_service.dart';
import '../../widgets/MainScaffold.dart';
import '../estimate/pages/Quartz_Slab_Page.dart';
import '../estimate/pages/charcoal_estimate.dart';
import '../estimate/pages/electrical_estimate_page.dart';
import '../estimate/pages/estimate_list_page.dart';
import '../estimate/pages/false_ceiling_estimate_page.dart';
import '../estimate/pages/granite_stone_estimate.dart';
import '../estimate/pages/new_woodwork_estimate_page.dart';
import '../estimate/pages/wallpaper.dart';
import '../estimate/pages/weinscoating_estimate.dart';
import '../providers/notification_provider.dart';
import '../user/TeamListPage.dart';

class EstimateSummaryPage extends StatefulWidget {
  const EstimateSummaryPage({super.key});

  @override
  _EstimateSummaryPageState createState() => _EstimateSummaryPageState();
}

class _EstimateSummaryPageState extends State<EstimateSummaryPage> {
  List<Map<String, dynamic>> estimates = [];
  final List<Map<String, dynamic>> _customers = [];
  Map<String, dynamic>? _selectedCustomer;
  double totalAmount = 0.0;
  int estimateCount = 0;
  int? currentUserId; // set this from SharedPreferences during initState

  // List to hold chart data (X-axis: Estimate Types, Y-axis: Total Amount)
  List<BarChartGroupData> barChartData = [];
  List<Map<String, dynamic>> _designers = [];
  List<Map<String, dynamic>> assignedEstimates = [];

  // Take Note Section
  String savedNote = "";

  // Meeting Section
  final TextEditingController _agendaController = TextEditingController();
  final TextEditingController _participantsController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  String? _selectedMeetingType;
  bool _isSidebarExpanded = true;
  bool _isGridView = true;

  // Available meeting types
  final List<String> meetingTypes = [
    'Strategy',
    'Project Discussion',
    'Client Meeting',
    'Team Sync',
    'Other'
  ];

  @override
  void initState() {
    super.initState();

    () async {
      await fetchEstimates();
      await fetchAssignedEstimates();
      mergeAllEstimates(); // 🔥 Combine them into one list for display
      fetchEstimateSummary(); // for charts/cards
      _loadSavedNote();
      _fetchCustomers();
      fetchDesigners();
      loadUserId();
    }();
  }

  Future<void> loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getInt('userId'); // assuming you store it
    if (currentUserId == null) {
      print("currentUser is null");
    } else {
      print("currentUser is not null");
    }
  }

  Future<void> _fetchCustomers() async {
    final dbService = CustomerDatabaseService();
    final response = await dbService.fetchCustomers();
    setState(() {
      _customers.clear();
      _customers.addAll(response['customers']);
    });
  }

  Future<void> fetchDesigners() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.get(
      Uri.parse(
          "http://127.0.0.1:4000/api/user/users-department?departments=Designer,Pre Designer"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _designers = List<Map<String, dynamic>>.from(data['users']);
      });
    } else {
      print('Failed to load users: ${response.body}');
    }
  }

  // Fetch user-based estimates
  Future<void> fetchEstimates() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      throw Exception("Token is missing.");
    }

    const baseUrl = "http://127.0.0.1:4000/api/all-estimates";

    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          estimates = List<Map<String, dynamic>>.from(data);
        });
      } else {
        throw Exception('Failed to load estimates');
      }
    } catch (error) {
      print('Error fetching estimates: $error');
    }
  }

  // Fetch estimate summary: total amount and count
  Future<void> fetchEstimateSummary() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      throw Exception("Token is missing.");
    }

    print("Authorization: Bearer $token");

    // Replace with your API endpoint to get summary of estimates (total amount and count)
    const baseUrl = "http://127.0.0.1:4000/api/estimates-summary";

    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Ensure data contains 'totalAmount' and 'estimateCount'
        setState(() {
          totalAmount =
              double.tryParse(data['totalAmount']?.toString() ?? '0.0') ?? 0.0;
          estimateCount =
              int.tryParse(data['estimateCount']?.toString() ?? '0') ?? 0;

          // Prepare chart data from the fetched estimates
          prepareChartData();
        });
      } else {
        throw Exception('Failed to load estimate summary');
      }
    } catch (error) {
      print('Error fetching estimate summary: $error');
    }
  }

  Future<void> fetchAssignedEstimates() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('http://127.0.0.1:4000/api/assigned-estimates'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        assignedEstimates = List<Map<String, dynamic>>.from(data['estimates']);
      });
    } else {
      print('❌ Failed to load assigned estimates: ${response.body}');
    }
  }

  void mergeAllEstimates() {
    // Add a flag to each list before merging
    final ownedList = estimates.map((e) => {...e, 'owned': true}).toList();
    final assignedList =
        assignedEstimates.map((e) => {...e, 'owned': false}).toList();

    setState(() {
      estimates = [...ownedList, ...assignedList];
    });
  }

  // Prepare data for the chart
  // Modify the prepareChartData method
  void prepareChartData() {
    // Extract unique estimateTypes from the estimates
    List<String> estimateTypes = List<String>.from(
      estimates
          .map((estimate) =>
              estimate['estimateType'] ?? 'Unknown') // Get estimate types
          .toSet(), // Remove duplicates by converting to Set
    );

    // Now, we can prepare the data for the chart
    barChartData = estimateTypes.map((estimateType) {
      double totalAmount = estimates
          .where((estimate) =>
              estimate['estimateType'] ==
              estimateType) // Filter by estimateType
          .fold(
              0.0,
              (sum, estimate) =>
                  sum +
                  (double.tryParse(estimate['totalAmount'].toString()) ??
                      0.0)); // Sum the totalAmount for each estimateType

      return BarChartGroupData(
        x: estimateTypes
            .indexOf(estimateType), // X-axis value (estimate type index)
        barRods: [
          BarChartRodData(
            toY: totalAmount, // Y value (total amount for that estimate type)
            color: Colors.blue, // Color of the bar
            width: 15, // Width of the bar
            borderRadius: BorderRadius.zero,
          ),
        ],
      );
    }).toList();
  }

  // Function to return chart data (Bar Chart in this case)
  BarChartData getBarChartData() {
    return BarChartData(
      alignment: BarChartAlignment.spaceBetween,
      barGroups: barChartData,
      titlesData: const FlTitlesData(show: true),
      gridData: const FlGridData(show: true),
      borderData: FlBorderData(show: true),
    );
  }

  // Sidebar toggling function
  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
    });
  }

  // Save the note to SharedPreferences

  // Load saved note from SharedPreferences
  Future<void> _loadSavedNote() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      savedNote = prefs.getString('note') ?? ''; // Load saved note
    });
  }

  Future<void> _saveMeeting() async {
    String agenda = _agendaController.text;
    String participants = _participantsController.text;
    String description = _descriptionController.text;

    // Check if all fields are filled out
    if (agenda.isNotEmpty &&
        participants.isNotEmpty &&
        _selectedMeetingType != null &&
        description.isNotEmpty) {
      // Save meeting data to SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('meetingAgenda', agenda); // Save agenda
      await prefs.setString(
          'meetingParticipants', participants); // Save participants
      await prefs.setString(
          'meetingDescription', description); // Save description
      await prefs.setString(
          'meetingType', _selectedMeetingType!); // Save meeting type

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meeting details saved successfully!')),
      );
    } else {
      // Show error message if any field is empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields')),
      );
    }
  }

  // Show Date Picker to select date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
        ) ??
        DateTime.now();

    setState(() {
      _dateController.text = "${picked.toLocal()}"
          .split(' ')[0]; // Store date in YYYY-MM-DD format
    });
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
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            _showCustomerSelectionDialog(context, estimateType);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 28, color: iconColor),
                if (_isSidebarExpanded) ...[
                  Flexible(
                    child: Text(
                      estimateType,
                      style: const TextStyle(
                        fontSize: 14,
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

// Grid or Table View for Estimates

  // Table View for Estimates

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Sales',
      actions: [
        IconButton(
          icon: const Icon(
            Icons.groups,
          ),
          tooltip: 'View Teams',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TeamListPage()),
            );
          },
        ),
        IconButton(
          icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
          onPressed: () => setState(() => _isGridView = !_isGridView),
        ),
      ],
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Align content from the start

                children: [
                  const Text(
                    'Estimate Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  // Cart 1: Total Amount and Cart 2: Estimate Count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCartSummary('Total Amount', '₹$totalAmount'),
                      _buildCartSummary('Estimate Count', '$estimateCount'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Bar Chart for Estimate Summary
                  if (barChartData.isNotEmpty)
                    SizedBox(
                      height: 300, // Define the height for the chart
                      child: BarChart(
                          getBarChartData()), // Display the BarChart here
                    ),
                  const SizedBox(height: 20),
                  // Displaying Estimates in a Table
                  if (estimates.isNotEmpty)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        double columnWidth = constraints.maxWidth / 7;
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 1,
                            columns: [
                              DataColumn(
                                label: SizedBox(
                                    width: columnWidth,
                                    child: const Text(
                                      'Customer Name',
                                      textAlign: TextAlign.start,
                                      style: TextStyle(fontSize: 14),
                                    )),
                              ),
                              DataColumn(
                                  label: SizedBox(
                                      width: columnWidth,
                                      child: const Text(
                                        'Estimate Type',
                                        textAlign: TextAlign.start,
                                        style: TextStyle(fontSize: 14),
                                      ))),
                              DataColumn(
                                  label: SizedBox(
                                      width: columnWidth,
                                      child: const Text('Total Amount',
                                          textAlign: TextAlign.start))),
                              DataColumn(
                                  label: SizedBox(
                                      width: columnWidth,
                                      child: const Text(
                                        'Version',
                                        textAlign: TextAlign.start,
                                      ))),
                              DataColumn(
                                  label: SizedBox(
                                      width: columnWidth,
                                      child: const Text(
                                        'Stage',
                                        textAlign: TextAlign.start,
                                      ))),
                              DataColumn(
                                  label: SizedBox(
                                width: columnWidth,
                                child: const Text('Status',
                                    textAlign: TextAlign.start),
                              )),
                              DataColumn(
                                  label: SizedBox(
                                width: columnWidth,
                                child: const Text('Created By',
                                    textAlign: TextAlign.start),
                              )),
                              DataColumn(
                                label: SizedBox(
                                  width: columnWidth,
                                  child: const Text(
                                    'Assigned To',
                                    textAlign: TextAlign.start,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                              DataColumn(
                                  label: SizedBox(
                                      width: columnWidth,
                                      child: const Text('Actions',
                                          textAlign: TextAlign.start))),
                            ],
                            rows: estimates.map<DataRow>((estimate) {
                              final isOwned = estimate['owned'] == true;
                              return DataRow(cells: [
                                DataCell(FutureBuilder<String?>(
                                  future: CustomerDatabaseService()
                                      .getCustomerNameById(
                                          estimate['customerId']),
                                  builder: (context, customerSnapshot) {
                                    if (customerSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Text('Loading...');
                                    } else if (customerSnapshot.hasError) {
                                      return Text(
                                          'Error: ${customerSnapshot.error}');
                                    } else if (customerSnapshot.hasData) {
                                      return Text(
                                          customerSnapshot.data ?? 'Unknown');
                                    } else {
                                      return const Text('Not Found');
                                    }
                                  },
                                )),
                                DataCell(Text(estimate['estimateType'] ?? '—')),
                                DataCell(Text('${estimate['totalAmount']}')),
                                DataCell(Text(estimate['version'].toString())),
                                DataCell(
                                    _buildStageBadge(estimate['stage'] ?? '')),
                                DataCell(_buildstatusbadge(
                                    estimate['status'] ?? 'NA')),
                                DataCell(Text(isOwned
                                    ? "You"
                                    : estimate['assignedByName'] ??
                                        '—')), // Created By
                                DataCell(Text(estimate['assignedUserName'] ??
                                    '—')), // Assigned To
                                DataCell(Row(
                                  children: [
                                    if ((isOwned ||
                                            estimate['assignedTo'] ==
                                                currentUserId) &&
                                        estimate['stage'] != 'Designer')
                                      TextButton(
                                        child: const Text("Promote"),
                                        onPressed: () {
                                          _showAssignDialog(
                                            estimateType:
                                                estimate['estimateType'],
                                            version:
                                                estimate['version'].toString(),
                                            currentStage: estimate['stage'],
                                          );
                                        },
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () {
                                        print(
                                            'Edit estimate: ${estimate['estimateId']}');
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () {
                                        print(
                                            'Delete estimate: ${estimate['id']}');
                                      },
                                    ),
                                  ],
                                )),
                              ]);
                            }).toList(),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 20),

                  // Select Meeting Type Dropdown
                  DropdownButton<String>(
                    value: _selectedMeetingType,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedMeetingType = newValue;
                      });
                    },
                    hint: const Text('Select Meeting Type'),
                    items: meetingTypes
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  // Description Section
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 10),
                  // Select Date Section
                  TextField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      labelText: 'Meeting Date',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _saveMeeting,
                    child: const Text('Save Meeting'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageBadge(String stage) {
    Color color;
    switch (stage) {
      case 'Sales':
        color = Colors.orange;
        break;
      case 'Pre-Designer':
        color = Colors.blue;
        break;
      case 'Designer':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        stage,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildstatusbadge(String status) {
    Color color;
    switch (status) {
      case 'InProgress':
        color = Colors.orange;
        break;
      case 'Hold':
        color = Colors.blue;
        break;
      case 'Complete':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  void _showAssignDialog({
    required String estimateType,
    required String version,
    required String currentStage,
  }) {
    int? selectedUserId;
    String? selectedUserName;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text("Assign Estimate To"),
            content: _designers.isEmpty
                ? const CircularProgressIndicator()
                : DropdownButton<int>(
                    isExpanded: true,
                    value: selectedUserId,
                    hint: const Text("Select designer"),
                    items: _designers.map((designer) {
                      return DropdownMenuItem<int>(
                        value: designer['id'],
                        child: Text(designer['name'] ?? 'Unnamed'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedUserId = val;
                        selectedUserName = _designers
                            .firstWhere((d) => d['id'] == val)['name'];
                      });
                    },
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (selectedUserId != null) {
                    Navigator.pop(context);
                    promoteEstimateStage(
                      estimateType: estimateType,
                      version: version,
                      currentStage: currentStage,
                      assignedTo: selectedUserId,
                      assignedUserName: selectedUserName,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Promoted to next stage")),
                    );
                  }
                },
                child: const Text("Assign & Promote"),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> promoteEstimateStage({
    required String estimateType,
    required String version,
    required String currentStage,
    int? assignedTo,
    String? assignedUserName,
  }) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      //  Debug input
      print("Promote Estimate Called");
      print(
          " Params → estimateType: $estimateType, version: $version, currentStage: $currentStage, AssignedTo: $assignedTo, assignedUserName: $assignedUserName");

      if (token == null) {
        print("❌ No token found in SharedPreferences");
        throw Exception("Token is missing");
      }

      final url = Uri.parse("http://127.0.0.1:4000/api/promote-stage");

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "estimateType": estimateType,
          "version": version,
          "currentStage": currentStage,
          if (assignedTo != null) "assignedTo": assignedTo,
        }),
      );
      await Provider.of<NotificationProvider>(context, listen: false)
          .refreshNotifications();
      //  Debug response
      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Promoted to next stage and assigned to ${assignedUserName ?? 'user'}"),
            backgroundColor: Colors.green.shade700,
          ),
        );
        await fetchEstimates(); // Refresh estimate list
      } else {
        print(" Failed to promote: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to promote: ${response.body}")),
        );
      }
    } catch (e) {
      print(" Exception during promotion: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // Helper method to build Cart Summary
  Widget _buildCartSummary(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6.0,
            offset: const Offset(0, 2), // Shadow position
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade900,
            ),
          ),
        ],
      ),
    );
  }
}
