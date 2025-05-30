import 'package:erp_tool/widgets/MainScaffold.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class SuperAdminDashboard extends StatefulWidget {
  final bool isAuthenticated;
  final String? userRole;
  final String? userName;
  const SuperAdminDashboard({
    super.key,
    required this.isAuthenticated,
    this.userRole,
    this.userName,
  });

  @override
  SuperAdminDashboardState createState() => SuperAdminDashboardState();
}

class SuperAdminDashboardState extends State<SuperAdminDashboard> {
  List<Map<String, dynamic>> estimates = [];
  double totalAmount = 0.0;
  int estimateCount = 0;
  int customerCount = 0;
  int userCount = 0;
  String _selectedType = 'All';
  String _selectedStatus = 'All';
  DateTime selectedDate = DateTime.now();
  String searchQuery = '';
  List<BarChartGroupData> barChartData = [];
  Uint8List? _webImageBytes;
  int selectedCardIndex = -1;
  List<double> weeklyChartAmounts = [];
  List<String> estimateTypes = [];
  List<Map<String, dynamic>> customer = [];
  List<Map<String, dynamic>> _allCustomers = [];
  int? _selectedCustomerId;
  String _selectedVersion = 'All';
  int _currentPage = 1;
  final int _rowsPerPage = 10;

  List<Map<String, dynamic>> get _paginatedCustomers {
    final start = (_currentPage - 1) * _rowsPerPage;
    final end = start + _rowsPerPage;
    return customer.sublist(
        start, end > customer.length ? customer.length : end);
  }

  int get _totalPages => (customer.length / _rowsPerPage).ceil();

  @override
  void initState() {
    super.initState();
    fetchEstimates();
    fetchCustomerCount();
    fetchUserCount();
    fetchCustomerData();
  }

  void _pickImageWeb() {
    final html.FileUploadInputElement uploadInput =
        html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((event) {
      final file = uploadInput.files?.first;
      if (file != null) {
        final reader = html.FileReader();

        reader.onLoadEnd.listen((e) {
          setState(() {
            _webImageBytes = reader.result as Uint8List;
          });
        });

        reader.readAsArrayBuffer(file);
      }
    });
  }

  // Fetch estimates from the API
  Future<void> fetchEstimates() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      throw Exception("Token is missing.");
    }

    const baseUrl =
        "http://127.0.0.1:4000/api/all-estimates"; // Replace with your API endpoint

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
          estimateCount = estimates.length;
          totalAmount = estimates.fold(
            0.0,
            (sum, estimate) =>
                sum +
                (double.tryParse(estimate['totalAmount'].toString()) ?? 0.0),
          );

          // Prepare chart data after fetching estimates
          prepareChartData();
        });
      } else {
        throw Exception('Failed to load estimates');
      }
    } catch (error) {
      print('Error fetching estimates: $error');
    }
  }

  // Fetch the total customer count
  Future<void> fetchCustomerCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      throw Exception("Token is missing.");
    }

    const baseUrl =
        "http://127.0.0.1:4000/api/customer-count"; // Replace with your API endpoint

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
          customerCount = data['count'] ?? 0;
        });
      } else {
        throw Exception('Failed to load customer count');
      }
    } catch (error) {
      print('Error fetching customer count: $error');
    }
  }

  // Fetch the total user count
  Future<void> fetchUserCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      throw Exception("Token is missing.");
    }

    const baseUrl = "http://127.0.0.1:4000/api/user-count";

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
          userCount = data['count'] ?? 0;
        });
      } else {
        throw Exception('Failed to load user count');
      }
    } catch (error) {
      print('Error fetching user count: $error');
    }
  }

  Future<void> fetchCustomerData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    const url = 'http://127.0.0.1:4000/api/customers';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData is Map<String, dynamic> &&
            responseData['customers'] is List) {
          final List<Map<String, dynamic>> fetched =
              List<Map<String, dynamic>>.from(responseData['customers']);
          setState(() {
            _allCustomers = fetched; // ✅ preserve original
            customer = fetched; // ✅ assign for display
          });
        } else {
          print('❌ Unexpected customer data format: $responseData');
        }
      } else {
        throw Exception('Failed to load customer data');
      }
    } catch (error) {
      print('❌ Error fetching customer data: $error');
    }
  }

  Widget buildStatusBadge(String status) {
    final isWon = status == 'hot';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isWon ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: isWon ? Colors.green : Colors.red,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget buildTypeChip(String type) {
    Color bg;
    Color textColor = Colors.black;
    switch (type.toLowerCase()) {
      case 'hot':
        bg = Colors.red.shade100;
        textColor = Colors.red;
        break;
      case 'warm':
        bg = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      case 'cold':
        bg = Colors.blue.shade100;
        textColor = Colors.blue;
        break;
      case 'junk':
        bg = Colors.grey.shade300;
        textColor = Colors.grey.shade700;
        break;
      default:
        bg = Colors.grey.shade200;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type.toUpperCase(),
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w500, color: textColor),
      ),
    );
  }

  Widget _buildCustomerSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Card(
      color: isDark ? Colors.grey[900] : Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? Colors.lightBlueAccent : Colors.orange,
          width: 1,
        ),
      ),
      margin: const EdgeInsets.only(top: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔍 Filters
            isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        style:
                            TextStyle(color: theme.textTheme.bodyMedium!.color),
                        decoration: InputDecoration(
                          hintText: 'Search',
                          prefixIcon: const Icon(Icons.search),
                          hintStyle: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black54),
                          filled: true,
                          fillColor: isDark ? Colors.grey[850] : Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) {
                          searchQuery = val.toLowerCase();
                          _filterData();
                        },
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: Icon(Icons.calendar_today_outlined,
                            size: 16, color: theme.iconTheme.color),
                        label: Text(
                          DateFormat('dd-MM-yyyy').format(selectedDate),
                          style: TextStyle(
                              color: theme.textTheme.bodyMedium!.color),
                        ),
                        onPressed: _pickDate,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: isDark ? Colors.grey : Colors.orange),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedStatus,
                        dropdownColor: theme.cardColor,
                        style:
                            TextStyle(color: theme.textTheme.bodyMedium!.color),
                        items: ['All', 'Won', 'Lost'].map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value ?? 'All';
                            _filterData();
                          });
                        },
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: TextField(
                          style: TextStyle(
                              color: theme.textTheme.bodyMedium!.color),
                          decoration: InputDecoration(
                            hintText: 'Search',
                            prefixIcon: const Icon(Icons.search),
                            hintStyle: TextStyle(
                                color:
                                    isDark ? Colors.white54 : Colors.black54),
                            filled: true,
                            fillColor: isDark ? Colors.grey[850] : Colors.white,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (val) {
                            searchQuery = val.toLowerCase();
                            _filterData();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 160,
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.calendar_today_outlined,
                              size: 16, color: theme.iconTheme.color),
                          label: Text(
                            DateFormat('dd-MM-yyyy').format(selectedDate),
                            style: TextStyle(
                                color: theme.textTheme.bodyMedium!.color),
                          ),
                          onPressed: _pickDate,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: isDark ? Colors.grey : Colors.orange),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: _selectedStatus,
                        dropdownColor: theme.cardColor,
                        style:
                            TextStyle(color: theme.textTheme.bodyMedium!.color),
                        items: ['All', 'Won', 'Lost'].map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value ?? 'All';
                            _filterData();
                          });
                        },
                      ),
                    ],
                  ),

            const SizedBox(height: 12),

            // 🔸 Type Filters
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['All', 'Hot', 'Warm', 'Cold', 'Junk'].map((type) {
                final isSelected = _selectedType == type;

                Color selectedBgColor;
                Color selectedTextColor;

                switch (type.toLowerCase()) {
                  case 'hot':
                    selectedBgColor = Colors.red.shade100;
                    selectedTextColor = Colors.red.shade800;
                    break;
                  case 'warm':
                    selectedBgColor = Colors.orange.shade100;
                    selectedTextColor = Colors.orange.shade800;
                    break;
                  case 'cold':
                    selectedBgColor = Colors.blue.shade100;
                    selectedTextColor = Colors.blue.shade800;
                    break;
                  case 'junk':
                    selectedBgColor = Colors.grey.shade400;
                    selectedTextColor = Colors.grey.shade900;
                    break;
                  default:
                    selectedBgColor = Colors.green.shade100;
                    selectedTextColor = Colors.green.shade800;
                }

                return ChoiceChip(
                  label: Text(
                    type,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? selectedTextColor
                          : theme.textTheme.bodyMedium!.color,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _selectedType = type);
                    _filterData();
                  },
                  selectedColor: selectedBgColor,
                  backgroundColor: isDark ? Colors.grey[850] : Colors.grey[200],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  elevation: isSelected ? 2 : 0,
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // 📋 Table
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 48,
                dataRowHeight: 52,
                columnSpacing: 20,
                headingRowColor: WidgetStateProperty.all(
                  isDark ? Colors.grey[850] : Colors.grey.shade100,
                ),
                dividerThickness: 0.5,
                columns: const [
                  DataColumn(
                      label: Text('S.No',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('Name',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('Email',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('Phone',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('Alt Phone',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('City',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('Project Name',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('Project Type',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('Type',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('Created At',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: List.generate(_paginatedCustomers.length, (index) {
                  final c = _paginatedCustomers[index];
                  final actualIndex = (_currentPage - 1) * _rowsPerPage + index;
                  return DataRow(
                    color: WidgetStateProperty.resolveWith<Color?>(
                      (Set<WidgetState> states) {
                        return index.isEven
                            ? (isDark ? Colors.grey.shade800 : Colors.white)
                            : (isDark
                                ? Colors.grey.shade900
                                : Colors.grey.shade50);
                      },
                    ),
                    cells: [
                      DataCell(Text('${actualIndex + 1}')),
                      DataCell(Text(c['name'] ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.w500))),
                      DataCell(Text(c['email'] ?? '-')),
                      DataCell(Text(c['phone'] ?? '-')),
                      DataCell(Text(c['altPhone'] ?? '-')),
                      DataCell(Text(c['city'] ?? '-')),
                      DataCell(Text(c['projectName'] ?? '-')),
                      DataCell(Text(c['projectType'] ?? '-')),
                      DataCell(buildTypeChip(c['type'] ?? '')),
                      DataCell(Text(
                          c['createdAt']?.toString().substring(0, 10) ?? '-')),
                    ],
                  );
                }),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _currentPage > 1
                      ? () => setState(() => _currentPage--)
                      : null,
                ),
                Text("Page $_currentPage of $_totalPages"),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _currentPage < _totalPages
                      ? () => setState(() => _currentPage++)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _filterData();
      });
    }
  }

  void _filterSearch(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      _filterData();
    });
  }

  void _filterData() {
    setState(() {
      customer = _allCustomers.where((c) {
        final matchesType =
            _selectedType == 'All' || c['type'] == _selectedType;
        final matchesStatus = _selectedStatus == 'All' ||
            (c['status'] ?? '').toLowerCase() == _selectedStatus.toLowerCase();
        final matchesSearch = searchQuery.isEmpty ||
            (c['name']?.toLowerCase().contains(searchQuery) ?? false) ||
            (c['email']?.toLowerCase().contains(searchQuery) ?? false);

        return matchesType && matchesStatus && matchesSearch;
      }).toList();
    });
  }

  // Prepare data for the chart
  void prepareChartData() {
    estimateTypes = List<String>.from(
      estimates.map((e) => e['estimateType'] ?? 'Unknown').toSet(),
    );

    barChartData = estimateTypes.map((estimateType) {
      double totalAmountForType = estimates
          .where((e) => e['estimateType'] == estimateType)
          .fold(
              0.0,
              (sum, e) =>
                  sum + (double.tryParse(e['totalAmount'].toString()) ?? 0.0));

      return BarChartGroupData(
        x: estimateTypes.indexOf(estimateType),
        barRods: [
          BarChartRodData(
            toY: totalAmountForType,
            color: Colors.blue,
            width: 30,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
  }

  Widget buildDashboardCard({
    required String title,
    required String value,
    required String subtitle,
    required int index,
    required double cardWidth,
  }) {
    final isSelected = selectedCardIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final valueFontSize = cardWidth < 200 ? 20.0 : 24.0;
    final titleFontSize = cardWidth < 200 ? 14.0 : 16.0;
    final subtitleFontSize = cardWidth < 200 ? 11.0 : 12.0;

    final bgColor = isSelected
        ? Colors.orange
        : isDark
            ? Colors.grey[850]!
            : Colors.white;

    final textColor = isSelected
        ? Colors.white
        : isDark
            ? Colors.white70
            : Colors.black87;

    final subTextColor = isSelected
        ? Colors.white70
        : isDark
            ? Colors.grey[400]!
            : Colors.grey;

    final borderColor =
        isDark ? Colors.lightBlueAccent : Colors.orange.shade100;
    final shadowColor = isDark ? Colors.black26 : Colors.grey.withOpacity(0.1);

    return GestureDetector(
      onTap: () => setState(() => selectedCardIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: cardWidth,
        height: 121, // 🔒 Fixed height for all cards
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: valueFontSize,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(fontSize: titleFontSize, color: textColor),
            ),
            const Spacer(), // 🧱 Push subtitle to the bottom
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: subtitleFontSize, color: subTextColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        barGroups: barChartData,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                int index = value.toInt();
                String title =
                    index < estimateTypes.length ? estimateTypes[index] : '';
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 200000,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value == 0) {
                  return const Text('0', style: TextStyle(fontSize: 10));
                }
                if (value >= 1000000) {
                  return Text('₹${(value / 1000000).toStringAsFixed(1)}M',
                      style: const TextStyle(fontSize: 10));
                }
                return Text('₹${(value ~/ 1000)}K',
                    style: const TextStyle(fontSize: 10));
              },
              reservedSize: 40,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 200000,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.3),
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ),
        borderData: FlBorderData(
          show: false,
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipMargin: 10, // Changed from tooltipBgColor
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '₹${rod.toY.toStringAsFixed(0)}',
                const TextStyle(color: Colors.white),
                children: [
                  TextSpan(
                    text: ' ${estimateTypes[group.x.toInt()]}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String getFormattedAmount(double value) {
    if (value >= 10000000) {
      return '₹${(value / 10000000).toStringAsFixed(1)} Cr';
    }
    if (value >= 100000) return '₹${(value / 100000).toStringAsFixed(1)} L';
    return '₹${value.toStringAsFixed(0)}';
  }

  Widget _buildSalesPerformanceCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final titleColor = isDark ? Colors.white70 : Colors.grey;
    final amountColor = isDark ? Colors.white : Colors.black;
    final growthColor = isDark ? Colors.white60 : Colors.black;

    final dropdownBg = isDark ? Colors.grey.shade800 : Colors.grey.shade100;
    final dropdownText = isDark ? Colors.white70 : Colors.black87;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sales Data
                    Text('Sales Performance',
                        style: TextStyle(fontSize: 14, color: titleColor)),
                    const SizedBox(height: 4),
                    Text(
                      '₹${NumberFormat.decimalPattern('en_IN').format(totalAmount)}',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: amountColor),
                    ),
                    const SizedBox(height: 4),
                    Text('25% increased than last week',
                        style: TextStyle(fontSize: 12, color: growthColor)),
                    const SizedBox(height: 20),

                    // Filters (stacked)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: dropdownBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Text("Last 60 days",
                              style:
                                  TextStyle(fontSize: 12, color: dropdownText)),
                          const SizedBox(width: 6),
                          Icon(Icons.arrow_drop_down,
                              size: 18, color: dropdownText),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: borderColor),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.calendar_month,
                              size: 20, color: dropdownText),
                        ),
                        const SizedBox(width: 10),
                        Row(
                          children: [
                            _tabChip("W", true, isDark),
                            _tabChip("Y", false, isDark),
                            _tabChip("T", false, isDark),
                            _tabChip("M", false, isDark),
                          ],
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Sales Data
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sales Performance',
                            style: TextStyle(fontSize: 14, color: titleColor)),
                        const SizedBox(height: 4),
                        Text(
                          '₹${NumberFormat.decimalPattern('en_IN').format(totalAmount)}',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: amountColor),
                        ),
                        const SizedBox(height: 4),
                        Text('25% increased than last week',
                            style: TextStyle(fontSize: 13, color: growthColor)),
                      ],
                    ),
                    const SizedBox(width: 16),

                    // Filter section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: dropdownBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              Text("Last 60 days",
                                  style: TextStyle(
                                      fontSize: 12, color: dropdownText)),
                              const SizedBox(width: 6),
                              Icon(Icons.arrow_drop_down,
                                  size: 18, color: dropdownText),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: borderColor),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Icon(Icons.calendar_month,
                                  size: 20, color: dropdownText),
                            ),
                            const SizedBox(width: 10),
                            Row(
                              children: [
                                _tabChip("W", true, isDark),
                                _tabChip("Y", false, isDark),
                                _tabChip("T", false, isDark),
                                _tabChip("M", false, isDark),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

          const SizedBox(height: 40),
          // 📊 Chart
          SizedBox(height: 260, child: _buildBarChart()),
        ],
      ),
    );
  }

  Widget _tabChip(String label, bool isSelected, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.orange
            : isDark
                ? Colors.grey[850]
                : Colors.transparent,
        border: Border.all(
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected
              ? Colors.white
              : isDark
                  ? Colors.white70
                  : Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTargetCard() {
    int? touchedIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Target',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.grey)),
              const SizedBox(height: 20),
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 270,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 5,
                          centerSpaceRadius: 40,
                          pieTouchData: PieTouchData(
                            touchCallback: (event, response) {
                              setState(() {
                                touchedIndex = response
                                    ?.touchedSection?.touchedSectionIndex;
                              });
                            },
                          ),
                          sections: List.generate(3, (i) {
                            final isTouched = i == touchedIndex;
                            final double radius = [15.0, 30.0, 45.0][i];
                            final Color color =
                                [Colors.green, Colors.orange, Colors.blue][i];
                            final double value = [100.0, 75.0, 75.0][i];

                            return PieChartSectionData(
                              value: value,
                              color: color,
                              radius: radius,
                              title: '',
                              showTitle: false,
                              badgeWidget: isTouched
                                  ? Container(
                                      padding: const EdgeInsets.all(8),
                                      margin: const EdgeInsets.only(top: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                            color: color, width: 1.5),
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: color.withOpacity(0.4),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text("April",
                                              style: TextStyle(
                                                  color: color,
                                                  fontWeight: FontWeight.bold)),
                                          Text(
                                            i == 0
                                                ? "✔ Goal"
                                                : i == 1
                                                    ? "📈 Completed"
                                                    : "🔄 On progress",
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black),
                                          ),
                                          Text(
                                              "No of projects ${i == 0 ? 'set' : i == 1 ? 'completed' : 'in progress'}",
                                              style: const TextStyle(
                                                  fontSize: 11)),
                                        ],
                                      ),
                                    )
                                  : null,
                              badgePositionPercentageOffset: .98,
                            );
                          }),
                        ),
                      ),
                    ),
                    const Text("April",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _legendRow(Colors.green, "Goal", "100%"),
              _legendRow(Colors.orange, "Completed", "75%"),
              _legendRow(Colors.blue, "On progress", "75%"),
            ],
          ),
        );
      },
    );
  }

  Widget _legendRow(Color color, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(radius: 6, backgroundColor: color),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BoxDecoration(
      color: isDark ? Colors.grey[850] : Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isDark ? Colors.lightBlueAccent : Colors.orange.shade100,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
          spreadRadius: 2,
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  List<int> expandedCustomerIds = [];
  Widget _buildGroupedEstimateChart() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Group estimates by customerId
    final grouped = <int, List<Map<String, dynamic>>>{};
    for (var est in estimates) {
      final id = est['customerId'];
      grouped.putIfAbsent(id, () => []).add(est);
    }

    final customerIds = grouped.keys.toList()..sort();
    final selectedList =
        _selectedCustomerId != null ? grouped[_selectedCustomerId!]! : [];

    // 🔁 Extract all versions from selected customer, not just filtered ones
    final rawVersions = selectedList
        .map((e) => e['version'].toString())
        .toSet()
        .toList()
      ..sort();
    final versions = ['All', ...rawVersions];
    int currentVersionIndex = versions.indexOf(_selectedVersion);

    // 🧮 Filter selectedEstimates by version
    final selectedEstimates = selectedList
        .where((e) =>
            _selectedVersion == 'All' ||
            e['version'].toString() == _selectedVersion)
        .toList();

    final barData = selectedEstimates.asMap().entries.map((entry) {
      final index = entry.key;
      final est = entry.value;
      final amount = double.tryParse(est['totalAmount'].toString()) ?? 0.0;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: amount,
            width: 30,
            borderRadius: BorderRadius.circular(6),
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.blue.shade800],
              begin: Alignment.topCenter, // 🔼 Top
              end: Alignment.bottomCenter, // 🔽 Bottom
            ),
          ),
        ],
      );
    }).toList();

    return Card(
      margin: const EdgeInsets.only(top: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.shade300, width: 1.2),
      ),
      color: isDark ? Colors.grey[900] : Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔽 Compact Customer & Version Filters Row
            Row(
              children: [
                // 🧍 Customer Selector
                DropdownButton<int>(
                  value: _selectedCustomerId,
                  hint: const Text("Select Customer"),
                  items: customerIds.map((id) {
                    return DropdownMenuItem(
                      value: id,
                      child: Text("Customer $id"),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCustomerId = val;
                      _selectedVersion = 'All';
                    });
                  },
                ),
                const SizedBox(width: 12),

                // 🔁 Version Arrows
                if (_selectedCustomerId != null && versions.length > 1)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 16),
                        onPressed: currentVersionIndex > 0
                            ? () {
                                setState(() {
                                  _selectedVersion =
                                      versions[currentVersionIndex - 1];
                                });
                              }
                            : null,
                      ),
                      Text(
                        'Version ${_selectedVersion == 'All' ? 'All' : _selectedVersion}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 16),
                        onPressed: currentVersionIndex < versions.length - 1
                            ? () {
                                setState(() {
                                  _selectedVersion =
                                      versions[currentVersionIndex + 1];
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // 📊 Chart Area
            selectedEstimates.isEmpty
                ? const Center(child: Text("No estimates available."))
                : SizedBox(
                    height: 300,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        barGroups: barData,
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < selectedEstimates.length) {
                                  return Text(
                                    selectedEstimates[index]['estimateType'] ??
                                        '',
                                    style: const TextStyle(fontSize: 10),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: true),
                          ),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '₹${NumberFormat.decimalPattern('en_IN').format(rod.toY)}',
                                const TextStyle(fontWeight: FontWeight.bold),
                              );
                            },
                          ),
                        ),
                      ),
                      swapAnimationDuration: const Duration(milliseconds: 800),
                      swapAnimationCurve: Curves.easeInOut,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return MainScaffold(
      title: 'Super Admin Dashboard',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🔸 Top Welcome Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: isDark
                    ? LinearGradient(
                        colors: [Colors.lightBlueAccent, Colors.grey.shade900],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : LinearGradient(
                        colors: [Colors.orange.shade100, Colors.white],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _pickImageWeb,
                              child: CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.orange.shade200,
                                backgroundImage: _webImageBytes != null
                                    ? MemoryImage(_webImageBytes!)
                                    : null,
                                child: _webImageBytes == null
                                    ? const Icon(Icons.person,
                                        color: Colors.white)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Hello ${widget.userRole ?? 'User'},",
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                const SizedBox(height: 6),
                                const Text("We’re about to reach our target!",
                                    style: TextStyle(fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text("Target Amount",
                            style: TextStyle(color: Colors.white)),
                        Text(
                            '₹${NumberFormat.decimalPattern('en_IN').format(totalAmount)}',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: _pickImageWeb,
                              child: CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.orange.shade200,
                                backgroundImage: _webImageBytes != null
                                    ? MemoryImage(_webImageBytes!)
                                    : null,
                                child: _webImageBytes == null
                                    ? const Icon(Icons.person,
                                        color: Colors.white)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Hello ${widget.userName ?? 'User'},",
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                    "Looks like we are about to reach our target!",
                                    style: TextStyle(fontSize: 14)),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text("Target Amount",
                                style: TextStyle(
                                    fontSize: 14, color: Colors.white)),
                            Text(
                                '₹${NumberFormat.decimalPattern('en_IN').format(totalAmount)}',
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        SizedBox(
                          height: 120,
                          child: Image.asset("assets/sales.png",
                              fit: BoxFit.contain),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 20),

            // const Text('Estimate Summary',
            // style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            // const SizedBox(height: 20),

            // Responsive cards
            LayoutBuilder(
              builder: (context, constraints) {
                double maxWidth = constraints.maxWidth;
                int itemsPerRow =
                    maxWidth ~/ 220; // Minimum width per card with spacing
                itemsPerRow = itemsPerRow == 0 ? 1 : itemsPerRow;

                double totalSpacing = (itemsPerRow - 1) * 16;
                double cardWidth = (maxWidth - totalSpacing) / itemsPerRow;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    buildDashboardCard(
                        title: 'Total Orders',
                        value: '$estimateCount',
                        subtitle: 'Recent orders: 15',
                        index: 0,
                        cardWidth: cardWidth),
                    buildDashboardCard(
                        title: 'Total Estimate',
                        value: '$estimateCount',
                        subtitle: 'Closed: 300 | Junk: 200',
                        index: 1,
                        cardWidth: cardWidth),
                    buildDashboardCard(
                        title: 'Clients',
                        value: '$customerCount',
                        subtitle: 'New: 15',
                        index: 2,
                        cardWidth: cardWidth),
                    buildDashboardCard(
                        title: 'Stocks',
                        value: '10000',
                        subtitle: 'Purchased: 150 | Spent: 150',
                        index: 3,
                        cardWidth: cardWidth),
                    buildDashboardCard(
                        title: 'Users',
                        value: '$userCount',
                        subtitle: 'Active users: 18',
                        index: 4,
                        cardWidth: cardWidth),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            isMobile
                ? Column(
                    children: [
                      _buildSalesPerformanceCard(),
                      const SizedBox(height: 16),
                      _buildTargetCard(),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildSalesPerformanceCard()),
                      const SizedBox(width: 16),
                      Expanded(flex: 1, child: _buildTargetCard()),
                    ],
                  ),

            const SizedBox(height: 20),
            if (estimates.isNotEmpty)
              _buildGroupedEstimateChart()
            else
              const Center(child: Text('Select the Customer')),
            const SizedBox(height: 20),
            _buildCustomerSection(),
          ],
        ),
      ),
    );
  }
}
